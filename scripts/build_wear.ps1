# Builds the Wear OS companion APK or App Bundle.
#
# Usage:
#   .\scripts\build_wear.ps1                          # apk debug
#   .\scripts\build_wear.ps1 -Release                 # apk release
#   .\scripts\build_wear.ps1 -Target appbundle -Release  # aab release
#
# Output artifact is copied to ./build/wear/
[CmdletBinding()]
param(
    [ValidateSet("apk", "appbundle")]
    [string]$Target = "apk",
    [switch]$Release
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

Push-Location (Join-Path $repoRoot "android")
try {
    $variant = if ($Release) { "Release" } else { "Debug" }
    $task = if ($Target -eq "appbundle") { ":wear:bundle$variant" } else { ":wear:assemble$variant" }
    Write-Host ">> Building $task" -ForegroundColor Cyan
    & .\gradlew.bat $task
    if ($LASTEXITCODE -ne 0) { throw "Gradle build failed" }
} finally {
    Pop-Location
}

$dstDir = Join-Path $repoRoot "build/wear"
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null

$artifactDir = if ($Target -eq "appbundle") {
    Join-Path $repoRoot "build/wear/outputs/bundle/$($variant.ToLower())"
} else {
    Join-Path $repoRoot "build/wear/outputs/apk/$($variant.ToLower())"
}

$pattern = if ($Target -eq "appbundle") { "*.aab" } else { "*.apk" }
$artifact = Get-ChildItem -Path $artifactDir -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $artifact) {
    Copy-Item -Force $artifact.FullName (Join-Path $dstDir $artifact.Name)
    Write-Host ">> Wear artifact: $(Join-Path $dstDir $artifact.Name)" -ForegroundColor Green
} else {
    Write-Warning "No artifact found under $artifactDir"
}
