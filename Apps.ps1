# Caminho base do compartilhamento
$ShareRoot = "\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores"

function Install-Office2021 {
    Write-Host "`n[Office] Iniciando instalação..." -ForegroundColor Cyan

    $OfficeSetup   = "\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores\Office\setup.exe"
    $OfficePTBR    = "\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores\Office\officesetup.exe"

    if (Test-Path "$OfficeSetup") {
        Start-Process -FilePath "$OfficeSetup" -Wait
    } else {
        Write-Host "setup.exe não encontrado: $OfficeSetup" -ForegroundColor Red
    }

    if (Test-Path "$OfficePTBR") {
        Start-Process -FilePath "$OfficePTBR" -Wait
    } else {
        Write-Host "officesetup.exe não encontrado: $OfficePTBR" -ForegroundColor Red
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

