Add-Type -AssemblyName System.Windows.Forms

# Função para o botão "Filtrar"
function Search-CBSLog {
    param (
        $CbsLogPath,
        $Keywords
    )

    $FilteredLogPath = Join-Path -Path "$env:USERPROFILE\Desktop" -ChildPath "filtered_log.txt"

    try {
        $FilteredLines = Get-Content -Path $CbsLogPath | Where-Object { $_ -match ($Keywords -join "|") }
        $FilteredLines | Out-File -FilePath $FilteredLogPath

        [System.Windows.Forms.MessageBox]::Show("Filtragem concluída. As linhas filtradas foram salvas em: $FilteredLogPath", "Filtragem Concluída", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Ocorreu um erro ao executar o script: $_", "Erro", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Criar a janela
$form = New-Object System.Windows.Forms.Form
$form.Text = "Filtrar Arquivo CBS"
$form.Width = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width * 0.5 # Por exemplo, 60% da largura da tela
$form.Height = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height * 0.5 # Por exemplo, 60% da altura da tela
$form.FormBorderStyle = "Sizable"
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false

# Criar os controles
$labelCbsLogPath = New-Object System.Windows.Forms.Label -Property @{
    Text = "Caminho do arquivo CBS:"
    Location = New-Object System.Drawing.Point(10, 20)
    AutoSize = $true
}

$txtCbsLogPath = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(10, 40)
    Size = New-Object System.Drawing.Size(250, 20)
}

$btnBrowse = New-Object System.Windows.Forms.Button -Property @{
    Text = "Procurar"
    Location = New-Object System.Drawing.Point(270, 40)
    Size = New-Object System.Drawing.Size(70, 20)
}
$btnBrowse.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter = "Arquivos CBS (*.log)|*.log"
    }
    $openFileDialog.ShowDialog() | Out-Null
    $txtCbsLogPath.Text = $openFileDialog.FileName
})

$labelKeywords = New-Object System.Windows.Forms.Label -Property @{
    Text = "Palavras-chave (uma por linha):"
    Location = New-Object System.Drawing.Point(10, 70)
    AutoSize = $true
}

$txtKeywords = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(10, 90)
    Size = New-Object System.Drawing.Size(200, 80)
    Multiline = $true
}

$btnFilter = New-Object System.Windows.Forms.Button -Property @{
    Text = "Filtrar"
    Location = New-Object System.Drawing.Point(10, 180)
    Size = New-Object System.Drawing.Size(60, 32)
}
$btnFilter.Add_Click({
    Search-CBSLog -CbsLogPath $txtCbsLogPath.Text -Keywords $txtKeywords.Lines
})

$btnClearKeywords = New-Object System.Windows.Forms.Button -Property @{
    Text = "Limpar Keywords"
    Location = New-Object System.Drawing.Point(75, 180)
    Size = New-Object System.Drawing.Size(120, 32)
}
$btnClearKeywords.Add_Click({
    $txtKeywords.Clear()
})

$btnErrorWarning = New-Object System.Windows.Forms.Button -Property @{
    Text = "Filtro: Error, Warning"
    Location = New-Object System.Drawing.Point(220, 90)
    Size = New-Object System.Drawing.Size(120, 35)
}
$btnErrorWarning.Add_Click({
    $txtKeywords.Text = "Error`r`nWarning"
})

$btnRollback = New-Object System.Windows.Forms.Button -Property @{
    Text = "Filtro: Rollback"
    Location = New-Object System.Drawing.Point(220, 135)
    Size = New-Object System.Drawing.Size(120, 35)
}
$btnRollback.Add_Click({
    $txtKeywords.Text = "Rollback"
})

$btnAllKeywords = New-Object System.Windows.Forms.Button -Property @{
    Text = "Filtro Completo"
    Location = New-Object System.Drawing.Point(355, 90)
    Size = New-Object System.Drawing.Size(120, 35)
}
$btnAllKeywords.Add_Click({
    $txtKeywords.Text = "Error`r`nWarning`r`nCritical`r`nRollback"
})

# Adicionar os controles à janela
$form.Controls.AddRange(@(
    $labelCbsLogPath, $txtCbsLogPath, $btnBrowse,
    $labelKeywords, $txtKeywords,
    $btnFilter, $btnErrorWarning, $btnRollback, $btnAllKeywords, $btnClearKeywords
))

# Exibir a janela
$form.ShowDialog() | Out-Null