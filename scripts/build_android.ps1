# Build APK (o app bundle) usando defines en JSON.
# 1) Copia dart_defines.example.json -> dart_defines.local.json (en la raíz del repo)
# 2) Rellena valores; dart_defines.local.json está en .gitignore
# 3) Ejecuta: .\scripts\build_android.ps1
#    Opcional: .\scripts\build_android.ps1 -Target appbundle

param(
  [ValidateSet("apk", "appbundle")]
  [string] $Target = "apk",
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
  Write-Host "Usando dart_defines.local.json" -ForegroundColor Green
} elseif (Test-Path $ExampleDefines) {
  $DefinesFile = $ExampleDefines
  Write-Warning "No existe dart_defines.local.json. Usando dart_defines.example.json (revisa que tenga tus claves)."
} else {
  throw "No se encontró dart_defines.example.json en la raíz del proyecto."
}

$defineArg = "--dart-define-from-file=$DefinesFile"

if ($Target -eq "appbundle") {
  flutter build appbundle $defineArg @FlutterArgs
} else {
  flutter build apk $defineArg @FlutterArgs
}
