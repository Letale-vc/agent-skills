<#
.SYNOPSIS
    Installs Practical Agent Skills for Codex, Antigravity and other agents that read .agents/skills.

.DESCRIPTION
    Claude Code uses the pas plugin instead (claude plugin marketplace add Letale-vc/agent-skills;
    claude plugin install pas@letale-skills); -Claude prints those commands and copies nothing.

    Skills link to shared rules and agent definitions as ${CLAUDE_PLUGIN_ROOT}/shared/... and
    ${CLAUDE_PLUGIN_ROOT}/agents/.... The installer copies shared/ and agents/ next to the skills
    folder (<skills-dir>/../pas/) and rewrites the placeholder in every copied file:
    - project install: .agents/pas (relative to the project root, so the folder can be committed);
    - global install: the absolute path of <skills-dir>/../pas.

    Every skills folder keeps a manifest (.practical-agent-skills.manifest) with a content hash per skill.
    - Locally modified skills (hash differs from the last install) are SKIPPED with a warning unless -Force is given.
    - Stale skills (installed earlier, now renamed or removed from this repo) are reported; -Prune deletes them.
    - Custom project skills that were never installed by this script are never touched.
    - shared/ and agents/ under pas/ belong to the installer and are always replaced.

.EXAMPLE
    # Install all skills globally (~/.gemini/config/skills and ~/.agents/skills)
    .\install.ps1 -Global

.EXAMPLE
    # Install all skills into a project (<project>/.agents/skills and <project>/.agents/pas)
    .\install.ps1 -Target "D:\path\to\project"

.EXAMPLE
    # Install only some skills into a project
    .\install.ps1 -Target "D:\path\to\project" -Skill flow,implement,review

.EXAMPLE
    # Claude Code: print the plugin commands; with -Prune also remove skills an older installer copied into .claude/skills
    .\install.ps1 -Target "D:\path\to\project" -Claude -Prune

.EXAMPLE
    # Link .agents/skills -> skills/ via Directory Junction inside this repository
    .\install.ps1 -SyncRepo

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
$Placeholder = '${CLAUDE_PLUGIN_ROOT}'
$SupportDirs = @("shared", "agents")
$SupportFolderName = "pas"
# Skills removed in 2.0 (merged into flow, shape, audit and git). Without a manifest entry they are only reported.
$RetiredSkills = @("using-agent-skills", "idea", "interview", "architect", "cleanup")
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

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

# Relative names are built from item names, not by cutting a path prefix: Resolve-Path keeps an 8.3 short
# path (C:\Users\ABCDEF~1) while Get-ChildItem returns the long one, which shifted the cut.
function Get-RelativeFiles {
    param([string]$Dir)
    $List = New-Object System.Collections.Generic.List[object]
    $Pending = New-Object System.Collections.Generic.Queue[object]
    $Pending.Enqueue(@((Get-Item -LiteralPath $Dir), ""))
    while ($Pending.Count -gt 0) {
        $Item, $Prefix = $Pending.Dequeue()
        foreach ($Child in Get-ChildItem -LiteralPath $Item.FullName) {
            $Rel = $Prefix + $Child.Name
            if ($Child.PSIsContainer) {
                # evals/ holds skill tests; it is never installed and never counts toward the hash.
                if ($Rel -ne "evals") { $Pending.Enqueue(@($Child, "$Rel/")) }
            } else {
                $List.Add([pscustomobject]@{ Full = $Child.FullName; Rel = $Rel })
            }
        }
    }
    return , $List.ToArray()
}

function Convert-PluginRoot {
    param([string]$Text, [string]$PluginRoot)
    if ([string]::IsNullOrEmpty($PluginRoot)) { return $Text }
    return $Text.Replace($Placeholder, $PluginRoot)
}

# Hash of a skill as installed: CR stripped (must match install.sh), placeholder rewritten to $PluginRoot.
# An installed copy has no placeholder left, so the same call hashes source and destination alike.
function Get-SkillHash {
    param([string]$Dir, [string]$PluginRoot = "")
    if (-not (Test-Path $Dir)) { return $null }
    $Files = Get-RelativeFiles -Dir $Dir
    if ($Files.Count -eq 0) { return $null }
    $Lines = foreach ($File in $Files) {
        $Text = Convert-PluginRoot -Text ([System.IO.File]::ReadAllText($File.Full) -replace "`r", "") -PluginRoot $PluginRoot
        $Sha = [System.Security.Cryptography.SHA256]::Create()
        $Hash = [BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').ToLower()
        "$($File.Rel)=$Hash"
    }
    $Lines = [string[]]$Lines
    [Array]::Sort($Lines, [StringComparer]::Ordinal)
    $Sha2 = [System.Security.Cryptography.SHA256]::Create()
    return [BitConverter]::ToString($Sha2.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(($Lines -join "`n")))).Replace('-', '').ToLower()
}

# Copies a folder (without evals/) and rewrites the placeholder in every file that contains it.
function Copy-WithPluginRoot {
    param([string]$Source, [string]$Destination, [string]$PluginRoot)
    if (Test-Path $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    foreach ($File in (Get-RelativeFiles -Dir $Source)) {
        $Dest = Join-Path $Destination $File.Rel
        $DestParent = Split-Path -Parent $Dest
        if (-not (Test-Path $DestParent)) { New-Item -ItemType Directory -Path $DestParent -Force | Out-Null }
        $Text = [System.IO.File]::ReadAllText($File.Full)
        if ($Text.Contains($Placeholder)) {
            [System.IO.File]::WriteAllText($Dest, (Convert-PluginRoot -Text $Text -PluginRoot $PluginRoot), $Utf8NoBom)
        } else {
            Copy-Item -LiteralPath $File.Full -Destination $Dest -Force
        }
    }
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

# Project installs use a path relative to the project root; global installs an absolute path.
function Install-SkillsToDirectory {
    param(
        [string]$DestinationSkillsDir,
        [string[]]$SelectedSkills,
        [string]$PluginRoot
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
        $SourceHash = Get-SkillHash -Dir $Folder.FullName -PluginRoot $PluginRoot
        $DestHash = Get-SkillHash -Dir $DestFolder -PluginRoot $PluginRoot
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

        Copy-WithPluginRoot -Source $Folder.FullName -Destination $DestFolder -PluginRoot $PluginRoot
        $Manifest[$Folder.Name] = $SourceHash
        Write-Host "  [+] Installed /$($Folder.Name) -> $DestFolder" -ForegroundColor Green
    }

    # Shared rules and agent definitions the skills link to.
    $SupportRoot = Join-Path (Split-Path -Parent $DestinationSkillsDir) $SupportFolderName
    foreach ($Name in $SupportDirs) {
        Copy-WithPluginRoot -Source (Join-Path $RepoRoot $Name) -Destination (Join-Path $SupportRoot $Name) -PluginRoot $PluginRoot
    }
    Write-Host "  [+] Installed $($SupportDirs -join '/, ')/ -> $SupportRoot (links rewritten to $PluginRoot)" -ForegroundColor Green

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
    foreach ($Name in $RetiredSkills) {
        if (-not $Manifest.ContainsKey($Name) -and (Test-Path (Join-Path $DestinationSkillsDir $Name))) {
            Write-Host "  [!] /$Name was retired in 2.0 but was not installed by this script; delete it by hand if it is an old copy" -ForegroundColor Yellow
        }
    }

    Write-Manifest -Path $ManifestPath -Map $Manifest
}

function Show-ClaudePluginHint {
    Write-Host "Claude Code uses the pas plugin; nothing is copied into .claude/skills. Run once:" -ForegroundColor Cyan
    Write-Host "  claude plugin marketplace add Letale-vc/agent-skills    # or a local clone: claude plugin marketplace add `"$RepoRoot`""
    Write-Host "  claude plugin install pas@letale-skills                 # add --scope project to enable it in .claude/settings.json"
}

# Skills an older installer copied into a Claude Code skills folder: the plugin replaces them.
function Remove-OldClaudeCopies {
    param([string]$ClaudeSkillsDir)
    $ManifestPath = Join-Path $ClaudeSkillsDir $ManifestName
    if (-not (Test-Path $ManifestPath)) { return }
    $Manifest = Read-Manifest -Path $ManifestPath
    if ($Manifest.Count -eq 0) { return }
    if (-not $Prune) {
        Write-Host "  [!] $ClaudeSkillsDir holds $($Manifest.Count) skills copied by an older installer; the plugin replaces them (use -Prune to delete)" -ForegroundColor Yellow
        return
    }
    foreach ($Name in @($Manifest.Keys)) {
        $Dir = Join-Path $ClaudeSkillsDir $Name
        $Hash = Get-SkillHash -Dir $Dir
        if ($Hash -and $Hash -ne $Manifest[$Name] -and -not $Force) {
            Write-Host "  [!] SKIPPED /$($Name): locally modified in $Dir (use -Force to delete)" -ForegroundColor Yellow
            continue
        }
        if (Test-Path $Dir) { Remove-Item -LiteralPath $Dir -Recurse -Force }
        $Manifest.Remove($Name)
        Write-Host "  [-] Removed old copy /$Name from $ClaudeSkillsDir" -ForegroundColor Magenta
    }
    if ($Manifest.Count -eq 0) { Remove-Item -LiteralPath $ManifestPath -Force } else { Write-Manifest -Path $ManifestPath -Map $Manifest }
}

function Get-AbsolutePluginRoot {
    param([string]$SkillsDir)
    return (Join-Path (Split-Path -Parent $SkillsDir) $SupportFolderName).Replace('\', '/')
}

function Install-GlobalSkills {
    Write-Host "Installing Practical Agent Skills GLOBALLY..." -ForegroundColor Cyan
    foreach ($Dir in @((Join-Path $HOME ".gemini\config\skills"), (Join-Path $HOME ".agents\skills"))) {
        Install-SkillsToDirectory -DestinationSkillsDir $Dir -SelectedSkills $Skill -PluginRoot (Get-AbsolutePluginRoot -SkillsDir $Dir)
    }
}

$ProjectPluginRoot = ".agents/$SupportFolderName"

if ($All) {
    Sync-RepoJunction
    Install-GlobalSkills
    Remove-OldClaudeCopies -ClaudeSkillsDir (Join-Path $HOME ".claude\skills")

    $ParentDir = Split-Path -Parent $RepoRoot
    if ($ParentDir -and (Test-Path $ParentDir)) {
        $SiblingProjects = Get-ChildItem -Path $ParentDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -ne $RepoRoot }
        foreach ($Proj in $SiblingProjects) {
            $ProjSkillsDir = Join-Path $Proj.FullName ".agents\skills"
            if (Test-Path $ProjSkillsDir) {
                Write-Host "`nUpdating project: $ProjSkillsDir..." -ForegroundColor Cyan
                Install-SkillsToDirectory -DestinationSkillsDir $ProjSkillsDir -SelectedSkills $Skill -PluginRoot $ProjectPluginRoot
            }
            $ProjClaudeDir = Join-Path $Proj.FullName ".claude\skills"
            if (Test-Path $ProjClaudeDir) { Remove-OldClaudeCopies -ClaudeSkillsDir $ProjClaudeDir }
        }
    }
    Write-Host ""
    Show-ClaudePluginHint
    Write-Host "`nAll global and project skills updated!" -ForegroundColor Green
    exit 0
}

if ($Claude) {
    if ($Global) {
        Remove-OldClaudeCopies -ClaudeSkillsDir (Join-Path $HOME ".claude\skills")
    } elseif (-not [string]::IsNullOrWhiteSpace($Target) -and (Test-Path $Target)) {
        Remove-OldClaudeCopies -ClaudeSkillsDir (Join-Path (Resolve-Path $Target).Path ".claude\skills")
    }
    Show-ClaudePluginHint
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
    Write-Host "  Project install:   .\install.ps1 -Target `"C:\path\to\project`" [-Force] [-Prune]"
    Write-Host "  Single skill:      .\install.ps1 -Target `"C:\path\to\project`" -Skill flow,implement"
    Write-Host "  Claude Code:       .\install.ps1 -Claude [-Global | -Target `"C:\path\to\project`"] [-Prune]  (prints the plugin commands)"
    Write-Host "  Sync repo:         .\install.ps1 -SyncRepo"
    exit 1
}

$ResolvedTarget = Resolve-Path $Target -ErrorAction SilentlyContinue
if (-not $ResolvedTarget) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    $ResolvedTarget = Resolve-Path $Target
}
$TargetRoot = $ResolvedTarget.Path
$TargetSkillsDir = Join-Path $TargetRoot ".agents\skills"

Write-Host "Installing Practical Agent Skills into project: $TargetRoot" -ForegroundColor Cyan
Install-SkillsToDirectory -DestinationSkillsDir $TargetSkillsDir -SelectedSkills $Skill -PluginRoot $ProjectPluginRoot

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
