<#
.SYNOPSIS
    Installs Practical Agent Skills locally into a project or globally on your machine.

.DESCRIPTION
    Every destination keeps a manifest (.practical-agent-skills.manifest) with a content hash per installed skill.
    - Locally modified skills (hash differs from the last install) are SKIPPED with a warning unless -Force is given.
    - Stale skills (installed earlier but renamed/removed from this repo) are reported; -Prune deletes them.
    - Custom project skills that were never installed by this script are never touched.

.EXAMPLE
    # Install all skills globally (Antigravity ~/.gemini/config/skills & ~/.agents/skills)
    .\install.ps1 -Global

.EXAMPLE
    # Install all skills into a specific project
    .\install.ps1 -Target "D:\practik\HelplessPoeTools"

.EXAMPLE
    # Install only specific skill(s) into a project
    .\install.ps1 -Target "D:\practik\HelplessPoeTools" -Skill interview,proposal,decompose

.EXAMPLE
    # Install all skills globally for Claude Code (~/.claude/skills)
    .\install.ps1 -Global -Claude

.EXAMPLE
    # Install skills locally into a repository for Claude Code (<project>/.claude/skills)
    .\install.ps1 -Target "D:\practik\HelplessPoeTools" -Claude

.EXAMPLE
    # Link .agents/skills -> skills/ via Directory Junction inside this repository
    .\install.ps1 -SyncRepo

.EXAMPLE
    # Update EVERYWHERE: repo junction + global directories + all sibling projects with .agents/skills
    .\install.ps1 -All

.EXAMPLE
    # Update everywhere, overwrite local edits and delete skills that no longer exist in this repo
    .\install.ps1 -All -Force -Prune
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$Target = "",

    [Parameter(Mandatory = $false)]
    [switch]$Global,

    [Parameter(Mandatory = $false)]
    [string[]]$Skill = @(),

    [Parameter(Mandatory = $false)]
    [switch]$SyncRepo,

    [Parameter(Mandatory = $false)]
    [switch]$All,

    [Parameter(Mandatory = $false)]
    [switch]$Claude,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Prune
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CanonicalSkillsDir = Join-Path $RepoRoot "skills"
$WorkspaceSkillsDir = Join-Path $RepoRoot ".agents\skills"
$ManifestName = ".practical-agent-skills.manifest"

function Sync-RepoJunction {
    Write-Host "Linking .agents/skills -> skills/ via Directory Junction..." -ForegroundColor Cyan
    $AgentsDir = Join-Path $RepoRoot ".agents"
    if (-not (Test-Path $AgentsDir)) {
        New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
    }
    if (Test-Path $WorkspaceSkillsDir) {
        $Existing = Get-Item -LiteralPath $WorkspaceSkillsDir -Force
        if ($Existing.LinkType) {
            # Delete only the link itself. Remove-Item -Recurse on a junction in PS 5.1 can wipe the target (skills/).
            $Existing.Delete()
        } else {
            Remove-Item -LiteralPath $WorkspaceSkillsDir -Recurse -Force
        }
    }
    New-Item -ItemType Junction -Path $WorkspaceSkillsDir -Target $CanonicalSkillsDir | Out-Null
    Write-Host "  [+] .agents/skills -> skills/ (Junction ready)" -ForegroundColor Green

    $GithooksDir = Join-Path $RepoRoot ".githooks"
    if (Test-Path $GithooksDir) {
        git config core.hooksPath .githooks
        Write-Host "  [+] Git hooks configured: core.hooksPath -> .githooks" -ForegroundColor Green
    }
}

if ($SyncRepo) {
    Sync-RepoJunction
    exit 0
}

$SourceDir = if (Test-Path $CanonicalSkillsDir) { $CanonicalSkillsDir } else { $WorkspaceSkillsDir }

function Get-SkillHash {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return $null }
    $Base = (Resolve-Path -LiteralPath $Dir).Path
    # evals/ holds skill tests; it is never installed, so it never counts toward the hash.
    $Files = @(Get-ChildItem -LiteralPath $Base -Recurse -File | Where-Object { -not $_.FullName.Substring($Base.Length + 1).Replace('\', '/').StartsWith('evals/') })
    if ($Files.Count -eq 0) { return $null }
    $Lines = foreach ($File in $Files) {
        $Rel = $File.FullName.Substring($Base.Length + 1).Replace('\', '/')
        # Normalize line endings so CRLF/LF checkouts hash identically (must match install.sh).
        $Text = [System.IO.File]::ReadAllText($File.FullName) -replace "`r", ""
        $Sha = [System.Security.Cryptography.SHA256]::Create()
        $Hash = [BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').ToLower()
        "$Rel=$Hash"
    }
    $Lines = [string[]]$Lines
    [Array]::Sort($Lines, [StringComparer]::Ordinal)
    $Sha2 = [System.Security.Cryptography.SHA256]::Create()
    return [BitConverter]::ToString($Sha2.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(($Lines -join "`n")))).Replace('-', '').ToLower()
}

# Manifest format (shared with install.sh): one "<skill-name> <hash>" pair per line.
function Read-Manifest {
    param([string]$Path)
    $Map = @{}
    if (Test-Path $Path) {
        foreach ($Line in Get-Content -LiteralPath $Path) {
            $Parts = $Line.Trim() -split '\s+'
            if ($Parts.Count -eq 2 -and -not $Parts[0].StartsWith('#')) { $Map[$Parts[0]] = $Parts[1] }
        }
    }
    return $Map
}

function Write-Manifest {
    param([string]$Path, [hashtable]$Map)
    $Out = @("# Managed by Practical Agent Skills installer. Do not edit.")
    foreach ($Key in ($Map.Keys | Sort-Object)) { $Out += "$Key $($Map[$Key])" }
    [System.IO.File]::WriteAllText($Path, (($Out -join "`n") + "`n"))
}

function Install-SkillsToDirectory {
    param(
        [string]$DestinationSkillsDir,
        [string[]]$SelectedSkills
    )
    if (-not (Test-Path $DestinationSkillsDir)) {
        New-Item -ItemType Directory -Path $DestinationSkillsDir -Force | Out-Null
    }
    $ManifestPath = Join-Path $DestinationSkillsDir $ManifestName
    $Manifest = Read-Manifest -Path $ManifestPath

    $AllSourceFolders = Get-ChildItem -Path $SourceDir -Directory
    $SkillFolders = $AllSourceFolders
    if ($SelectedSkills.Count -gt 0) {
        $SkillFolders = $SkillFolders | Where-Object { $SelectedSkills -contains $_.Name }
    }

    foreach ($Folder in $SkillFolders) {
        $DestFolder = Join-Path $DestinationSkillsDir $Folder.Name
        $SourceHash = Get-SkillHash -Dir $Folder.FullName
        $DestHash = Get-SkillHash -Dir $DestFolder
        $RecordedHash = $Manifest[$Folder.Name]

        if ($DestHash -and $DestHash -eq $SourceHash) {
            $Manifest[$Folder.Name] = $SourceHash
            Write-Host "  [=] /$($Folder.Name) already up to date" -ForegroundColor DarkGray
            continue
        }
        if ($DestHash -and $RecordedHash -and $DestHash -ne $RecordedHash -and -not $Force) {
            Write-Host "  [!] SKIPPED /$($Folder.Name): locally modified in $DestFolder (use -Force to overwrite)" -ForegroundColor Yellow
            continue
        }

        if (Test-Path $DestFolder) {
            Remove-Item -LiteralPath $DestFolder -Recurse -Force
        }
        New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
        Get-ChildItem -LiteralPath $Folder.FullName | Where-Object { $_.Name -ne 'evals' } | Copy-Item -Destination $DestFolder -Recurse -Force
        $Manifest[$Folder.Name] = $SourceHash
        Write-Host "  [+] Installed /$($Folder.Name) -> $DestFolder" -ForegroundColor Green
    }

    # Stale skills: installed earlier by this script but no longer present in the repo.
    $SourceNames = $AllSourceFolders | ForEach-Object { $_.Name }
    foreach ($Name in @($Manifest.Keys)) {
        if ($SourceNames -notcontains $Name) {
            $StaleDir = Join-Path $DestinationSkillsDir $Name
            if ($Prune) {
                if (Test-Path $StaleDir) { Remove-Item -LiteralPath $StaleDir -Recurse -Force }
                $Manifest.Remove($Name)
                Write-Host "  [-] Pruned stale skill /$Name" -ForegroundColor Magenta
            } else {
                Write-Host "  [!] Stale skill /$Name no longer exists in this repo (use -Prune to delete)" -ForegroundColor Yellow
            }
        }
    }

    Write-Manifest -Path $ManifestPath -Map $Manifest
}

function Install-GlobalSkills {
    if ($Claude) {
        Write-Host "Installing Practical Agent Skills GLOBALLY for Claude Code..." -ForegroundColor Cyan
        Install-SkillsToDirectory -DestinationSkillsDir (Join-Path $HOME ".claude\skills") -SelectedSkills $Skill
        return
    }
    $AgyGlobalSkills = Join-Path $HOME ".gemini\config\skills"
    $UniversalGlobalSkills = Join-Path $HOME ".agents\skills"

    Write-Host "Installing Practical Agent Skills GLOBALLY..." -ForegroundColor Cyan
    Install-SkillsToDirectory -DestinationSkillsDir $AgyGlobalSkills -SelectedSkills $Skill
    Install-SkillsToDirectory -DestinationSkillsDir $UniversalGlobalSkills -SelectedSkills $Skill
}

if ($All) {
    Sync-RepoJunction
    Install-GlobalSkills

    # Claude Code: update the global dir only if it already exists (-Claude forces it, handled above).
    $ClaudeGlobalSkills = Join-Path $HOME ".claude\skills"
    if (-not $Claude -and (Test-Path $ClaudeGlobalSkills)) {
        Write-Host "`nUpdating Claude Code global skills..." -ForegroundColor Cyan
        Install-SkillsToDirectory -DestinationSkillsDir $ClaudeGlobalSkills -SelectedSkills $Skill
    }

    $ParentDir = Split-Path -Parent $RepoRoot
    if ($ParentDir -and (Test-Path $ParentDir)) {
        $SiblingProjects = Get-ChildItem -Path $ParentDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -ne $RepoRoot }
        foreach ($Proj in $SiblingProjects) {
            foreach ($Rel in @(".agents\skills", ".claude\skills")) {
                $ProjSkillsDir = Join-Path $Proj.FullName $Rel
                if (-not (Test-Path $ProjSkillsDir)) { continue }
                Write-Host "`nUpdating project: $ProjSkillsDir..." -ForegroundColor Cyan
                Install-SkillsToDirectory -DestinationSkillsDir $ProjSkillsDir -SelectedSkills $Skill
            }
        }
    }
    Write-Host "`nAll global and project skills updated!" -ForegroundColor Green
    exit 0
}

if ($Global) {
    Install-GlobalSkills
    Write-Host "`nGlobal installation complete!" -ForegroundColor Green
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Update everywhere: .\install.ps1 -All [-Force] [-Prune]"
    Write-Host "  Global install:    .\install.ps1 -Global [-Force] [-Prune]"
    Write-Host "  Project install:   .\install.ps1 -Target `"C:\path\to\project`""
    Write-Host "  Claude Code:       .\install.ps1 -Global -Claude  |  .\install.ps1 -Target `"C:\path\to\project`" -Claude"
    Write-Host "  Single skill:      .\install.ps1 -Target `"C:\path\to\project`" -Skill interview,proposal"
    Write-Host "  Sync repo:         .\install.ps1 -SyncRepo"
    exit 1
}

$ResolvedTarget = Resolve-Path $Target -ErrorAction SilentlyContinue
if (-not $ResolvedTarget) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    $ResolvedTarget = Resolve-Path $Target
}
$TargetRoot = $ResolvedTarget.Path
$TargetSkillsDir = Join-Path $TargetRoot $(if ($Claude) { ".claude\skills" } else { ".agents\skills" })

Write-Host "Installing Practical Agent Skills into project: $TargetRoot" -ForegroundColor Cyan
Install-SkillsToDirectory -DestinationSkillsDir $TargetSkillsDir -SelectedSkills $Skill

# Ensure .temp/ is in target project's .gitignore
$GitIgnorePath = Join-Path $TargetRoot ".gitignore"
if (Test-Path $GitIgnorePath) {
    $GitIgnoreContent = Get-Content $GitIgnorePath -Raw
    if ($GitIgnoreContent -notmatch "(?m)^\s*/?\.temp/?\s*$") {
        Add-Content -Path $GitIgnorePath -Value "`n.temp/"
        Write-Host "  [+] Added .temp/ to $GitIgnorePath" -ForegroundColor DarkCyan
    }
} else {
    Set-Content -Path $GitIgnorePath -Value ".temp/`n"
    Write-Host "  [+] Created $GitIgnorePath with .temp/" -ForegroundColor DarkCyan
}

Write-Host "`nProject installation complete!" -ForegroundColor Green
