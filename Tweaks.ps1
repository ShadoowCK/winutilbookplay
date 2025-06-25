function Set-ShowFileExtensions {
  Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0
  Write-Host "Extensões de arquivo agora visíveis."
}
function Set-DisableCortana {
  Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCortana -Value 0
  Write-Host "Cortana desativada."
}
function Remove-BackgroundApps {
  Get-AppxPackage | Remove-AppxPackage
  Write-Host "Apps de segundo plano removidos."
}
function Set-EnableDarkMode {
  Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value 0
  Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value 0
  Write-Host "Tema escuro ativado."
}
