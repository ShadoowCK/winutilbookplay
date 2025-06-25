# Caminho base do compartilhamento
$ShareRoot = "\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores"

function Install-Office2021 {
    Write-Host "`n[Office] Iniciando instalação..." -ForegroundColor Cyan

    # --- pasta específica do Office ---
    $OfficeDir     = Join-Path "$ShareRoot" "Office"
    $setup         = Join-Path "$OfficeDir" "setup.exe"
    $setupTraducao = Join-Path "$OfficeDir" "officesetup.exe"

    # --- installer principal ---
    if (Test-Path "$setup") {
        Write-Host "Executando $setup"
        Start-Process "$setup" -Wait          # acrescente /quiet /configure … se precisar silencioso
    } else {
        Write-Host "setup.exe não encontrado em $OfficeDir" -ForegroundColor Red
    }

    # --- pacote de idioma ---
    if (Test-Path "$setupTraducao") {
        Write-Host "Executando $setupTraducao"
        Start-Process "$setupTraducao" -Wait  # idem: parâmetros silenciosos, se houver
    } else {
        Write-Host "officesetup.exe não encontrado em $OfficeDir" -ForegroundColor Red
    }
}
function Install-Chrome {
    Write-Host "`n[Chrome] Baixando instalador..." -ForegroundColor Cyan
    $url  = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
    $dest = "$env:TEMP\chrome_installer.exe"
    Invoke-WebRequest $url -OutFile $dest
    Start-Process $dest -ArgumentList "/silent /install" -Wait
}

function Install-7Zip {
    Write-Host "`n[7-Zip] Baixando instalador..." -ForegroundColor Cyan
    $url  = "https://www.7-zip.org/a/7z2301-x64.exe"
    $dest = "$env:TEMP\7z.exe"
    Invoke-WebRequest $url -OutFile $dest
    Start-Process $dest -ArgumentList "/S" -Wait
}
