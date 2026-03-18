# install.ps1 — copy playbook files from a package into the current working directory.
#
# Usage (run from your target repo root):
#   powershell -ExecutionPolicy Bypass -File C:\path\to\odin-ai-playbook\scripts\install.ps1 -Package all [-Force]
#
# Parameters:
#   -Package <name>   Package profile to install (e.g. all). Required.
#   -Force            Overwrite existing files without prompting.
#
# Skills (from .ai/skills/) are always installed regardless of the chosen package.
# They are sourced from the top-level .ai/skills/ folder in the playbook repo,
# which is the single source of truth — no copy is kept inside packages/.

param(
    [Parameter(Mandatory = $true)]
    [string]$Package,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$PlaybookRoot = Split-Path -Parent $ScriptDir
$PackageDir   = Join-Path $PlaybookRoot "packages\$Package"
$TargetDir    = Get-Location | Select-Object -ExpandProperty Path

if (-not (Test-Path $PackageDir)) {
    Write-Error "Package '$Package' not found at $PackageDir"
    exit 1
}

# ---------------------------------------------------------------------------
# Helper: copy all files from $SrcRoot into $TargetDir, preserving structure.
# ---------------------------------------------------------------------------
function Copy-PlaybookDir {
    param(
        [string]$SrcRoot,
        [string]$Label
    )
    Write-Host $Label
    Get-ChildItem -Path $SrcRoot -Recurse -File | ForEach-Object {
        $SrcFile  = $_.FullName
        $RelPath  = $SrcFile.Substring($SrcRoot.Length).TrimStart('\', '/')
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
}

# ---------------------------------------------------------------------------
# 1. Copy package-specific files (.github/, .kiro/, etc.)
# ---------------------------------------------------------------------------
Copy-PlaybookDir -SrcRoot $PackageDir -Label "Installing package '$Package' into $TargetDir ..."

# ---------------------------------------------------------------------------
# 2. Copy skills from the single source of truth: <playbook-root>\.ai\skills\
#    Strip relative to PlaybookRoot so that skills land at .ai\skills\ in the
#    target, not at the root.  This avoids a redundant copy inside packages\.
# ---------------------------------------------------------------------------
$SkillsDir = Join-Path $PlaybookRoot ".ai\skills"
if (Test-Path $SkillsDir) {
    Write-Host "Installing skills from .ai\skills\ ..."
    Get-ChildItem -Path $SkillsDir -Recurse -File | ForEach-Object {
        $SrcFile  = $_.FullName
        # Keep the .ai\skills\... prefix by stripping from PlaybookRoot
        $RelPath  = $SrcFile.Substring($PlaybookRoot.Length).TrimStart('\', '/')
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
}

Write-Host "Done."
