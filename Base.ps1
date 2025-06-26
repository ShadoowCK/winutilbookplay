# Base.ps1 – Interface GUI WinUtil (corrigido para não ficar oculto atrás do console)
# ---------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Oculta o console que executou o script --------------------------------------
Add-Type @" 
using System; using System.Runtime.InteropServices; 
public class Win32 { [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); 
                     [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); } 
"@
$consolePtr = [Win32]::GetConsoleWindow()
if ($consolePtr -ne [IntPtr]::Zero) { [Win32]::ShowWindow($consolePtr, 0) }   # 0 = SW_HIDE

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Carrega catálogos -----------------------------------------------------------
function Get-Catalog ($url) {
    try   { (Invoke-WebRequest -UseBasicParsing $url).Content | ConvertFrom-Json }
    catch { [System.Windows.Forms.MessageBox]::Show("Falha ao baixar " + $url); return $null }
}

$repoRoot = "https://raw.githubusercontent.com/ShadoowCK/winutilbookplay/main"
$appsCatalog   = Get-Catalog "$repoRoot/Apps.json"
$tweaksCatalog = Get-Catalog "$repoRoot/Tweaks.json"
if (-not $appsCatalog -or -not $tweaksCatalog) { exit }

# --- Form ------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "WinUtil BookPlay"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(620,520)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# --- Tabs ------------------------------------------------------------------------
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = 'Fill'

$tabApps   = New-Object System.Windows.Forms.TabPage("Instalar Programas")
$tabTweaks = New-Object System.Windows.Forms.TabPage("Tweaks")
$tabs.TabPages.AddRange(@($tabApps,$tabTweaks))
$form.Controls.Add($tabs)

# --- Checklist Apps --------------------------------------------------------------
$clbApps = New-Object System.Windows.Forms.CheckedListBox
$clbApps.Dock = 'Top'
$clbApps.Height = 350
foreach ($a in $appsCatalog) { $clbApps.Items.Add($a.nome) }
$tabApps.Controls.Add($clbApps)

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text = 'Instalar Selecionados'
$btnInstalar.Height = 35
$btnInstalar.Dock = 'Bottom'
$tabApps.Controls.Add($btnInstalar)

# --- Checklist Tweaks ------------------------------------------------------------
$clbTweaks = New-Object System.Windows.Forms.CheckedListBox
$clbTweaks.Dock = 'Top'
$clbTweaks.Height = 350
foreach ($t in $tweaksCatalog) { $clbTweaks.Items.Add($t.nome) }
$tabTweaks.Controls.Add($clbTweaks)

$btnTweaks = New-Object System.Windows.Forms.Button
$btnTweaks.Text = 'Aplicar Tweaks'
$btnTweaks.Height = 35
$btnTweaks.Dock = 'Bottom'
$tabTweaks.Controls.Add($btnTweaks)

# --- Botão fechar ----------------------------------------------------------------
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = 'Fechar'
$btnClose.Dock = 'Bottom'
$btnClose.Height = 35
$form.Controls.Add($btnClose)

# --- Eventos ---------------------------------------------------------------------
$btnClose.Add_Click({ $form.Close() })

$btnInstalar.Add_Click({
    Invoke-Expression (Invoke-WebRequest -UseBasicParsing "$repoRoot/Apps.ps1").Content
    foreach ($i in $clbApps.CheckedIndices) { & $appsCatalog[$i].funcao }
    [System.Windows.Forms.MessageBox]::Show("Instalação concluída.")
})

$btnTweaks.Add_Click({
    Invoke-Expression (Invoke-WebRequest -UseBasicParsing "$repoRoot/Tweaks.ps1").Content
    foreach ($i in $clbTweaks.CheckedIndices) { & $tweaksCatalog[$i].funcao }
    [System.Windows.Forms.MessageBox]::Show("Tweaks aplicados.")
})

# --- Exibe GUI -------------------------------------------------------------------
$form.TopMost = $true
$form.ShowDialog()
