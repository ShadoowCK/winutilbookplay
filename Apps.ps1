# Apps.ps1 – instaladores com etapas numeradas para debug organizado
# -----------------------------------------------------------------------------
# [Etapa 1] - Configurações globais de mapeamento e caminhos
$global:InstallShareUser  = 'mundial\_install'      # domínio\usuário correto com underscore
$global:InstallSharePass  = 'sup@2023#'             # senha desse usuário
$global:InstallShareRoot  = "\\192.168.4.100\util"  # raiz do compartilhamento
$global:InstallShareDrive = 'U'
$global:ShareRoot = "$($global:InstallShareDrive):\01 - Programas\WinUtil\Instaladores"

# [Etapa 2] - Função para mapear unidade de rede
function Connect-InstallShare {
    if (-not (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue)) {
        try {
            Write-Host "[2.1] Removendo mapeamento anterior, se existir..."
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
        }
        catch {
            Write-Host "[2.4] [ERRO] Falha ao mapear: $_" -ForegroundColor Red
            return $false
        }
    }
    Write-Host "[2.5] Unidade já mapeada."
    return $true
}

# [Etapa 3] - Função para desmontar unidade de rede
function Disconnect-InstallShare {
    if (Get-PSDrive -Name $global:InstallShareDrive -ErrorAction SilentlyContinue) {
        Write-Host "[3.1] Desmontando unidade..."
        Remove-PSDrive -Name $global:InstallShareDrive -Force
        cmd.exe /c "net use $($global:InstallShareDrive): /delete /yes" | Out-Null
    }
}

# [Etapa 4] - Função genérica para executar instaladores de forma silenciosa
function Invoke-SilentInstall {
    param([string]$SourceExe,[string]$InstallArgs='/quiet /norestart')
    if (-not (Test-Path $SourceExe)) {
        Write-Host "[4.1] Arquivo não encontrado: $SourceExe" -ForegroundColor Red
        return
    }
    $tmp = Join-Path $env:TEMP ([io.path]::GetFileName($SourceExe))
    Write-Host "[4.2] Copiando $SourceExe para $tmp"
    Copy-Item $SourceExe $tmp -Force
    Unblock-File $tmp
    Write-Host "[4.3] Executando $tmp $InstallArgs"
    Start-Process $tmp -ArgumentList $InstallArgs -Wait
    Remove-Item $tmp -Force -EA SilentlyContinue
}

# [Etapa 5] - Instalação do Office 2021 silenciosa com progresso
function Install-Office2021 {
    Write-Host "[5.1] Iniciando instalação do Office..."
    if (-not (Connect-InstallShare)) { return }

    $exes = @(
        Join-Path $global:ShareRoot 'Office\setup.exe'
        Join-Path $global:ShareRoot 'Office\officesetup.exe'
    )
    $i = 0; $tot = $exes.Count
    foreach ($e in $exes) {
        $i++
        Write-Host "[5.2] Etapa ${i} de ${tot}: $e"
        Write-Progress -Activity 'Instalando Office' -Status "Etapa $i/$tot" -PercentComplete (($i-1)/$tot*100)
        Invoke-SilentInstall $e
    }
    Write-Progress -Activity 'Instalando Office' -Completed
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
