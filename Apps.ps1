## Apps.ps1 – Instalador universal
# ────────────────────────────────────────────────────────────────
# [1] Configurações globais
# ────────────────────────────────────────────────────────────────
$global:InstallShareUser  = 'mundial\_install'
$global:InstallSharePass  = 'sup@2023#'
$global:InstallBasePath   = '\\192.168.4.100\util\Programas\WinUtil\Instaladores'

# ────────────────────────────────────────────────────────────────
# [2] Executar instalador genérico
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
        Write-Error  "      ✖ Erro: $($_.Exception.Message)"
    }
}

# ────────────────────────────────────────────────────────────────
# [3] Instalar Office 2021
# ────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[3.1] Iniciando instalação do Office 2021…"

    $setupPath       = Join-Path $global:InstallBasePath 'Office\Setup.exe'
    $officeSetupPath = Join-Path $global:InstallBasePath 'Office\OfficeSetup.exe'

    # 1) Setup.exe (GUI)
    Start-Installer $setupPath

    # 2) OfficeSetup.exe (silencioso)
    Start-Installer $officeSetupPath '/quiet /norestart'

    Write-Host "[3.2] Instalação do Office finalizada."
}

# ────────────────────────────────────────────────────────────────
# [4] Instalar WinRAR
# ────────────────────────────────────────────────────────────────
function Install-WinRar {
    Write-Host "[4.1] Iniciando instalação do WinRAR…"

    $winrarPath = Join-Path $global:InstallBasePath 'WinRar\WinRar.exe'

    # Instalação padrão do WinRAR (GUI); ajuste Args se quiser silencioso /S
    Start-Installer $winrarPath

    Write-Host "[4.2] Instalação do WinRAR finalizada."
}
