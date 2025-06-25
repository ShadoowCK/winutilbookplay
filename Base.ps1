# winutil.ps1
Write-Host "Instalando Google Chrome..."
Start-Process "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -Wait

Write-Host "Instalando 7-Zip..."
Start-Process "https://www.7-zip.org/a/7z2301-x64.exe" -Wait

Write-Host "Tudo instalado com sucesso!"
