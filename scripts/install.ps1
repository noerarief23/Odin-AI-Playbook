# install.ps1 — copy playbook files from a package into the current working directory.
#
# Usage (run from your target repo root):
#   powershell -ExecutionPolicy Bypass -File C:\path\to\odin-ai-playbook\scripts\install.ps1 -Package all [-Force]
#
# Parameters:
#   -Package <name>   Package profile to install (e.g. all). Required.
#   -Force            Overwrite existing files without prompting.

param(
    [Parameter(Mandatory = $true)]
    [string]$Package,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$PlaybookRoot = Split-Path -Parent $ScriptDir
$PackageDir  = Join-Path $PlaybookRoot "packages\$Package"
$TargetDir   = Get-Location | Select-Object -ExpandProperty Path

if (-not (Test-Path $PackageDir)) {
    Write-Error "Package '$Package' not found at $PackageDir"
    exit 1
}

Write-Host "Installing package '$Package' into $TargetDir ..."

Get-ChildItem -Path $PackageDir -Recurse -File | ForEach-Object {
    $SrcFile  = $_.FullName
    $RelPath  = $SrcFile.Substring($PackageDir.Length).TrimStart('\', '/')
    $DestFile = Join-Path $TargetDir $RelPath
    $DestDir  = Split-Path -Parent $DestFile

    if ((Test-Path $DestFile) -and (-not $Force)) {
        Write-Host "  SKIP (exists, use -Force to overwrite): $RelPath"
        return
    }

    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $SrcFile -Destination $DestFile -Force
    Write-Host "  WRITE: $RelPath"
}

Write-Host "Done."
