## Apps.ps1 – Instalador universal
# ────────────────────────────────────────────────────────────────
# [1] Configurações globais
# ────────────────────────────────────────────────────────────────
$global:InstallShareUser = 'mundial\_install'
$global:InstallSharePass = 'sup@2023#'
$global:ShareRoot        = '\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores'

# ────────────────────────────────────────────────────────────────
# [2] Autenticar sessão SMB
# ────────────────────────────────────────────────────────────────
function Connect-InstallShare {
    $exists = (cmd.exe /c "net use" | Select-String "192.168.4.100").Line
    if ($exists) { Write-Host "[2.1] Já autenticado."; return $true }

    $cmd = "net use `"$($global:ShareRoot)`" /user:$($global:InstallShareUser) $($global:InstallSharePass) /persistent:no"
    Write-Host "[2.2] Autenticando…"
    cmd.exe /c $cmd | Out-Null

    if ($LASTEXITCODE -eq 0) { Write-Host "[2.3] Autenticação OK."; return $true }
    Write-Host "[2.3] Falha na autenticação." -ForegroundColor Red; return $false
}

# ────────────────────────────────────────────────────────────────
# [3] Helper: localizar arquivo
# ────────────────────────────────────────────────────────────────
function Resolve-InstallerPath {
    param([string]$Relative)
    $full = Join-Path $global:ShareRoot $Relative
    if (Test-Path $full) { Write-Host "[3] Encontrado: $full"; return $full }
    Write-Host "[3] NÃO encontrado: $full" -ForegroundColor Red; return $null
}

# ────────────────────────────────────────────────────────────────
# [4] Start-Installer  → executa EXE com ou sem argumentos
# ────────────────────────────────────────────────────────────────
function Start-Installer {
    param(
        [string]$RelativeExe,
        [string]$Arguments = $null
    )

    $exe = Resolve-InstallerPath $RelativeExe
    if (-not $exe) { return }

    Write-Host "[4] Executando: $exe $Arguments"
    try {
        $proc = if ($Arguments) {
            Start-Process -FilePath $exe -ArgumentList $Arguments -Wait -PassThru -ErrorAction Stop
        } else {
            Start-Process -FilePath $exe -Wait -PassThru -ErrorAction Stop
        }
        Write-Host "      ✔ ExitCode=$($proc.ExitCode)"
    }
    catch {
        Write-Error "      ✖ Falha -> $($_.Exception.Message)"
    }
}

# ────────────────────────────────────────────────────────────────
# [5] Install-Office2021  (Setup.exe ➜ OfficeSetup.exe)
# ────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[5] Iniciando instalação do Office 2021…"
    if (-not (Connect-InstallShare)) { return }

    Start-Installer 'Office\Setup.exe'
    Start-Installer 'Office\OfficeSetup.exe' '/quiet /norestart'

    Write-Host "[5] Processo concluído."
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
