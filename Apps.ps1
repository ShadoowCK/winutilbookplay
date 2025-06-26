## Apps.ps1 – Instalador universal (passo a passo)
# ---------------------------------------------------------------
# Objetivo: localizar qualquer instalador em
#           \\192.168.4.100\util\01 - Programas\WinUtil\Instaladores
#           e executá‑lo em ordem definida, SEM mapear unidade.
#
# Fluxo para Office 2021
#   1. Executa Setup.exe sem argumentos (mesmo comportamento do clique manual)
#   2. Em seguida executa OfficeSetup.exe /quiet /norestart
#
# Cada passo é numerado para depuração.

# ────────────────────────────────────────────────────────────────
# [Passo 1] - Configurações globais
# ────────────────────────────────────────────────────────────────
$global:InstallShareUser = 'mundial\_install'
$global:InstallSharePass = 'sup@2023#'
$global:ShareRoot        = '\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores'

# ────────────────────────────────────────────────────────────────
# [Passo 2] - Autenticar sessão SMB (sem mapear unidade)
# ────────────────────────────────────────────────────────────────
function Connect-InstallShare {
    $existing = (cmd.exe /c "net use" | Select-String "192.168.4.100").Line
    if ($existing) { Write-Host "[2.1] Já autenticado."; return $true }

    $cmd = "net use `"$global:ShareRoot`" /user:$global:InstallShareUser $global:InstallSharePass /persistent:no"
    Write-Host "[2.2] Autenticando: $cmd"
    cmd.exe /c $cmd | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "[2.3] Autenticação OK."; return $true }
    Write-Host "[2.3] Falha na autenticação." -ForegroundColor Red; return $false
}

# ────────────────────────────────────────────────────────────────
# [Passo 3] - Helper: localizar arquivo dentro do share
# ────────────────────────────────────────────────────────────────
function Get-InstallerPath {
    param([string]$RelativePath)
    $full = Join-Path $global:ShareRoot $RelativePath
    if (Test-Path $full) {
        Write-Host "[3.2] Encontrado: $full"; return $full
    }
    Write-Host "[3.1] Não encontrado: $full" -ForegroundColor Red; return $null
}

# ────────────────────────────────────────────────────────────────
# [Passo 4] - Executar instalador
# ────────────────────────────────────────────────────────────────
function Start-Installer {
    param(
        [string]$RelativeExe,
        [string]$Arguments = ''
    )
    $exePath = Get-InstallerPath $RelativeExe
    if (-not $exePath) { return }

    Write-Host "[4.x] Executando: $exePath $Arguments"
    try {
        $p = Start-Process -FilePath $exePath -ArgumentList $Arguments -Wait -PassThru -ErrorAction Stop
        Write-Host "      ✔ Concluído. ExitCode=$($p.ExitCode)"
    } catch {
        Write-Error  "      ✖ Falha -> $($_.Exception.Message)"
    }
}

# ────────────────────────────────────────────────────────────────
# [Passo 5] - Instalação do Office 2021
# ────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[5] Iniciando instalação do Office 2021"
    if (-not (Connect-InstallShare)) { return }

    # 1. Setup.exe sem argumentos (comportamento igual ao clique manual)
    Run-Installer 'Office/Setup.exe'

    # 2. OfficeSetup.exe silencioso
    Run-Installer 'Office/OfficeSetup.exe' '/quiet /norestart'

    Write-Host "[5] Instalação do Office concluída."
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
