# Apps.ps1 – instaladores com etapas numeradas para debug organizado
# ------------------------------------------------------------------
# Ajuste os dados de usuário/senha se necessário.

# ──────────────────────────────────────────────────────────────────
# [Etapa 1] - Configurações globais
# ──────────────────────────────────────────────────────────────────
$global:InstallShareUser  = 'mundial\_install'                # domínio\usuário
$global:InstallSharePass  = 'sup@2023#'                       # senha
$global:InstallShareRoot  = '\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores'
$global:InstallShareDrive = 'Z'                               # letra a mapear
$global:ShareRoot         = "$($global:InstallShareDrive):"   # raiz local após mapeamento (Z:)

# ──────────────────────────────────────────────────────────────────
# [Etapa 2] - Mapear unidade de rede
# ──────────────────────────────────────────────────────────────────
function Connect-InstallShare {
    if (-not (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue)) {
        try {
            Write-Host "[2.1] Removendo mapeamento anterior (se existir)..."
            cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null

            $cmd = "net use $($global:InstallShareDrive): `"$($global:InstallShareRoot)`" /user:`"$($global:InstallShareUser)`" `"$($global:InstallSharePass)`" /persistent:no"
            Write-Host "[2.2] Executando: $cmd"
            cmd.exe /c $cmd | Out-Null

            Start-Sleep 1
            if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
                Write-Host "[2.3] Mapeamento realizado com sucesso."
                return $true
            } else {
                Write-Host "[2.3] Falha no mapeamento." -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "[2.4] [ERRO] Falha ao mapear: $_" -ForegroundColor Red
            return $false
        }
    }
    Write-Host "[2.5] Unidade já mapeada."
    return $true
}

# ──────────────────────────────────────────────────────────────────
# [Etapa 3] - Desmontar unidade
# ──────────────────────────────────────────────────────────────────
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Write-Host "[3.1] Desmontando unidade..."
        Remove-PSDrive -Name $global:InstallShareDrive -Force
        cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
    }
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
        Start-Process $ExePath -ArgumentList $Arguments -Wait -ErrorAction Stop
        Write-Host "      ✔ Instalação concluída."
    } catch {
        Write-Error  "      ✖ Falha: $($_.Exception.Message)"
    }
}

# ──────────────────────────────────────────────────────────────────
# [Etapa 5] - Instalar Office 2021 diretamente do compartilhamento
# ──────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[5.1] Iniciando instalação silenciosa do Office..."

    if (-not (Connect-InstallShare)) { return }

    $setupPath  = Join-Path $global:ShareRoot 'Office\Setup.exe'
    $configPath = Join-Path (Split-Path $setupPath) 'config.xml'

    if (-not (Test-Path $setupPath)) {
        Write-Host "[5.2] Setup.exe não encontrado: $setupPath" -ForegroundColor Red
        Disconnect-InstallShare
        return
    }

    # Decide argumentos: se houver config.xml, usa /configure; senão, /quiet /norestart.
    if (Test-Path $configPath) {
        $installArgs = "/configure `"$configPath`""
    } else {
        $installArgs = '/quiet /norestart'
    }

    Invoke-SilentInstallDirect $setupPath $installArgs

    Disconnect-InstallShare
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
