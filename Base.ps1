Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Funções utilitárias para carregar JSON remoto ---
function Load-JsonFromUrl($url) {
  try { return Invoke-WebRequest -UseBasicParsing $url | ConvertFrom-Json }
  catch { [System.Windows.Forms.MessageBox]::Show("Falha ao baixar $url"); return $null }
}

$appsCatalog   = Load-JsonFromUrl "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main/Apps.json"
$tweaksCatalog= Load-JsonFromUrl "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main/Tweaks.json"
if (-not $appsCatalog -or -not $tweaksCatalog) { exit }

# --- Cria form principal com tabs ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "WinUtil Empresa"
$form.Size = New-Object System.Drawing.Size(600,500)
$form.StartPosition = "CenterScreen"

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Size = New-Object System.Drawing.Size(580,450)
$tabs.Location = New-Object System.Drawing.Point(10,10)

$tabApps   = New-Object System.Windows.Forms.TabPage("Instalar Programas")
$tabTweaks = New-Object System.Windows.Forms.TabPage("Tweaks")
$tabs.TabPages.AddRange(@($tabApps,$tabTweaks))

# --- Checklist para Apps ---
$clbApps = New-Object System.Windows.Forms.CheckedListBox
$clbApps.Size = New-Object System.Drawing.Size(540,300)
$clbApps.Location = New-Object System.Drawing.Point(20,20)
foreach ($app in $appsCatalog) { $clbApps.Items.Add($app.nome) }
$tabApps.Controls.Add($clbApps)

$btnInstallApps = New-Object System.Windows.Forms.Button
$btnInstallApps.Text = "Instalar Selecionados"
$btnInstallApps.Size = New-Object System.Drawing.Size(180,40)
$btnInstallApps.Location = New-Object System.Drawing.Point(20,340)
$tabApps.Controls.Add($btnInstallApps)

# --- Checklist para Tweaks ---
$clbTweaks = New-Object System.Windows.Forms.CheckedListBox
$clbTweaks.Size = New-Object System.Drawing.Size(540,300)
$clbTweaks.Location = New-Object System.Drawing.Point(20,20)
foreach ($tweak in $tweaksCatalog) { $clbTweaks.Items.Add($tweak.nome) }
$tabTweaks.Controls.Add($clbTweaks)

$btnRunTweaks = New-Object System.Windows.Forms.Button
$btnRunTweaks.Text = "Aplicar Tweaks"
$btnRunTweaks.Size = New-Object System.Drawing.Size(180,40)
$btnRunTweaks.Location = New-Object System.Drawing.Point(20,340)
$tabTweaks.Controls.Add($btnRunTweaks)

# --- Botão Fechar ---
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Fechar"
$btnClose.Size = New-Object System.Drawing.Size(120,40)
$btnClose.Location = New-Object System.Drawing.Point(470,420)
$btnClose.Add_Click({ $form.Close() })

$form.Controls.AddRange(@($tabs,$btnClose))
$form.Topmost = $true

# --- Ações ao clicar instalar apps ---
$btnInstallApps.Add_Click({
  Invoke-Expression (Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main/Apps.ps1").Content
  foreach ($i in $clbApps.CheckedIndices) {
    $f = $appsCatalog[$i].funcao
    if (Get-Command $f -ErrorAction SilentlyContinue) { & $f } else { Write-Host "Função $f não existe." }
  }
  [System.Windows.Forms.MessageBox]::Show("Programas instalados.")
})

# --- Ações ao clicar aplicar tweaks ---
$btnRunTweaks.Add_Click({
  Invoke-Expression (Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main/Tweaks.ps1").Content
  foreach ($i in $clbTweaks.CheckedIndices) {
    $f = $tweaksCatalog[$i].funcao
    if (Get-Command $f -ErrorAction SilentlyContinue) { & $f } else { Write-Host "Função $f não existe." }
  }
  [System.Windows.Forms.MessageBox]::Show("Tweaks aplicados.")
})

# --- Exibe a janela ---
$form.ShowDialog()
