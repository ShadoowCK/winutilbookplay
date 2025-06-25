# Apps.ps1 – instaladores com credencial fixa para acessar o servidor interno
# ---------------------------------------------------------------------------------
# ⚠️ Este arquivo contém usuário/senha em texto puro. 
#    Considere encriptar a senha (ver documentação) se distribuir fora do time de TI.

# --- Configurações globais ---------------------------------------------------------
$global:InstallShareUser  = 'mundial\install'        # domínio\usuário com permissão de leitura
$global:InstallSharePass  = 'sup@2023#'              # senha desse usuário
$global:InstallShareRoot  = "\\192.168.4.100\util"  # raiz do compartilhamento
$global:InstallShareDrive = 'Z'                      # letra usada para mapear a unidade

# Caminho base (dentro do drive mapeado) para os instaladores
$global:ShareRoot = "$($global:InstallShareDrive):\01 - Programas\WinUtil\Instaladores"

# --- Função utilitária: mapeia a unidade se ainda não existir ---------------------
function Connect-InstallShare {
    if (-not (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue)) {
        try {
            cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
            $cmd = "net use $($global:InstallShareDrive): $($global:InstallShareRoot) /user:$($global:InstallShareUser) $($global:InstallSharePass) /persistent:no"
            cmd.exe /c $cmd | Out-Null
            Start-Sleep -Seconds 1
            return (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) -ne $null
        }
        catch { Write-Host "[ERRO] Falha ao mapear: $_" -ForegroundColor Red; return $false }
    }
    return $true
}
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $global:InstallShareDrive -Force
        cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
    }
}

# --- Função genérica para execução silenciosa ------------------------------------
function Invoke-SilentInstall {
    param(
        [string]$SourceExe,
        [string]$Args = '/quiet /norestart'
    )
    if (-not (Test-Path $SourceExe)) { Write-Host "Arquivo não encontrado: $SourceExe" -ForegroundColor Red; return }
    $tmpExe = Join-Path $env:TEMP ([IO.Path]::GetFileName($SourceExe))
    Copy-Item $SourceExe $tmpExe -Force
    Unblock-File $tmpExe
    Start-Process -FilePath $tmpExe -ArgumentList $Args -Wait
    Remove-Item $tmpExe -Force -ErrorAction SilentlyContinue
}

# ----------------------------------------------------------------------------------
#                               INSTALADORES
# ----------------------------------------------------------------------------------
function Install-Office2021 {
    if (-not (Connect-InstallShare)) { return }
    Write-Host "`n[Office] Instalação silenciosa..." -ForegroundColor Cyan

    $executaveis = @(
        Join-Path $global:ShareRoot 'Office\setup.exe',
        Join-Path $global:ShareRoot 'Office\officesetup.exe'
    )
    $step = 0; $total = $executaveis.Count
    foreach ($exe in $executaveis) {
        $step++
        Write-Progress -Activity 'Instalando Office' -Status "Etapa $step de $total" -PercentComplete (($step-1)/$total*100)
        Invoke-SilentInstall $exe
    }
    Write-Progress -Activity 'Instalando Office' -Completed
    Disconnect-InstallShare
}

function Install-Chrome {
    Write-Host "`n[Chrome] Baixando instalador..." -ForegroundColor Cyan
    $url  = 'https://dl.google.com/chrome/install/latest/chrome_installer.exe'
    $dest = "$env:TEMP\chrome_installer.exe"
    Invoke-WebRequest $url -OutFile $dest
    Start-Process $dest -ArgumentList '/silent /install' -Wait
}

function Install-7Zip {
    Write-Host "`n[7-Zip] Baixando instalador..." -ForegroundColor Cyan
    $url  = 'https://www.7-zip.org/a/7z2301-x64.exe'
    $dest = "$env:TEMP\7z.exe"
    Invoke-WebRequest $url -OutFile $dest
    Start-Process $dest -ArgumentList '/S' -Wait
}

# -------------------------------------------------------------------------------
# Para adicionar mais instaladores:
# 1. Crie Install-Nome seguindo o padrão.
# 2. Use Connect-InstallShare/Disconnect-InstallShare para arquivos de rede.
# 3. Utilize Invoke-SilentInstall para execução sem prompt.
