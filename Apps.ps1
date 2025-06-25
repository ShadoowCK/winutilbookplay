# Apps.ps1 – instaladores com credencial fixa para acessar o servidor interno
# ---------------------------------------------------------------------------------
# ⚠️ Este arquivo contém usuário/senha em texto puro.  
#    Considere encriptar a senha (ver documentação) se distribuir fora do time de TI.

# --- Configurações globais ---------------------------------------------------------
$global:InstallShareUser  = "mundial\install"      # domínio\usuário com permissão de leitura
$global:InstallSharePass  = "sup@2023#"               # senha desse usuário
$global:InstallShareRoot  = "\\192.168.4.100\util"  # raiz do compartilhamento
$global:InstallShareDrive = "Z"                      # letra usada para mapear a unidade

# Caminho base (dentro do drive mapeado) para os instaladores
$global:ShareRoot = "$($global:InstallShareDrive):\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores\"

# --- Função utilitária: mapeia a unidade se ainda não existir ---------------------
function Connect-InstallShare {
    if (-not (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue)) {
        $sec  = ConvertTo-SecureString $global:InstallSharePass -AsPlainText -Force
        $cred = [PSCredential]::new($global:InstallShareUser,$sec)
        try {
            New-PSDrive -Name $global:InstallShareDrive -PSProvider FileSystem -Root $global:InstallShareRoot -Credential $cred -Persist -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "[ERRO] Falha ao mapear $($global:InstallShareRoot): $_" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# --- Função utilitária: desmonta a unidade ----------------------------------------
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $global:InstallShareDrive -Force
    }
}

# ----------------------------------------------------------------------------------
#                               INSTALADORES
# ----------------------------------------------------------------------------------

function Install-Office2021 {
    if (-not (Connect-InstallShare)) { return }

    Write-Host "`n[Office] Iniciando instalação..." -ForegroundColor Cyan

    $OfficeSetup   = Join-Path $global:ShareRoot "Office\Setup.exe"
    $OfficePTBR    = Join-Path $global:ShareRoot "Office\OfficeSetup.exe"

    if (Test-Path $OfficeSetup) {
        Start-Process -FilePath $OfficeSetup -Wait
    } else {
        Write-Host "setup.exe não encontrado: $OfficeSetup" -ForegroundColor Red
    }

    if (Test-Path $OfficePTBR) {
        Start-Process -FilePath $OfficePTBR -Wait
    } else {
        Write-Host "officesetup.exe não encontrado: $OfficePTBR" -ForegroundColor Red
    }

    Disconnect-InstallShare
}

function Install-Chrome {
    Write-Host "`n[Chrome] Baixando instalador..." -ForegroundColor Cyan
    $url  = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
    $dest = "$env:TEMP\\chrome_installer.exe"
    Invoke-WebRequest $url -OutFile $dest
    Start-Process $dest -ArgumentList "/silent /install" -Wait
}

function Install-7Zip {
    Write-Host "`n[7-Zip] Baixando instalador..." -ForegroundColor Cyan
    $url  = "https://www.7-zip.org/a/7z2301-x64.exe"
    $dest = "$env:TEMP\\7z.exe"
    Invoke-WebRequest $url -OutFile $dest
    Start-Process $dest -ArgumentList "/S" -Wait
}

# -------------------------------------------------------------------------------
# Adicione novos instaladores seguindo o padrão:
# - Crie uma função Install-Nome
# - Chame Connect-InstallShare / Disconnect-InstallShare se precisar acessar o servidor
# - Use $global:ShareRoot para o subcaminho
