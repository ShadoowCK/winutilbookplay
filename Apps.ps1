## Apps.ps1 – Instalador universal
# ────────────────────────────────────────────────────────────────
# [1] Configurações globais
# ────────────────────────────────────────────────────────────────
$global:InstallShareUser   = "mundial\_install"
$global:InstallSharePass   = 'sup@2023#'
$global:InstallShareRoot   = '\\192.168.4.100\util\01 - Programas\WinUtil\Instaladores'
$global:InstallShareDrive  = 'K'
$global:MappedRoot         = "$($global:InstallShareDrive):"  # K:

# ────────────────────────────────────────────────────────────────
# [2] Mapear K: (sem salvar credenciais)
# ────────────────────────────────────────────────────────────────
function Connect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Write-Host "[2.1] Unidade K: já mapeada."; return $true }

    Write-Host "[2.2] Mapeando K: → $global:InstallShareRoot …"
    $cmd = "net use $global:InstallShareDrive`: `"$global:InstallShareRoot`" /user:$global:InstallShareUser $global:InstallSharePass /persistent:no"
    cmd.exe /c $cmd | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "[2.3] Mapeamento OK."; return $true }
    Write-Host "[2.3] Falha ao mapear." -ForegroundColor Red; return $false
}

# ────────────────────────────────────────────────────────────────
# [3] Desmontar K:
# ────────────────────────────────────────────────────────────────
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Write-Host "[3.1] Desmontando K: …"; cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null }
}

# ────────────────────────────────────────────────────────────────
# [4] Resolver instalador: caminho padrão OU busca recursiva
# ────────────────────────────────────────────────────────────────
function Resolve-Installer {
    param(
        [string]$DefaultRelative,  # ex: 'Office\Setup.exe'
        [string]$SearchPattern     # ex: 'Setup.exe'
    )

    # 4.1 Caminho padrão (mais rápido)
    $defaultPath = Join-Path $global:MappedRoot $DefaultRelative
    if (Test-Path $defaultPath) {
        Write-Host "[4.1] Encontrado (padrão): $defaultPath"; return $defaultPath }

    # 4.2 Busca recursiva
    Write-Host "[4.2] Padrão não encontrado. Buscando *$SearchPattern* em K: …"
    $found = Get-ChildItem -Path $global:MappedRoot -Filter $SearchPattern -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Write-Host "[4.3] Encontrado (busca): $($found.FullName)"; return $found.FullName }

    Write-Host "[4.4] NÃO encontrado: $SearchPattern" -ForegroundColor Red; return $null
}

# ────────────────────────────────────────────────────────────────
# [5] Executar instalador
# ────────────────────────────────────────────────────────────────
function Start-Installer {
    param(
        [string]$DefaultRel,
        [string]$ExeName,
        [string]$InstallerArgs = $null
    )

    $path = Resolve-Installer $DefaultRel $ExeName
    if (-not $path) { return }

    Write-Host "[5] Executando: $path $InstallerArgs"
    try {
        $p = if ($InstallerArgs) {
            Start-Process -FilePath $path -ArgumentList $InstallerArgs -Wait -PassThru -ErrorAction Stop
        } else {
            Start-Process -FilePath $path -Wait -PassThru -ErrorAction Stop
        }
        Write-Host "      ✔ ExitCode=$($p.ExitCode)"
    } catch {
        Write-Error  "      ✖ Erro: $($_.Exception.Message)"
    }
}

# ────────────────────────────────────────────────────────────────
# [6] Instalar Office 2021
# ────────────────────────────────────────────────────────────────
function Install-Office2021 {
    Write-Host "[6.1] Iniciando instalação do Office…"
    if (-not (Connect-InstallShare)) { return }

    # 1) Setup.exe (GUI)
    Start-Installer 'Office\Setup.exe' 'Setup.exe'

    # 2) OfficeSetup.exe (silencioso)
    Start-Installer 'Office\OfficeSetup.exe' 'OfficeSetup.exe' '/quiet /norestart'

    Disconnect-InstallShare
    Write-Host "[6.2] Processo concluído."
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
