# ==============================================================================
# CBSFilter - MainForm.ps1
# Camada de Apresentacao (Windows Forms UI)
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-CBSFilterForm {
    <#
    .SYNOPSIS
        Inicializa e exibe o formulario principal do CBSFilter.
    #>
    [CmdletBinding()]
    param()

    # Habilitar estilos visuais modernos do Windows
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # --------------------------------------------------------------------------
    # 1. Configuracao da Janela Principal
    # --------------------------------------------------------------------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "CBS Filter - Analisador de Logs do Windows"
    $form.Size = New-Object System.Drawing.Size(740, 620)
    $form.MinimumSize = New-Object System.Drawing.Size(680, 580)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    # --------------------------------------------------------------------------
    # 2. Grupo: Arquivo de Origem (Log CBS)
    # --------------------------------------------------------------------------
    $grpSource = New-Object System.Windows.Forms.GroupBox -Property @{
        Text     = " 1. Arquivo de Log CBS (Origem) "
        Location = New-Object System.Drawing.Point(15, 12)
        Size     = New-Object System.Drawing.Size(695, 95)
    }

    $lblCbsPath = New-Object System.Windows.Forms.Label -Property @{
        Text     = "Selecione o arquivo CBS.log ou arquivo rotacionado (CbsPersist_*.log):"
        Location = New-Object System.Drawing.Point(15, 25)
        AutoSize = $true
    }

    $txtCbsPath = New-Object System.Windows.Forms.TextBox -Property @{
        Location = New-Object System.Drawing.Point(15, 50)
        Size     = New-Object System.Drawing.Size(430, 25)
        Text     = (Get-DefaultCbsLogPath)
    }

    $btnBrowseSource = New-Object System.Windows.Forms.Button -Property @{
        Text     = "Procurar..."
        Location = New-Object System.Drawing.Point(455, 49)
        Size     = New-Object System.Drawing.Size(95, 27)
    }

    $btnDefaultCbs = New-Object System.Windows.Forms.Button -Property @{
        Text     = "CBS Padrao"
        Location = New-Object System.Drawing.Point(560, 49)
        Size     = New-Object System.Drawing.Size(120, 27)
    }

    $grpSource.Controls.AddRange(@($lblCbsPath, $txtCbsPath, $btnBrowseSource, $btnDefaultCbs))

    # --------------------------------------------------------------------------
    # 3. Grupo: Filtros e Palavras-Chave
    # --------------------------------------------------------------------------
    $grpFilters = New-Object System.Windows.Forms.GroupBox -Property @{
        Text     = " 2. Criterios de Filtragem e Palavras-chave "
        Location = New-Object System.Drawing.Point(15, 115)
        Size     = New-Object System.Drawing.Size(695, 255)
    }

    $lblKeywords = New-Object System.Windows.Forms.Label -Property @{
        Text     = "Palavras-chave ativas (uma por linha):"
        Location = New-Object System.Drawing.Point(15, 24)
        AutoSize = $true
    }

    $txtKeywords = New-Object System.Windows.Forms.TextBox -Property @{
        Location   = New-Object System.Drawing.Point(15, 46)
        Size       = New-Object System.Drawing.Size(320, 162)
        Multiline  = $true
        ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
        Text       = "Error`r`nWarning"
    }

    $chkCaseSensitive = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Diferenciar Maiusculas/Minusculas (Case Sensitive)"
        Location = New-Object System.Drawing.Point(15, 218)
        AutoSize = $true
    }

    # Painel de Presets
    $grpPresets = New-Object System.Windows.Forms.GroupBox -Property @{
        Text     = " Presets Rapidos "
        Location = New-Object System.Drawing.Point(350, 20)
        Size     = New-Object System.Drawing.Size(330, 222)
    }

    $chkError = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Error"
        Location = New-Object System.Drawing.Point(20, 26)
        Size     = New-Object System.Drawing.Size(130, 24)
        Checked  = $true
    }

    $chkWarning = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Warning"
        Location = New-Object System.Drawing.Point(165, 26)
        Size     = New-Object System.Drawing.Size(130, 24)
        Checked  = $true
    }

    $chkRollback = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Rollback"
        Location = New-Object System.Drawing.Point(20, 56)
        Size     = New-Object System.Drawing.Size(130, 24)
    }

    $chkCritical = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Critical"
        Location = New-Object System.Drawing.Point(165, 56)
        Size     = New-Object System.Drawing.Size(130, 24)
    }

    $chkMissing = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Missing"
        Location = New-Object System.Drawing.Point(20, 86)
        Size     = New-Object System.Drawing.Size(130, 24)
    }

    $chkCorrupt = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Corrupt / Corrompido"
        Location = New-Object System.Drawing.Point(165, 86)
        Size     = New-Object System.Drawing.Size(155, 24)
    }

    $chkFailed = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Failed / Failure"
        Location = New-Object System.Drawing.Point(20, 116)
        Size     = New-Object System.Drawing.Size(130, 24)
    }

    $chkAllPresets = New-Object System.Windows.Forms.CheckBox -Property @{
        Text     = "Filtro Completo (Todos os Erros)"
        Location = New-Object System.Drawing.Point(20, 165)
        Size     = New-Object System.Drawing.Size(280, 26)
        Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    }

    $grpPresets.Controls.AddRange(@(
        $chkError, $chkWarning, $chkRollback, $chkCritical,
        $chkMissing, $chkCorrupt, $chkFailed, $chkAllPresets
    ))

    $grpFilters.Controls.AddRange(@($lblKeywords, $txtKeywords, $chkCaseSensitive, $grpPresets))

    # --------------------------------------------------------------------------
    # 4. Grupo: Arquivo de Saida e Acoes
    # --------------------------------------------------------------------------
    $grpOutput = New-Object System.Windows.Forms.GroupBox -Property @{
        Text     = " 3. Destino e Execucao "
        Location = New-Object System.Drawing.Point(15, 380)
        Size     = New-Object System.Drawing.Size(695, 145)
    }

    $lblOutputPath = New-Object System.Windows.Forms.Label -Property @{
        Text     = "Arquivo de saida (relatorio filtrado):"
        Location = New-Object System.Drawing.Point(15, 25)
        AutoSize = $true
    }

    $txtOutputPath = New-Object System.Windows.Forms.TextBox -Property @{
        Location = New-Object System.Drawing.Point(15, 48)
        Size     = New-Object System.Drawing.Size(535, 25)
        Text     = (Get-DefaultOutputPath)
    }

    $btnBrowseOutput = New-Object System.Windows.Forms.Button -Property @{
        Text     = "Alterar..."
        Location = New-Object System.Drawing.Point(560, 47)
        Size     = New-Object System.Drawing.Size(120, 27)
    }

    # Botoes de Acao
    $btnFilter = New-Object System.Windows.Forms.Button -Property @{
        Text      = "Iniciar Filtragem"
        Location  = New-Object System.Drawing.Point(15, 90)
        Size      = New-Object System.Drawing.Size(170, 38)
        Font      = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        BackColor = [System.Drawing.Color]::FromArgb(230, 245, 230)
    }

    $btnClearKeywords = New-Object System.Windows.Forms.Button -Property @{
        Text     = "Limpar Palavras-chave"
        Location = New-Object System.Drawing.Point(195, 90)
        Size     = New-Object System.Drawing.Size(170, 38)
    }

    $grpOutput.Controls.AddRange(@(
        $lblOutputPath, $txtOutputPath, $btnBrowseOutput,
        $btnFilter, $btnClearKeywords
    ))

    # --------------------------------------------------------------------------
    # 5. Barra de Status Inferior
    # --------------------------------------------------------------------------
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel -Property @{
        Text = "Pronto. Selecione os filtros e clique em 'Iniciar Filtragem'."
    }
    $statusStrip.Items.Add($lblStatus) | Out-Null

    # Adicionar grupos ao Form
    $form.Controls.AddRange(@($grpSource, $grpFilters, $grpOutput, $statusStrip))

    # ==========================================================================
    # Logica de Controle e Sincronizacao de Estado (UI Logic)
    # ==========================================================================

    # Tabela com as palavras correspondentes a cada preset
    $presetMap = @{
        $chkError    = "Error"
        $chkWarning  = "Warning"
        $chkRollback = "Rollback"
        $chkCritical = "Critical"
        $chkMissing  = "Missing"
        $chkCorrupt  = "Corrupt"
        $chkFailed   = "Failed"
    }

    $script:isUpdatingPresets = $false

    # Atualiza a caixa de texto ao alterar uma checkbox sem apagar termos manuais
    $syncCheckboxToText = {
        param($checkbox, [string]$keyword)
        if ($script:isUpdatingPresets) { return }

        $currentLines = @($txtKeywords.Lines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne "" })

        if ($checkbox.Checked) {
            if ($currentLines -notcontains $keyword) {
                $currentLines += $keyword
            }
        } else {
            $currentLines = @($currentLines | Where-Object { $_ -ne $keyword })
        }

        $txtKeywords.Lines = $currentLines
    }

    # Associacao dos eventos das checkboxes individuais
    foreach ($chk in $presetMap.Keys) {
        $kw = $presetMap[$chk]
        $chk.Add_CheckedChanged({
            & $syncCheckboxToText $this $kw
        }.GetNewClosure())
    }

    # Evento do "Filtro Completo"
    $chkAllPresets.Add_CheckedChanged({
        if ($script:isUpdatingPresets) { return }
        $script:isUpdatingPresets = $true

        $targetState = $chkAllPresets.Checked
        $currentLines = [System.Collections.Generic.List[string]]::new(
            [string[]]@($txtKeywords.Lines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne "" })
        )

        foreach ($chk in $presetMap.Keys) {
            $chk.Checked = $targetState
            $word = $presetMap[$chk]
            if ($targetState) {
                if (-not $currentLines.Contains($word)) {
                    $currentLines.Add($word)
                }
            } else {
                $currentLines.Remove($word) | Out-Null
            }
        }

        $txtKeywords.Lines = $currentLines.ToArray()
        $script:isUpdatingPresets = $false
    })

    # Botao "CBS Padrao"
    $btnDefaultCbs.Add_Click({
        $txtCbsPath.Text = Get-DefaultCbsLogPath
        $lblStatus.Text = "Caminho padrao do CBS.log carregado."
    })

    # Botao "Procurar Arquivo de Origem"
    $btnBrowseSource.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = (Split-Path -Path $txtCbsPath.Text -Parent -ErrorAction SilentlyContinue)
            Filter           = "Arquivos de Log (*.log;*.txt)|*.log;*.txt|Arquivos Compactados (*.cab)|*.cab|Todos os Arquivos (*.*)|*.*"
            Title            = "Selecione o arquivo de log para analise"
        }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtCbsPath.Text = $dialog.FileName
            $lblStatus.Text = "Arquivo selecionado: $(Split-Path $dialog.FileName -Leaf)"
        }
    })

    # Botao "Alterar Destino"
    $btnBrowseOutput.Add_Click({
        $dialog = New-Object System.Windows.Forms.SaveFileDialog -Property @{
            InitialDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
            FileName         = (Split-Path -Path $txtOutputPath.Text -Leaf)
            Filter           = "Arquivo de Log (*.log)|*.log|Arquivo de Texto (*.txt)|*.txt"
            Title            = "Salvar resultado filtrado como"
        }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtOutputPath.Text = $dialog.FileName
        }
    })

    # Botao "Limpar Palavras-Chave"
    $btnClearKeywords.Add_Click({
        $script:isUpdatingPresets = $true
        $txtKeywords.Clear()
        foreach ($chk in $presetMap.Keys) {
            $chk.Checked = $false
        }
        $chkAllPresets.Checked = $false
        $script:isUpdatingPresets = $false
        $lblStatus.Text = "Palavras-chave e presets limpos."
    })

    # Botao "Iniciar Filtragem"
    $btnFilter.Add_Click({
        $inputPath = $txtCbsPath.Text.Trim()
        $outputPath = $txtOutputPath.Text.Trim()
        $keywords = @($txtKeywords.Lines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne "" })

        # Validacoes previas
        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor, selecione ou informe o caminho do arquivo de log.",
                "Arquivo Nao Informado",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        if (-not (Test-Path -Path $inputPath -PathType Leaf)) {
            [System.Windows.Forms.MessageBox]::Show(
                "O arquivo informado nao foi encontrado:`n`n$inputPath",
                "Arquivo Inexistente",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return
        }

        if ($keywords.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Informe ao menos uma palavra-chave para realizar o filtro.",
                "Filtro Vazio",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        # Atualizar estado da UI durante o processamento
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $btnFilter.Enabled = $false
        $lblStatus.Text = "Filtrando log, por favor aguarde..."
        $form.Update()

        try {
            $filterResult = Invoke-CBSLogFilter `
                -InputPath $inputPath `
                -Keywords $keywords `
                -OutputPath $outputPath `
                -CaseSensitive:$chkCaseSensitive.Checked

            if ($filterResult.Success) {
                $lblStatus.Text = "Filtragem concluida: $($filterResult.MatchedLines) linhas encontradas em $($filterResult.DurationSeconds)s."

                $msg = "Filtragem concluida com sucesso!`n`n" +
                       "- Total de linhas analisadas: $($filterResult.TotalLines.ToString('N0'))`n" +
                       "- Linhas filtradas encontradas: $($filterResult.MatchedLines.ToString('N0'))`n" +
                       "- Tempo decorrido: $($filterResult.DurationSeconds) segundos`n" +
                       "- Destino: $($filterResult.OutputPath)`n`n" +
                       "Deseja abrir o arquivo filtrado agora?"

                $answer = [System.Windows.Forms.MessageBox]::Show(
                    $msg,
                    "Filtragem Concluida",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )

                if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Start-Process -FilePath $filterResult.OutputPath
                }

                # Atualiza com um novo caminho sugerido para a proxima execucao
                $txtOutputPath.Text = Get-DefaultOutputPath
            } else {
                $lblStatus.Text = "Erro durante a filtragem."
                [System.Windows.Forms.MessageBox]::Show(
                    "Ocorreu um erro durante a filtragem:`n`n$($filterResult.ErrorMessage)",
                    "Erro de Processamento",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        }
        catch {
            $lblStatus.Text = "Erro inesperado."
            [System.Windows.Forms.MessageBox]::Show(
                "Ocorreu um erro inesperado:`n`n$_",
                "Erro Inesperado",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
        finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            $btnFilter.Enabled = $true
        }
    })

    # Exibir a janela como dialogo modal
    $form.ShowDialog() | Out-Null
}
