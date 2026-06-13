# flutter run en Chrome con puerto fijo para OAuth local (60889) + proxy CORS IGDB/Twitch.
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $FlutterArgs = @()
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

$LocalDefines = Join-Path $Root "dart_defines.local.json"
$ExampleDefines = Join-Path $Root "dart_defines.example.json"

if (Test-Path $LocalDefines) {
  $DefinesFile = $LocalDefines
} elseif (Test-Path $ExampleDefines) {
  $DefinesFile = $ExampleDefines
  Write-Warning "Usando dart_defines.example.json - crea dart_defines.local.json para secretos."
} else {
  throw "No se encontro ningun JSON de defines."
}

try {
  $definesJson = Get-Content -Raw -Path $DefinesFile | ConvertFrom-Json
  $anilistId = $definesJson.ANILIST_CLIENT_ID
  Write-Host "Defines: $DefinesFile"
  Write-Host "AniList CLIENT_ID en archivo: $(if ($anilistId) { $anilistId } else { '(vacio)' })"
  Write-Host "Detén Flutter por completo antes de relanzar; hot reload no recarga dart-defines." -ForegroundColor Yellow
} catch {
  Write-Warning "No se pudo leer ANILIST_CLIENT_ID de $DefinesFile"
}

$ProxyPort = 8787
$ProxyUrl = "http://127.0.0.1:$ProxyPort"

$restartProxy = Join-Path $Root "scripts/restart_dev_proxy.ps1"
if (-not (Test-Path $restartProxy)) {
  throw "No se encontro $restartProxy"
}

# Reinicia el proxy si está obsoleto (sin /anilist-oauth) y sigue con Flutter.
& $restartProxy
if ($LASTEXITCODE -ne 0) {
  throw "No se pudo iniciar dev_api_proxy"
}

flutter run -d chrome --web-port=60889 --web-hostname=localhost `
  --dart-define-from-file="$DefinesFile" `
  --dart-define=DEV_API_PROXY=$ProxyUrl `
  @FlutterArgs
