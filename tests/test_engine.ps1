# ==============================================================================
# CBSFilter - Testes Automatizados da Camada de Domínio / Engine
# ==============================================================================

$enginePath = Join-Path -Path $PSScriptRoot -ChildPath "..\src\Core\LogFilterEngine.ps1"
if (-not (Test-Path $enginePath)) {
    throw "Engine não encontrada em: $enginePath"
}
. $enginePath

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " EXECUTANDO SUITE DE TESTES: LogFilterEngine" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$testCount = 0
$passCount = 0

function Assert-Test {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Details = ""
    )
    $script:testCount++
    if ($Condition) {
        $script:passCount++
        Write-Host " [PASS] $TestName" -ForegroundColor Green
    } else {
        Write-Host " [FAIL] $TestName - $Details" -ForegroundColor Red
    }
}

# 1. Teste de caminho padrão do CBS
$defaultCbs = Get-DefaultCbsLogPath
Assert-Test -TestName "Get-DefaultCbsLogPath retorna caminho válido" `
            -Condition ($defaultCbs -match "CBS\.log$") `
            -Details "Valor retornado: $defaultCbs"

# 2. Teste de caminho inexistente
$invalidResult = Invoke-CBSLogFilter -InputPath "C:\CaminhoInexistente_123.log" -Keywords @("Error")
Assert-Test -TestName "Invoke-CBSLogFilter falha amigavelmente para arquivo inexistente" `
            -Condition ($invalidResult.Success -eq $false -and $invalidResult.ErrorMessage -match "não foi encontrado") `
            -Details "Mensagem: $($invalidResult.ErrorMessage)"

# 3. Teste de palavras-chave vazias
$emptyKeywordsResult = Invoke-CBSLogFilter -InputPath $defaultCbs -Keywords @("", "   ")
Assert-Test -TestName "Invoke-CBSLogFilter rejeita lista de palavras-chave vazia" `
            -Condition ($emptyKeywordsResult.Success -eq $false -and $emptyKeywordsResult.ErrorMessage -match "palavra-chave") `
            -Details "Mensagem: $($emptyKeywordsResult.ErrorMessage)"

# 4. Teste de filtragem com arquivo real e caracteres especiais de Regex
$tempLog = Join-Path -Path $PSScriptRoot -ChildPath "test_sample.log"
$tempOut = Join-Path -Path $PSScriptRoot -ChildPath "test_sample_filtered.log"

@"
2026-11-02 10:00:00, Info                  CBS    Starting TrustedInstaller.
2026-11-02 10:00:01, Warning               CBS    Package [KB5001234] is not required.
2026-11-02 10:00:02, Error                 CBS    Failed to install package with HRESULT (0x800f081f).
2026-11-02 10:00:03, Info                  CBS    Finalizing installation.
2026-11-02 10:00:04, Error                 CBS    Rollback initiated due to critical corruption.
"@ | Set-Content -Path $tempLog -Encoding UTF8

$filterResult = Invoke-CBSLogFilter `
    -InputPath $tempLog `
    -Keywords @("[KB5001234]", "(0x800f081f)", "Rollback") `
    -OutputPath $tempOut

Assert-Test -TestName "Invoke-CBSLogFilter processa corretamente caracteres especiais de Regex" `
            -Condition ($filterResult.Success -eq $true -and $filterResult.MatchedLines -eq 3) `
            -Details "Linhas esperadas: 3, Obtidas: $($filterResult.MatchedLines)"

# Limpeza dos arquivos temporários de teste
if (Test-Path $tempLog) { Remove-Item $tempLog -Force }
if (Test-Path $tempOut) { Remove-Item $tempOut -Force }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " RESULTADO DOS TESTES: $passCount de $testCount passaram." -ForegroundColor $(if ($passCount -eq $testCount) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($passCount -ne $testCount) {
    exit 1
}
