$allPassed = $true
Get-ChildItem -Path "$PSScriptRoot\.." -Filter "*.ps1" -Recurse | ForEach-Object {
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
    if ($errors) {
        $allPassed = $false
        Write-Host "ERRO no arquivo $($_.FullName):" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host " - $($_.Message)" -ForegroundColor Red }
    } else {
        Write-Host "OK: $($_.FullName)" -ForegroundColor Green
    }
}

if (-not $allPassed) {
    exit 1
} else {
    Write-Host "Todos os arquivos foram parseados com sucesso pelo PowerShell!" -ForegroundColor Green
}
