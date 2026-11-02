# ==============================================================================
# CBSFilter - LogFilterEngine.ps1
# Camada de Domínio / Serviços (Business Logic & Streaming Engine)
# ==============================================================================

<#
.SYNOPSIS
    Mecanismo de filtragem em alta performance para logs CBS do Windows.
.DESCRIPTION
    Realiza a leitura e escrita linha a linha utilizando Streams nativos do .NET
    com FileShare.ReadWrite (evitando bloqueios em logs ativos do TrustedInstaller)
    e com consumo mínimo de memória RAM.
#>

function Get-DefaultCbsLogPath {
    <#
    .SYNOPSIS
        Retorna o caminho padrão do log CBS ativo do Windows.
    #>
    [CmdletBinding()]
    param()

    return Join-Path -Path $env:windir -ChildPath "Logs\CBS\CBS.log"
}

function Get-DefaultOutputPath {
    <#
    .SYNOPSIS
        Gera um caminho padrão de saída no Desktop do usuário ou no diretório atual.
    #>
    [CmdletBinding()]
    param(
        [string]$Prefix = "CBS_Filtered"
    )

    $targetDir = $null
    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)

    if (-not [string]::IsNullOrWhiteSpace($desktop) -and (Test-Path -Path $desktop -ErrorAction SilentlyContinue)) {
        $targetDir = $desktop
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $userDesktop = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop"
        if (Test-Path -Path $userDesktop -ErrorAction SilentlyContinue) {
            $targetDir = $userDesktop
        }
    }

    if ([string]::IsNullOrWhiteSpace($targetDir)) {
        $targetDir = (Get-Location).Path
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    return Join-Path -Path $targetDir -ChildPath "$($Prefix)_$timestamp.log"
}

function Test-CBSLogPath {
    <#
    .SYNOPSIS
        Valida a existência e acessibilidade de um arquivo de log.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return @{ IsValid = $false; ErrorMessage = "O caminho do arquivo de log não foi informado." }
    }

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        return @{ IsValid = $false; ErrorMessage = "O arquivo não foi encontrado em: '$Path'" }
    }

    return @{ IsValid = $true; ErrorMessage = $null }
}

function Invoke-CBSLogFilter {
    <#
    .SYNOPSIS
        Filtra um arquivo de log CBS com base nas palavras-chave fornecidas.
    .OUTPUTS
        Retorna um PSCustomObject com o status e métricas da execução.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Keywords,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeHeader = $true
    )

    # 1. Validação do arquivo de entrada
    $pathCheck = Test-CBSLogPath -Path $InputPath
    if (-not $pathCheck.IsValid) {
        return [PSCustomObject]@{
            Success          = $false
            InputPath        = $InputPath
            OutputPath       = $OutputPath
            TotalLines       = 0
            MatchedLines     = 0
            DurationSeconds  = 0
            Keywords         = @()
            ErrorMessage     = $pathCheck.ErrorMessage
        }
    }

    # 2. Sanitização e validação das palavras-chave
    $cleanedKeywords = @($Keywords | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne "" })
    if ($cleanedKeywords.Count -eq 0) {
        return [PSCustomObject]@{
            Success          = $false
            InputPath        = $InputPath
            OutputPath       = $OutputPath
            TotalLines       = 0
            MatchedLines     = 0
            DurationSeconds  = 0
            Keywords         = @()
            ErrorMessage     = "Nenhuma palavra-chave válida foi informada para o filtro."
        }
    }

    # 3. Definição do destino de saída
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Get-DefaultOutputPath
    }

    $outDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path -Path $outDir)) {
        try {
            [System.IO.Directory]::CreateDirectory($outDir) | Out-Null
        }
        catch {
            return [PSCustomObject]@{
                Success          = $false
                InputPath        = $InputPath
                OutputPath       = $OutputPath
                TotalLines       = 0
                MatchedLines     = 0
                DurationSeconds  = 0
                Keywords         = $cleanedKeywords
                ErrorMessage     = "Não foi possível criar o diretório de destino: $_"
            }
        }
    }

    # 4. Compilação da Regex com escape seguro para evitar injeções ou erros de sintaxe
    $escapedPatterns = $cleanedKeywords | ForEach-Object { [System.Text.RegularExpressions.Regex]::Escape($_) }
    $regexPattern = $escapedPatterns -join "|"
    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::Compiled
    if (-not $CaseSensitive) {
        $regexOptions = $regexOptions -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }
    $filterRegex = New-Object System.Text.RegularExpressions.Regex($regexPattern, $regexOptions)

    # 5. Processamento via Streams (.NET) em baixa demanda de memória
    $totalLines = 0
    $matchedLines = 0
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $inStream = $null
    $reader = $null
    $outStream = $null
    $writer = $null

    try {
        # FileShare.ReadWrite permite ler mesmo se o TrustedInstaller estiver escrevendo no CBS.log
        $inStream = New-Object System.IO.FileStream(
            $InputPath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )
        $reader = New-Object System.IO.StreamReader($inStream, [System.Text.Encoding]::UTF8, $true)

        $outStream = New-Object System.IO.FileStream(
            $OutputPath,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::Read
        )
        $writer = New-Object System.IO.StreamWriter($outStream, [System.Text.Encoding]::UTF8)

        # Cabeçalho informativo no arquivo de resultado
        if ($IncludeHeader) {
            $writer.WriteLine("# ====================================================================")
            $writer.WriteLine("# CBSFilter - Relatório de Linhas Filtradas")
            $writer.WriteLine("# Origem: $InputPath")
            $writer.WriteLine("# Data da Extração: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
            $writer.WriteLine("# Palavras-chave: $($cleanedKeywords -join ', ')")
            $writer.WriteLine("# ====================================================================")
            $writer.WriteLine("")
        }

        while (($line = $reader.ReadLine()) -ne $null) {
            $totalLines++
            if ($filterRegex.IsMatch($line)) {
                $writer.WriteLine($line)
                $matchedLines++
            }
        }

        $writer.Flush()
        $stopwatch.Stop()

        return [PSCustomObject]@{
            Success          = $true
            InputPath        = $InputPath
            OutputPath       = $OutputPath
            TotalLines       = $totalLines
            MatchedLines     = $matchedLines
            DurationSeconds  = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            Keywords         = $cleanedKeywords
            ErrorMessage     = $null
        }
    }
    catch {
        if ($stopwatch.IsRunning) { $stopwatch.Stop() }
        return [PSCustomObject]@{
            Success          = $false
            InputPath        = $InputPath
            OutputPath       = $OutputPath
            TotalLines       = $totalLines
            MatchedLines     = $matchedLines
            DurationSeconds  = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            Keywords         = $cleanedKeywords
            ErrorMessage     = $_.Exception.Message
        }
    }
    finally {
        if ($writer) { $writer.Dispose() }
        if ($outStream) { $outStream.Dispose() }
        if ($reader) { $reader.Dispose() }
        if ($inStream) { $inStream.Dispose() }
    }
}
