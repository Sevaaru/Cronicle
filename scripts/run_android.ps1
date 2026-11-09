# flutter run con los mismos dart-define que el build (dispositivo/emulador).
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
  Write-Warning "Usando dart_defines.example.json — crea dart_defines.local.json para secretos."
} else {
  throw "No se encontró ningún JSON de defines."
}

flutter run --dart-define-from-file="$DefinesFile" @FlutterArgs
