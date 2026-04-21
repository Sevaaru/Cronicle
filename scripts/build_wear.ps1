# Builds the Wear OS companion APK.
#
# Usage:
#   .\scripts\build_wear.ps1                # debug
#   .\scripts\build_wear.ps1 -Release       # release (uses android/key.properties)
#
# Output APK is copied to ./build/wear/
[CmdletBinding()]
param(
    [switch]$Release
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

Push-Location (Join-Path $repoRoot "android")
try {
    $variant = if ($Release) { "Release" } else { "Debug" }
    Write-Host ">> Building :wear:assemble$variant" -ForegroundColor Cyan
    & .\gradlew.bat ":wear:assemble$variant"
    if ($LASTEXITCODE -ne 0) { throw "Gradle build failed" }
} finally {
    Pop-Location
}

$srcDir = Join-Path $repoRoot "build/wear/outputs/apk/$($variant.ToLower())"
$dstDir = Join-Path $repoRoot "build/wear"
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
$apk = Get-ChildItem -Path $srcDir -Filter "*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $apk) {
    Copy-Item -Force $apk.FullName (Join-Path $dstDir $apk.Name)
    Write-Host ">> Wear APK: $(Join-Path $dstDir $apk.Name)" -ForegroundColor Green
} else {
    Write-Warning "No APK found under $srcDir"
}
