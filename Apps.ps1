## Apps.ps1 – Instalador universal
# ────────────────────────────────────────────────────────────────
# [1] Configurações globais
# ────────────────────────────────────────────────────────────────
$global:InstallShareUser  = 'mundial\_install'
$global:InstallSharePass  = 'sup@2023#'
$global:InstallBasePath   = '\\192.168.4.100\util\WinUtil\Instaladores'

# ────────────────────────────────────────────────────────────────
# [2] Executar instalador
# ────────────────────────────────────────────────────────────────
function Start-Installer {
    param(
        [string]$FullExePath,
        [string]$InstallerArgs = $null
    )

    if (-not (Test-Path $FullExePath)) {
        Write-Host "[2.1] NÃO encontrado: $FullExePath" -ForegroundColor Red
        return
    }

    Write-Host "[2.2] Executando: $FullExePath $InstallerArgs"
    try {
        $proc = if ($InstallerArgs) {
            Start-Process -FilePath $FullExePath -ArgumentList $InstallerArgs -Wait -PassThru -ErrorAction Stop
        } else {
            Start-Process -FilePath $FullExePath -Wait -PassThru -ErrorAction Stop
        }
        Write-Host "      ✔ ExitCode=$($proc.ExitCode)"
    } catch {
        Write-Error "      ✖ Erro: $($_.Exception.Message)"
    }
}

# ────────────────────────────────────────────────────────────────
# [3] Instalar Office 2021
# ────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[3.1] Iniciando instalação do Office 2021…"

    # Caminho completo para os instaladores
    $setupPath        = Join-Path $global:InstallBasePath '\Office\Setup.exe'
    $officeSetupPath  = Join-Path $global:InstallBasePath '\Office\OfficeSetup.exe'

    # 1) Setup.exe (GUI)
    Start-Installer $setupPath

    # 2) OfficeSetup.exe (silencioso)
    Start-Installer $officeSetupPath '/quiet /norestart'

    Write-Host "[3.2] Processo concluído."
}

# [Etapa 8] - Instalação do 7-Zip
function Install-7Zip {
    Write-Host "[7.1] Baixando 7-Zip..."
    $url='https://www.7-zip.org/a/7z2301-x64.exe'
    $dest="$env:TEMP\7z.exe"
    Invoke-WebRequest $url -OutFile $dest
    Write-Host "[7.2] Executando instalador do 7-Zip..."
    Start-Process $dest -Arg '/S' -Wait
}
