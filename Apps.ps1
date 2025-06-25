# Apps.ps1 – instaladores com etapas numeradas para debug organizado
# ------------------------------------------------------------------
# Este script executa instaladores diretamente do compartilhamento UNC
# sem mapear unidade (Z:). Ele apenas autentica a sessão SMB com
# `net use` e dispara o executável no local.

# ──────────────────────────────────────────────────────────────────
# [Etapa 1] - Configurações globais
# ──────────────────────────────────────────────────────────────────
$global:InstallShareUser = 'mundial\_install'                # domínio\usuário
$global:InstallSharePass = 'sup@2023#'                       # senha desse usuário
$global:InstallShareRoot = '\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores'
$global:ShareRoot        = $global:InstallShareRoot          # raiz UNC para todos os instaladores

# ──────────────────────────────────────────────────────────────────
# [Etapa 2] - Autenticar sessão SMB (sem mapear unidade)
# ──────────────────────────────────────────────────────────────────
function Connect-InstallShare {
    # Verifica se já existe credencial para o host
    $existing = (cmd.exe /c "net use" | Select-String "192.168.4.100").Line
    if ($existing) {
        Write-Host "[2.1] Já autenticado em 192.168.4.100."; return $true
    }

    $cmd = "net use `"$($global:InstallShareRoot)`" /user:$($global:InstallShareUser) $($global:InstallSharePass) /persistent:no"
    Write-Host "[2.2] Autenticando com: $cmd"
    cmd.exe /c "$cmd"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[2.3] Autenticação OK."; return $true
    } else {
        Write-Host "[2.3] Falha na autenticação." -ForegroundColor Red
        return $false
    }
}

# ──────────────────────────────────────────────────────────────────
# [Etapa 3] - Encerrar sessão SMB (opcional)
# ──────────────────────────────────────────────────────────────────
function Disconnect-InstallShare {
    cmd.exe /c "net use \"$($global:InstallShareRoot)\" /delete /yes" | Out-Null
    Write-Host "[3.1] Sessão com 192.168.4.100 encerrada."
}


# ──────────────────────────────────────────────────────────────────
# [Etapa 4] - Executar instalador silencioso diretamente do share
# ──────────────────────────────────────────────────────────────────
function Invoke-SilentInstallDirect {
    param (
        [string]$ExePath,
        [string]$Arguments = '/quiet /norestart'
    )

    if (-not (Test-Path $ExePath)) {
        Write-Host "[4.1] Arquivo não encontrado: $ExePath" -ForegroundColor Red
        return
    }

    Write-Host "[4.2] Executando: $ExePath $Arguments"
    try {
        Start-Process -FilePath $ExePath -ArgumentList $Arguments -Wait -ErrorAction Stop
        Write-Host "      ✔ Instalação concluída."
    } catch {
        Write-Error  "      ✖ Falha: $($_.Exception.Message)"
    }
}
# ──────────────────────────────────────────────────────────────────
# [Etapa 5] - Instalar Office 2021 (direto do compartilhamento)
# ──────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[5.1] Iniciando instalação silenciosa do Office..."
    if (-not (Connect-InstallShare)) { return }

    $officeDir = Join-Path $global:ShareRoot 'Office'
    $setupExe       = Join-Path $officeDir 'Setup.exe'
    $officeSetupExe = Join-Path $officeDir 'OfficeSetup.exe'
    $configPath     = Join-Path $officeDir 'config.xml'

    $installSteps = @(
        @{ Path = $setupExe;       Name = 'Setup.exe'       }
        @{ Path = $officeSetupExe; Name = 'OfficeSetup.exe' }
    )

    $step = 0; $total = $installSteps.Count
    foreach ($item in $installSteps) {
        $step++
        $exePath = $item.Path
        $exeName = $item.Name

        Write-Progress -Activity 'Instalando Office' -Status "Passo $step/${total}: $exeName" -PercentComplete (($step-1)/$total*100)

        if (-not (Test-Path $exePath)) {
            Write-Warning "[5.$step] $exeName não encontrado: $exePath — pulando."
            continue
        }

        # Usa /configure apenas para Setup.exe se config.xml existir
        $installArgs = if ($exeName -eq 'Setup.exe' -and (Test-Path $configPath)) {
            "/configure `"$configPath`""
        } else {
            '/quiet /norestart'
        }

        Invoke-SilentInstallDirect $exePath $installArgs
    }

    Write-Progress -Activity 'Instalando Office' -Completed
    #Disconnect-InstallShare   # opcional
}

# [Etapa 6] - Instalação do Chrome
function Install-Chrome {
    Write-Host "[6.1] Baixando Chrome..."
    $url='https://dl.google.com/chrome/install/latest/chrome_installer.exe'
    $dest="$env:TEMP\chrome_installer.exe"
    Invoke-WebRequest $url -OutFile $dest
    Write-Host "[6.2] Executando instalador do Chrome..."
    Start-Process $dest -Arg '/silent /install' -Wait
}

# [Etapa 7] - Instalação do 7-Zip
function Install-7Zip {
    Write-Host "[7.1] Baixando 7-Zip..."
    $url='https://www.7-zip.org/a/7z2301-x64.exe'
    $dest="$env:TEMP\7z.exe"
    Invoke-WebRequest $url -OutFile $dest
    Write-Host "[7.2] Executando instalador do 7-Zip..."
    Start-Process $dest -Arg '/S' -Wait
}
