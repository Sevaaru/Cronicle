# Asegura que dev_api_proxy esté activo y con ruta /anilist-oauth.
param(
  [switch] $Foreground
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$ProxyPort = 8787
$ProxyScript = Join-Path $Root "scripts/dev_api_proxy.mjs"
$BaseUrl = "http://127.0.0.1:$ProxyPort"

function Stop-ListenerOnPort([int] $Port) {
  $pids = [System.Collections.Generic.HashSet[int]]::new()
  try {
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
      ForEach-Object { [void]$pids.Add($_.OwningProcess) }
  } catch {
    netstat -ano | Select-String ":\s*$Port\s" | ForEach-Object {
      if ($_ -match '\s(\d+)\s*$') { [void]$pids.Add([int]$Matches[1]) }
    }
  }
  foreach ($procId in $pids) {
    if ($procId -gt 0 -and $procId -ne $PID) {
      Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
  }
}

function Test-DevApiProxyHealthy([string] $Url) {
  try {
    $r = Invoke-WebRequest -Uri "$Url/__health" -UseBasicParsing -TimeoutSec 2
    if ($r.StatusCode -ne 200) { return $false }
    $json = $r.Content | ConvertFrom-Json
    return ($json.ok -eq $true) -and ($json.routes -contains '/anilist-oauth')
  } catch {
    return $false
  }
}

if (-not (Test-Path $ProxyScript)) {
  throw "No se encontro $ProxyScript"
}

if (Test-DevApiProxyHealthy $BaseUrl) {
  Write-Host "dev_api_proxy ya activo en $BaseUrl"
  if ($Foreground) {
    # Mantener la tarea de VS Code viva sin duplicar el listener.
    while ($true) { Start-Sleep -Seconds 3600 }
  }
  exit 0
}

Stop-ListenerOnPort $ProxyPort
Start-Sleep -Milliseconds 400

if ($Foreground) {
  Write-Host "Iniciando dev_api_proxy en $BaseUrl (foreground) ..."
  & node $ProxyScript
  exit $LASTEXITCODE
}

Write-Host "Iniciando dev_api_proxy en $BaseUrl ..."
Start-Process -FilePath "node" -ArgumentList @($ProxyScript) -WindowStyle Hidden | Out-Null

for ($i = 0; $i -lt 24; $i++) {
  Start-Sleep -Milliseconds 250
  if (Test-DevApiProxyHealthy $BaseUrl) {
    Write-Host "Proxy listo (incluye /anilist-oauth para OAuth AniList)." -ForegroundColor Green
    exit 0
  }
}

Write-Warning "El proxy no respondio al health check. Ejecuta: node scripts/dev_api_proxy.mjs"
exit 1
