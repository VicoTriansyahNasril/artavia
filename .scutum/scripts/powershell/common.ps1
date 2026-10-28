#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh

function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

# Resolve the active feature identity, decoupled from the git branch.
# Mirrors get_current_branch() in common.sh. Resolution order:
#   1. SCUTUM_FEATURE / RUDIS_FEATURE env var (explicit override)
#   2. git branch, IF it looks like a feature branch (^NNN-)
#   3. .scutum/.current-feature file  (pointer written by create-new-feature.ps1)
#   4. latest specs/NNN-* directory   (works in git AND non-git repos)
#   5. "main"                         (final fallback)
function Get-CurrentBranch {
    # 1. Explicit override
    if ($env:SCUTUM_FEATURE) {
        return $env:SCUTUM_FEATURE
    }
    if ($env:RUDIS_FEATURE) {
        return $env:RUDIS_FEATURE
    }

    # 2. A real feature branch (opt-in via -CreateBranch) wins
    try {
        $result = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $result -match '^[0-9]{3}-') {
            return $result
        }
    } catch {
        # Git command failed
    }

    $repoRoot = Get-RepoRoot

    # 3. Pointer file written by the last /scutum.specify
    $pointerFile = Join-Path $repoRoot ".scutum/.current-feature"
    if (Test-Path $pointerFile) {
        $pointer = (Get-Content -Path $pointerFile -TotalCount 1 -ErrorAction SilentlyContinue)
        if ($pointer) { $pointer = $pointer.Trim() }
        if ($pointer -match '^[0-9]{3}-') {
            return $pointer
        }
    }

    # 4. Latest specs/NNN-* directory (git or non-git)
    $specsDir = Join-Path $repoRoot "specs"
    if (Test-Path $specsDir) {
        $latestFeature = ""
        $highest = 0

        Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3})-') {
                $num = [int]$matches[1]
                if ($num -gt $highest) {
                    $highest = $num
                    $latestFeature = $_.Name
                }
            }
        }

        if ($latestFeature) {
            return $latestFeature
        }
    }

    # Final fallback
    return "main"
}

function Test-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit = $true
    )
    
    # For non-git repos, we can't enforce branch naming but still provide output
    if (-not $HasGit) {
        Write-Warning "[scutum] Warning: Git repository not detected; skipped branch validation"
        return $true
    }
    
    if ($Branch -notmatch '^[0-9]{3}-') {
        Write-Output "ERROR: No active feature resolved (got: '$Branch')."
        Write-Output "Run /scutum.specify first - it scaffolds specs/NNN-name/ and records the active feature."
        Write-Output "Or target one explicitly: `$env:SCUTUM_FEATURE='NNN-name' before running the command."
        return $false
    }
    return $true
}

function Get-FeatureDir {
    param([string]$RepoRoot, [string]$Branch)
    Join-Path $RepoRoot "specs/$Branch"
}

function Get-FeaturePathsEnv {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $hasGit = Test-HasGit
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $currentBranch
    
    [PSCustomObject]@{
        REPO_ROOT     = $repoRoot
        CURRENT_BRANCH = $currentBranch
        HAS_GIT       = $hasGit
        FEATURE_DIR   = $featureDir
        FEATURE_SPEC  = Join-Path $featureDir 'spec.md'
        IMPL_PLAN     = Join-Path $featureDir 'plan.md'
        TASKS         = Join-Path $featureDir 'tasks.md'
        RESEARCH      = Join-Path $featureDir 'research.md'
        DATA_MODEL    = Join-Path $featureDir 'data-model.md'
        QUICKSTART    = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR = Join-Path $featureDir 'contracts'
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

