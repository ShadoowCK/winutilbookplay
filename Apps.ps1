# Caminho base do seu compartilhamento
$ShareRoot = "\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores"

function Install-Office2021 {
    Write-Host "`n[Office] Iniciando instalação..." -ForegroundColor Cyan
    $setup          = Join-Path $ShareRoot "setup.exe"
    $setupTraducao  = Join-Path $ShareRoot "officesetup.exe"

    if (Test-Path $setup)         { Start-Process $setup         -Wait }
    else                          { Write-Host "setup.exe não encontrado!" -ForegroundColor Red }

    if (Test-Path $setupTraducao) { Start-Process $setupTraducao -Wait }
    else                          { Write-Host "officesetup.exe não encontrado!" -ForegroundColor Red }
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
