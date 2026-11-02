# ==============================================================================
# CBSFilter - Windows Component-Based Servicing Log Analyzer
# Arquivo Principal / Ponto de Entrada (Entry Point & Controller)
# ==============================================================================

<#
.SYNOPSIS
    Filtra e analisa arquivos de log CBS (Component-Based Servicing) do Windows.
.DESCRIPTION
    Ferramenta para análise rápida e diagnóstico de falhas no Windows Update,
    corrupção de pacotes (SFC / DISM) e erros de inicialização de componentes.
    
    Suporta execução com Interface Gráfica (GUI) ou em modo Linha de Comando (CLI).
.PARAMETER CbsLogPath
    Caminho do arquivo CBS.log a ser analisado. Se não for especificado no modo CLI,
    utiliza o padrão 'C:\Windows\Logs\CBS\CBS.log'.
.PARAMETER Keywords
    Lista de palavras-chave para filtragem (ex: "Error", "Warning", "Rollback", "0x800").
.PARAMETER OutputPath
    Caminho onde o relatório filtrado será salvo. Padrão: Desktop com timestamp.
.PARAMETER CaseSensitive
    Indica se a busca deve diferenciar maiúsculas de minúsculas.
.PARAMETER NoGui
    Força a execução em modo Linha de Comando (CLI), sem abrir a janela gráfica.
.EXAMPLE
    # Abrir a interface gráfica padrão
    .\CBSFilter.ps1

.EXAMPLE
    # Executar em modo CLI direto no terminal
    .\CBSFilter.ps1 -Keywords "Error", "Rollback" -NoGui

.EXAMPLE
    # Analisar um arquivo específico e salvar em pasta customizada
    .\CBSFilter.ps1 -CbsLogPath "D:\Logs\CbsPersist_20261101.log" -Keywords "0x800f081f", "Failed" -OutputPath "D:\resultado.log" -NoGui
#>

[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $false)]
    [string]$CbsLogPath,

    [Parameter(Mandatory = $false)]
    [string[]]$Keywords,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$CaseSensitive,

    [Parameter(Mandatory = $false)]
    [switch]$NoGui
)

# ------------------------------------------------------------------------------
# 1. Carregamento dos Módulos (Clean Architecture - Injeção das Camadas)
# ------------------------------------------------------------------------------
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$coreEnginePath = Join-Path -Path $scriptDir -ChildPath "src\Core\LogFilterEngine.ps1"
$uiFormPath     = Join-Path -Path $scriptDir -ChildPath "src\UI\MainForm.ps1"

if (-not (Test-Path -Path $coreEnginePath)) {
    Write-Error "Módulo Core não encontrado em: '$coreEnginePath'"
    exit 1
}

# Importar o mecanismo de filtragem (Domínio / Core)
. $coreEnginePath

# ------------------------------------------------------------------------------
# 2. Roteamento de Execução: CLI vs GUI
# ------------------------------------------------------------------------------
$isCliMode = $NoGui -or ($PSBoundParameters.ContainsKey("Keywords") -and $Keywords.Count -gt 0)

if ($isCliMode) {
    # Modo CLI (Linha de Comando)
    if ([string]::IsNullOrWhiteSpace($CbsLogPath)) {
        $CbsLogPath = Get-DefaultCbsLogPath
    }

    if ($null -eq $Keywords -or $Keywords.Count -eq 0) {
        $Keywords = @("Error", "Warning", "Rollback", "Critical")
    } else {
        $Keywords = @($Keywords | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
    }

    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host " [CBSFilter] Iniciando filtragem em modo CLI" -ForegroundColor Cyan
    Write-Host " Arquivo de Origem: $CbsLogPath" -ForegroundColor Gray
    Write-Host " Palavras-chave   : $($Keywords -join ', ')" -ForegroundColor Gray
    Write-Host "==============================================================" -ForegroundColor Cyan

    $result = Invoke-CBSLogFilter `
        -InputPath $CbsLogPath `
        -Keywords $Keywords `
        -OutputPath $OutputPath `
        -CaseSensitive:$CaseSensitive

    if ($result.Success) {
        Write-Host "`nFiltragem concluída com sucesso!" -ForegroundColor Green
        Write-Host " • Linhas analisadas: $($result.TotalLines.ToString('N0'))"
        Write-Host " • Linhas filtradas : $($result.MatchedLines.ToString('N0'))"
        Write-Host " • Tempo decorrido  : $($result.DurationSeconds) s"
        Write-Host " • Arquivo gerado   : $($result.OutputPath)`n" -ForegroundColor Yellow
        return $result
    } else {
        Write-Error "Erro na filtragem: $($result.ErrorMessage)"
        return $result
    }
} else {
    # Modo Gráfico (GUI)
    if (-not (Test-Path -Path $uiFormPath)) {
        Write-Error "Módulo UI não encontrado em: '$uiFormPath'"
        exit 1
    }

    # Importar e exibir a interface gráfica
    . $uiFormPath
    Show-CBSFilterForm
}
