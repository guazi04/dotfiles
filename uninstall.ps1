# =============================================================================
# dotfiles uninstaller — remove Windows terminal config, restore backups
# Usage: pwsh -File .\uninstall.ps1   (from ~\dotfiles)
# =============================================================================

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "`e[31m[FAIL]`e[0m  This script requires PowerShell 7+." -ForegroundColor Red
    Write-Host "  Install:  winget install Microsoft.PowerShell"
    Write-Host "  Then run: pwsh -File uninstall.ps1"
    exit 1
}

$ErrorActionPreference = 'Stop'

function OK   { Write-Host "`e[32m[OK]`e[0m    $($args -join ' ')" }
function Warn { Write-Host "`e[33m[WARN]`e[0m  $($args -join ' ')" }

Write-Host ""
Write-Host "This will remove config files and restore backups if available."
Write-Host ""
$answer = Read-Host "Continue? [y/N]"
if ($answer -ne 'y' -and $answer -ne 'Y') { exit 0 }

$targets = @(
    $PROFILE,
    (Join-Path $env:USERPROFILE ".config\oh-my-posh\theme.omp.json"),
    (Join-Path $env:USERPROFILE ".bunfig.toml")
)

# Find latest backup
$backupBase = Join-Path $env:USERPROFILE ".dotfiles-backup"
$latestBackup = $null
if (Test-Path $backupBase) {
    $latestBackup = Get-ChildItem -Path $backupBase -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1
}

foreach ($target in $targets) {
    $name = Split-Path $target -Leaf
    if (Test-Path $target) {
        $item = Get-Item -LiteralPath $target -ErrorAction SilentlyContinue

        # Safety check: only remove $PROFILE if it was installed by dotfiles
        if ($target -eq $PROFILE) {
            $firstLine = Get-Content -LiteralPath $target -TotalCount 1 -ErrorAction SilentlyContinue
            if ($firstLine -notmatch 'dotfiles-managed') {
                Warn "$target does not appear to be dotfiles-managed — skipping (delete manually if needed)"
                continue
            }
        }

        if ($item -and $item.LinkType) {
            Remove-Item -LiteralPath $target -Force
            OK "Removed symlink $target"
        } elseif ($item -and $item.PSIsContainer) {
            Remove-Item -LiteralPath $target -Recurse -Force
            OK "Removed directory $target"
        } else {
            Remove-Item -LiteralPath $target -Force
            OK "Removed file $target"
        }

        if ($latestBackup -and (Test-Path (Join-Path $latestBackup.FullName $name))) {
            Copy-Item -LiteralPath (Join-Path $latestBackup.FullName $name) -Destination $target -Force
            OK "Restored $name from backup"
        }
    } else {
        Warn "$target not found, skipping"
    }
}

Write-Host ""
Write-Host "`e[32mUninstall complete.`e[0m Installed tools (Scoop packages, Oh My Posh, etc.) were NOT removed."
Write-Host "To remove those manually:"
Write-Host "  scoop uninstall eza bat fd ripgrep fzf zoxide oh-my-posh gh nodejs"
Write-Host "  scoop uninstall nerd-fonts/Meslo-NF"
Write-Host ""
