
<#
  Tweaks.ps1  –  Engine genérico de tweaks
  © 2025 ShadoowCK (adaptado de Chris Titus Tech)

  ▸ Usa o Tweaks.json local.  
  ▸ Se não existir (ou se você chamar -Update) baixa automaticamente a versão
    mais recente do repositório ChrisTitusTech/winutil.  
  ▸ Permite aplicar ou desfazer tweaks individualmente ou por seleção gráfica
    (Out‑GridView).

  Exemplos:
    .\Tweaks.ps1 -Update                    # atualiza lista de tweaks
    .\Tweaks.ps1                            # abre lista gráfica
    .\Tweaks.ps1 DisableTelemetry Debloat   # aplica 2 tweaks
    .\Tweaks.ps1 DisableTelemetry -Undo     # desfaz tweak
#>

[CmdletBinding()]
param(
    [string[]]$Keys,     # IDs dos tweaks – veja Tweaks.json
    [switch]$Undo,       # Desfazer tweaks
    [switch]$Update      # Forçar download do JSON mais recente
)

$ErrorActionPreference = 'Stop'

# Caminho do JSON (mesmo diretório do script)
$ConfigPath = Join-Path $PSScriptRoot 'Tweaks.json'
$RemoteJson = 'https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/tweaks.json'

function Update-TweaksJson {
    Write-Host "[*] Baixando Tweaks.json completo do WinUtil..."
    try {
        Invoke-WebRequest -Uri $RemoteJson -OutFile $ConfigPath -UseBasicParsing
        Write-Host "[+] Tweaks.json atualizado com sucesso.`n"
    }
    catch {
        throw "Falha ao baixar Tweaks.json: $_"
    }
}

if ($Update -or -not (Test-Path $ConfigPath)) { Update-TweaksJson }

# Carrega o JSON com profundidade ampla
try   { $Tweaks = Get-Content $ConfigPath -Raw | ConvertFrom-Json -Depth 20 }
catch { throw "Falha ao carregar ou converter Tweaks.json (`$_`)" }

#############################
# Funções auxiliares        #
#############################
function Invoke-RegistryEntry ($arr, $revert) {
    foreach ($e in $arr) {
        $val = if ($revert) { $e.OriginalValue } else { $e.Value }
        if (-not (Test-Path $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
        try {
            New-ItemProperty -Path $e.Path -Name $e.Name -Value $val -PropertyType $e.Type -Force | Out-Null
        } catch {
            Write-Warning "Falha no registro $($e.Path)\$($e.Name): $_"
        }
    }
}

function Invoke-ServiceEntry ($arr, $revert) {
    foreach ($e in $arr) {
        $type = if ($revert) { $e.OriginalType } else { $e.StartupType }
        try { Set-Service -Name $e.Name -StartupType $type -ErrorAction Stop }
        catch { Write-Warning "Serviço $($e.Name): $_" }
    }
}

function Invoke-ScriptBlock ($lines) {
    if ($lines) {
        & ([scriptblock]::Create(($lines -join "`n")))
    }
}

function Run-Tweak ($key, $revert) {
    $t = $Tweaks.$key
    if (-not $t) { Write-Warning "Tweak '$key' não encontrado."; return }
    Write-Host "`n==== $($t.Content)  ($(if($revert){'UNDO'}else{'APLICAR'})) ===="
    if ($t.registry) { Invoke-RegistryEntry $t.registry $revert }
    if ($t.service)  { Invoke-ServiceEntry  $t.service  $revert }
    if (-not $revert) { Invoke-ScriptBlock $t.InvokeScript } else { Invoke-ScriptBlock $t.UndoScript }
}

#############################
# Execução principal        #
#############################
if (-not $Keys) {
    # Seleção gráfica se Out‑GridView estiver disponível
    $Keys = $Tweaks.PSObject.Properties |
            Select-Object -Expand Name |
            Out-GridView -Title "Selecione os Tweaks para $(if($Undo){'DESFAZER'}else{'APLICAR'})" -PassThru
}

foreach ($k in $Keys) { Run-Tweak $k $Undo.IsPresent }
