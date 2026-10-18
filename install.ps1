<#
.SYNOPSIS
    Installs Practical Agent Skills locally into a project or globally on your machine.

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
    # Link .agents/skills -> skills/ via Directory Junction inside this repository
    .\install.ps1 -SyncRepo

.EXAMPLE
    # Update EVERYWHERE: repo junction + global directories + all sibling projects with .agents/skills
    .\install.ps1 -All
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
    [switch]$All
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CanonicalSkillsDir = Join-Path $RepoRoot "skills"
$WorkspaceSkillsDir = Join-Path $RepoRoot ".agents\skills"

function Sync-RepoJunction {
    Write-Host "Linking .agents/skills -> skills/ via Directory Junction..." -ForegroundColor Cyan
    $AgentsDir = Join-Path $RepoRoot ".agents"
    if (-not (Test-Path $AgentsDir)) {
        New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
    }
    if (Test-Path $WorkspaceSkillsDir) {
        Remove-Item -Path $WorkspaceSkillsDir -Recurse -Force
    }
    New-Item -ItemType Junction -Path $WorkspaceSkillsDir -Target $CanonicalSkillsDir | Out-Null
    Write-Host "  [+] .agents/skills -> skills/ (Junction ready)" -ForegroundColor Green
}

if ($SyncRepo) {
    Sync-RepoJunction
    exit 0
}

$SourceDir = if (Test-Path $CanonicalSkillsDir) { $CanonicalSkillsDir } else { $WorkspaceSkillsDir }

function Install-SkillsToDirectory {
    param(
        [string]$DestinationSkillsDir,
        [string[]]$SelectedSkills
    )
    if (-not (Test-Path $DestinationSkillsDir)) {
        New-Item -ItemType Directory -Path $DestinationSkillsDir -Force | Out-Null
    }

    $SkillFolders = Get-ChildItem -Path $SourceDir -Directory
    if ($SelectedSkills.Count -gt 0) {
        $SkillFolders = $SkillFolders | Where-Object { $SelectedSkills -contains $_.Name }
    }

    foreach ($Folder in $SkillFolders) {
        $DestFolder = Join-Path $DestinationSkillsDir $Folder.Name
        if (-not (Test-Path $DestFolder)) {
            New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $Folder.FullName "*") -Destination $DestFolder -Recurse -Force
        Write-Host "  [+] Installed /$($Folder.Name) -> $DestFolder" -ForegroundColor Green
    }
}

function Install-GlobalSkills {
    $AgyGlobalSkills = Join-Path $HOME ".gemini\config\skills"
    $UniversalGlobalSkills = Join-Path $HOME ".agents\skills"

    Write-Host "Installing Practical Agent Skills GLOBALLY..." -ForegroundColor Cyan
    Install-SkillsToDirectory -DestinationSkillsDir $AgyGlobalSkills -SelectedSkills $Skill
    Install-SkillsToDirectory -DestinationSkillsDir $UniversalGlobalSkills -SelectedSkills $Skill
}

if ($All) {
    Sync-RepoJunction
    Install-GlobalSkills

    $ParentDir = Split-Path -Parent $RepoRoot
    if ($ParentDir -and (Test-Path $ParentDir)) {
        $SiblingProjects = Get-ChildItem -Path $ParentDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -ne $RepoRoot -and (Test-Path (Join-Path $_.FullName ".agents\skills")) }
        foreach ($Proj in $SiblingProjects) {
            $ProjSkillsDir = Join-Path $Proj.FullName ".agents\skills"
            Write-Host "`nUpdating project: $($Proj.FullName)..." -ForegroundColor Cyan
            Install-SkillsToDirectory -DestinationSkillsDir $ProjSkillsDir -SelectedSkills $Skill
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
    Write-Host "  Update everywhere: .\install.ps1 -All"
    Write-Host "  Global install:    .\install.ps1 -Global"
    Write-Host "  Project install:   .\install.ps1 -Target `"C:\path\to\project`""
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
$TargetSkillsDir = Join-Path $TargetRoot ".agents\skills"

Write-Host "Installing Practical Agent Skills into project: $TargetRoot" -ForegroundColor Cyan
Install-SkillsToDirectory -DestinationSkillsDir $TargetSkillsDir -SelectedSkills $Skill

# Ensure .temp/ is in target project's .gitignore
$GitIgnorePath = Join-Path $TargetRoot ".gitignore"
if (Test-Path $GitIgnorePath) {
    $GitIgnoreContent = Get-Content $GitIgnorePath -Raw
    if ($GitIgnoreContent -notmatch "(?m)^\.temp/?$") {
        Add-Content -Path $GitIgnorePath -Value "`n.temp/"
        Write-Host "  [+] Added .temp/ to $GitIgnorePath" -ForegroundColor DarkCyan
    }
} else {
    Set-Content -Path $GitIgnorePath -Value ".temp/`n"
    Write-Host "  [+] Created $GitIgnorePath with .temp/" -ForegroundColor DarkCyan
}

Write-Host "`nProject installation complete!" -ForegroundColor Green

