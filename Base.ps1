<#
.SYNOPSIS
  WinUtilEmpresa – instalador modular inspirado no Chris Titus Tech
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

############################
# 1. Carrega catálogo JSON #
############################
$catalogoUrl = "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main/Apps.json"
try   { $catalogo = Invoke-WebRequest -UseBasicParsing -Uri $catalogoUrl | ConvertFrom-Json }
catch { Write-Host "Falha ao baixar catálogo Apps.json" -ForegroundColor Red ; exit }

######################################
# 2. Cria interface com checklistbox #
######################################
$form              = New-Object System.Windows.Forms.Form
$form.Text         = "WinUtil Empresa"
$form.Size         = New-Object System.Drawing.Size(500,400)
$form.StartPosition= "CenterScreen"

$clb = New-Object System.Windows.Forms.CheckedListBox
$clb.Size          = New-Object System.Drawing.Size(460,250)
$clb.Location      = New-Object System.Drawing.Point(10,10)

foreach ($app in $catalogo) { $clb.Items.Add($app.nome) }

$btnInstalar       = New-Object System.Windows.Forms.Button
$btnInstalar.Text  = "Instalar Selecionados"
$btnInstalar.Size  = New-Object System.Drawing.Size(200,40)
$btnInstalar.Location = New-Object System.Drawing.Point(10,280)

$btnFechar         = New-Object System.Windows.Forms.Button
$btnFechar.Text    = "Fechar"
$btnFechar.Size    = New-Object System.Drawing.Size(120,40)
$btnFechar.Location= New-Object System.Drawing.Point(350,280)

###########################################################
# 3. Quando clicar, baixa Apps.ps1 e executa app a app    #
###########################################################
$btnInstalar.Add_Click({
    # Carrega as funções de instalação
    $appsUrl = "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main/Apps.ps1"
    try   { Invoke-Expression (Invoke-WebRequest -UseBasicParsing $appsUrl).Content }
    catch { [System.Windows.Forms.MessageBox]::Show("Falha ao baixar Apps.ps1") ; return }

    # Para cada item marcado, chama a função especificada no JSON
    foreach ($indice in $clb.CheckedIndices) {
        $appObj   = $catalogo[$indice]
        $funcName = $appObj.funcao
        if (Get-Command $funcName -ErrorAction SilentlyContinue) {
            & $funcName
        } else {
            Write-Host "Função $funcName não encontrada." -ForegroundColor Yellow
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Processo concluído!")
})

$btnFechar.Add_Click({ $form.Close() })

$form.Controls.AddRange(@($clb,$btnInstalar,$btnFechar))
$form.Topmost = $true
$form.ShowDialog()
//teste tortoise