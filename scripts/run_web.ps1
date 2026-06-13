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

$ProxyPort = 8787
$ProxyUrl = "http://127.0.0.1:$ProxyPort"

function Test-TcpPortOpen([int] $Port) {
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect("127.0.0.1", $Port)
    $client.Close()
    return $true
  } catch {
    return $false
  }
}

if (-not (Test-TcpPortOpen $ProxyPort)) {
  $proxyScript = Join-Path $Root "scripts/dev_api_proxy.mjs"
  if (-not (Test-Path $proxyScript)) {
    throw "No se encontro $proxyScript"
  }
  Write-Host "Iniciando proxy CORS IGDB/Twitch en $ProxyUrl ..."
  Start-Process -FilePath "node" -ArgumentList @($proxyScript) -WindowStyle Hidden | Out-Null
  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 250
    if (Test-TcpPortOpen $ProxyPort) { break }
  }
  if (-not (Test-TcpPortOpen $ProxyPort)) {
    Write-Warning "El proxy no respondio en $ProxyUrl. Ejecuta: node scripts/dev_api_proxy.mjs"
  }
} else {
  Write-Host "Proxy CORS ya activo en $ProxyUrl"
}

flutter run -d chrome --web-port=60889 --web-hostname=localhost `
  --dart-define-from-file="$DefinesFile" `
  --dart-define=DEV_API_PROXY=$ProxyUrl `
  @FlutterArgs
