## Apps.ps1 – Instalador universal
# ────────────────────────────────────────────────────────────────
# [1] Configurações globais
# ────────────────────────────────────────────────────────────────
$global:InstallShareUser   = 'mundial\_install'
$global:InstallSharePass   = 'sup@2023#'
$global:InstallShareRoot   = '\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores'
$global:InstallShareDrive  = 'Z'                     # letra a mapear
$global:MappedRoot        = "$($global:InstallShareDrive):"  # ex: Z:

# ────────────────────────────────────────────────────────────────
# [2] Mapear unidade (sem salvar credenciais)
# ────────────────────────────────────────────────────────────────
function Connect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Write-Host "[2.1] Unidade $($global:InstallShareDrive): já mapeada."
        return $true
    }

    Write-Host "[2.2] Mapeando $($global:InstallShareDrive): para $global:InstallShareRoot…"
    $cmd = "net use $($global:InstallShareDrive): `"$($global:InstallShareRoot)`" /user:$($global:InstallShareUser) $($global:InstallSharePass) /persistent:no"
    cmd.exe /c "$cmd" | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[2.3] Mapeamento OK."
        return $true
    } else {
        Write-Host "[2.3] Falha ao mapear." -ForegroundColor Red
        return $false
    }
}

# ────────────────────────────────────────────────────────────────
# [3] Desmontar unidade (boa prática)
# ────────────────────────────────────────────────────────────────
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Write-Host "[3.1] Desmontando $($global:InstallShareDrive): …"
        cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
    }
}

# ────────────────────────────────────────────────────────────────
# [4] Localizar instalador
# ────────────────────────────────────────────────────────────────
function Get-InstallerPath {
    param([string]$RelativePath)           # ex: 'Office\Setup.exe'
    $fullPath = Join-Path $global:MappedRoot $RelativePath
    if (Test-Path $fullPath) {
        Write-Host "[4.1] Encontrado: $fullPath"; return $fullPath }
    Write-Host "[4.1] NÃO encontrado: $fullPath" -ForegroundColor Red; return $null
}

# ────────────────────────────────────────────────────────────────
# [5] Executar instalador
# ────────────────────────────────────────────────────────────────
function Start-Installer {
    param(
        [string]$RelativeExe,
        [string]$Arguments = $null
    )

    $exePath = Get-InstallerPath $RelativeExe
    if (-not $exePath) { return }

    Write-Host "[5] Executando: $exePath $Arguments"
    try {
        if ($Arguments) {
            Start-Process -FilePath $exePath -ArgumentList $Arguments -Wait -PassThru -ErrorAction Stop
        } else {
            Start-Process -FilePath $exePath -Wait -PassThru -ErrorAction Stop
        }
        Write-Host "      ✔ Concluído."
    } catch {
        Write-Error "      ✖ Erro: $($_.Exception.Message)"
    }
}

# ────────────────────────────────────────────────────────────────
# [6] Instalar Office 2021
# ────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[6.1] Iniciando instalação do Office…"
    if (-not (Connect-InstallShare)) { return }

    Start-Installer 'Office\Setup.exe'            # GUI
    Start-Installer 'Office\OfficeSetup.exe' '/quiet /norestart'

    Disconnect-InstallShare
    Write-Host "[6.2] Processo concluído."
}

# [Etapa 7] - Instalação do Chrome
function Install-Chrome {
    Write-Host "[6.1] Baixando Chrome..."
    $url='https://dl.google.com/chrome/install/latest/chrome_installer.exe'
    $dest="$env:TEMP\chrome_installer.exe"
    Invoke-WebRequest $url -OutFile $dest
    Write-Host "[6.2] Executando instalador do Chrome..."
    Start-Process $dest -Arg '/silent /install' -Wait
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
