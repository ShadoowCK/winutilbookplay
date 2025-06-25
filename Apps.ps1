# Apps.ps1 – instaladores com credencial fixa para acessar o servidor interno
# ---------------------------------------------------------------------------------
# ⚠️ Este arquivo contém usuário/senha em texto puro.  
#    Considere encriptar a senha (ver documentação) se distribuir fora do time de TI.

# --- Configurações globais ---------------------------------------------------------
$global:InstallShareUser  = 'mundial\_install'       # domínio\usuário com permissão de leitura
$global:InstallSharePass  = "sup@2023#"             # senha desse usuário
$global:InstallShareRoot  = "\\192.168.4.100\util"  # raiz do compartilhamento
$global:InstallShareDrive = "Z"                      # letra usada para mapear a unidade

# Caminho base (dentro do drive mapeado) para os instaladores
$global:ShareRoot = "$($global:InstallShareDrive):\01 - Programas\WinUtil\Instaladores"

# --- Função utilitária: mapeia a unidade se ainda não existir ---------------------
function Connect-InstallShare {
    if (-not (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue)) {
        try {
            Write-Host "Tentando mapear $($global:InstallShareRoot) com net use" -ForegroundColor Yellow
            
            # Remove mapeamento antigo se existir para evitar conflito
            cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
            
            # Monta comando net use com credenciais
            $cmd = "net use $($global:InstallShareDrive): $($global:InstallShareRoot) /user:$($global:InstallShareUser) $($global:InstallSharePass) /persistent:no"
            Write-Host "Executando: $cmd" -ForegroundColor Cyan
            
            cmd.exe /c $cmd
            
            Start-Sleep -Seconds 1 # Pequena pausa para o sistema processar
            
            if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
                Write-Host "Mapeamento realizado com sucesso via net use." -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "[ERRO] Falha no mapeamento via net use." -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "[ERRO] Exceção no net use: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "Unidade $($global:InstallShareDrive): já mapeada." -ForegroundColor Green
        return $true
    }
}

# --- Função utilitária: desmonta a unidade ----------------------------------------
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $global:InstallShareDrive -Force
    }
    # Remove também via net use para garantir limpeza completa
    cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
}

# ----------------------------------------------------------------------------------
#                               INSTALADORES
# ----------------------------------------------------------------------------------

function Install-Office2021 {
    if (-not (Connect-InstallShare)) { return }

    Write-Host "`n[Office] Iniciando instalação silenciosa..." -ForegroundColor Cyan

    $OfficeSetup   = Join-Path $global:ShareRoot "Office\\setup.exe"
    $OfficePTBR    = Join-Path $global:ShareRoot "Office\\officesetup.exe"

    if (Test-Path $OfficeSetup) {
        Write-Host "[Office] Executando setup.exe em modo silencioso..." -ForegroundColor Green
        Start-Process "cmd.exe" -ArgumentList "/c `"$OfficeSetup`" /quiet /norestart" -Wait
    } else {
        Write-Host "setup.exe não encontrado: $OfficeSetup" -ForegroundColor Red
    }

    if (Test-Path $OfficePTBR) {
        Write-Host "[Office] Executando officesetup.exe em modo silencioso..." -ForegroundColor Green
        Start-Process "cmd.exe" -ArgumentList "/c `"$OfficePTBR`" /quiet /norestart" -Wait
    } else {
        Write-Host "officesetup.exe não encontrado: $OfficePTBR" -ForegroundColor Red
    }

    Disconnect-InstallShare
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

# -------------------------------------------------------------------------------
# Adicione novos instaladores seguindo o padrão:
# - Crie uma função Install-Nome
# - Chame Connect-InstallShare / Disconnect-InstallShare se precisar acessar o servidor
# - Use $global:ShareRoot para o subcaminho
