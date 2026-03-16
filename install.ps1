# =============================================================================
# dotfiles installer — restore full Windows terminal setup
# Usage: pwsh -File .\install.ps1   (from ~\dotfiles)
# =============================================================================

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "`e[31m[FAIL]`e[0m  This script requires PowerShell 7+." -ForegroundColor Red
    Write-Host "  Install:  winget install Microsoft.PowerShell"
    Write-Host "  Then run: pwsh -File install.ps1"
    exit 1
}

$ErrorActionPreference = 'Stop'

$DOTFILES_DIR = $PSScriptRoot
$BACKUP_DIR = Join-Path $env:USERPROFILE ".dotfiles-backup\$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ─── Colors ──────────────────────────────────────────────────────────────────
function Info  { Write-Host "`e[34m[INFO]`e[0m  $($args -join ' ')" }
function OK    { Write-Host "`e[32m[OK]`e[0m    $($args -join ' ')" }
function Warn  { Write-Host "`e[33m[WARN]`e[0m  $($args -join ' ')" }
function Fail  { Write-Host "`e[31m[FAIL]`e[0m  $($args -join ' ')"; exit 1 }

# ─── Helpers ─────────────────────────────────────────────────────────────────
function Set-SecureFileAcl {
    param([Parameter(Mandatory)][string]$Path)
    $acl = Get-Acl $Path
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) {
        $acl.RemoveAccessRule($rule) | Out-Null
    }
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $identity, 'FullControl', 'Allow')
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $Path -AclObject $acl
}

function Test-ExternalCommand {
    param([string]$Name, [string]$Action)
    if ($LASTEXITCODE -ne 0) {
        Fail "$Name failed (exit code $LASTEXITCODE) during: $Action"
    }
}

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value
    )
    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Test-SymlinkPointsTo {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$ExpectedTarget
    )

    if (-not (Test-Path $LinkPath)) { return $false }

    $item = Get-Item -LiteralPath $LinkPath -ErrorAction SilentlyContinue
    if (-not $item -or -not $item.LinkType) { return $false }

    $actualTarget = $item.Target
    if ($actualTarget -is [array]) {
        $actualTarget = $actualTarget[0]
    }
    if ([string]::IsNullOrWhiteSpace($actualTarget)) { return $false }

    if (-not [System.IO.Path]::IsPathRooted($actualTarget)) {
        $actualTarget = Join-Path (Split-Path $LinkPath -Parent) $actualTarget
    }

    try {
        $actual = [System.IO.Path]::GetFullPath($actualTarget)
        $expected = [System.IO.Path]::GetFullPath($ExpectedTarget)
        return $actual -eq $expected
    } catch {
        return $false
    }
}

function Install-LinkedConfig {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$BackupName,
        [Parameter(Mandatory)][string]$Label
    )

    $destDir = Split-Path $Destination -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if (Test-SymlinkPointsTo -LinkPath $Destination -ExpectedTarget $Source) {
        OK "$Label already linked → $Destination"
        return
    }

    if (Test-Path $Destination) {
        $existing = Get-Item -LiteralPath $Destination -ErrorAction SilentlyContinue
        if ($existing -and $existing.LinkType) {
            Remove-Item -LiteralPath $Destination -Force
            Info "Removed stale symlink → $Destination"
        } else {
            Copy-Item -LiteralPath $Destination -Destination (Join-Path $BACKUP_DIR $BackupName) -Force
            Warn "Backed up existing $Label → $BACKUP_DIR"
            Remove-Item -LiteralPath $Destination -Force
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
        if (Test-SymlinkPointsTo -LinkPath $Destination -ExpectedTarget $Source) {
            OK "Linked $Label → $Destination"
            return
        }
        throw "Symbolic link target mismatch after creation."
    } catch {
        Warn "Symlink failed for $Label; falling back to file copy (try Developer Mode/Admin): $($_.Exception.Message)"
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        OK "Copied $Label → $Destination"
    }
}

# ─── Pre-flight ──────────────────────────────────────────────────────────────
if ($env:OS -ne 'Windows_NT') { Fail "This script is for Windows only." }

Write-Host ""
Write-Host "============================================"
Write-Host "  dotfiles installer for Windows"
Write-Host "============================================"
Write-Host ""
Info "Starting installation..."

# ─── Step 0: Proxy (FIRST — everything else downloads faster) ────────────────
$CLASH_DIR = Join-Path $env:USERPROFILE ".config\clash"
$CLASH_DEST = Join-Path $CLASH_DIR "config.yaml"

function Test-Proxy {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect('127.0.0.1', 7890)
        $tcp.Close()
        $env:HTTP_PROXY  = 'http://127.0.0.1:7890'
        $env:HTTPS_PROXY = 'http://127.0.0.1:7890'
        $env:ALL_PROXY   = 'socks5://127.0.0.1:7891'
        return $true
    } catch {
        return $false
    }
}

function New-ClashConfig {
    Write-Host ""
    Info "Interactive Shadowsocks config setup"
    Write-Host "  `e[34mEnter your Shadowsocks server details:`e[0m"
    Write-Host ""

    # Server address (required)
    $ss_server = ''
    while ([string]::IsNullOrEmpty($ss_server)) {
        $ss_server = Read-Host "  Server address (required)"
        if ([string]::IsNullOrEmpty($ss_server)) {
            Write-Host "  `e[31mServer address is required.`e[0m"
        }
    }

    # Port (default: 38883)
    $ss_port = Read-Host "  Port [38883]"
    if ([string]::IsNullOrEmpty($ss_port)) { $ss_port = '38883' }

    # Password (required, hidden)
    $ss_password = ''
    while ([string]::IsNullOrEmpty($ss_password)) {
        $ss_password = Read-Host "  Password (required, hidden)" -MaskInput
        if ([string]::IsNullOrEmpty($ss_password)) {
            Write-Host "  `e[31mPassword is required.`e[0m"
        }
    }

    # Cipher (default: chacha20-ietf-poly1305)
    $ss_cipher = Read-Host "  Cipher [chacha20-ietf-poly1305]"
    if ([string]::IsNullOrEmpty($ss_cipher)) { $ss_cipher = 'chacha20-ietf-poly1305' }

    # Proxy name (default: SS-proxy)
    $ss_name = Read-Host "  Proxy name [SS-proxy]"
    if ([string]::IsNullOrEmpty($ss_name)) { $ss_name = 'SS-proxy' }

    # Generate config
    New-Item -ItemType Directory -Path $CLASH_DIR -Force | Out-Null
    @"
#---------------------------------------------------#
## 配置文件需要放置在 ~/.config/clash/*.yaml

## 这份文件是 Clash Verge 的基础配置文件
## 如果您不知道如何操作，请参阅 https://clash-verge-rev.github.io/
#---------------------------------------------------#

mode: rule
log-level: info

proxies:
  - name: "${ss_name}"
    type: ss
    server: '${ss_server}'
    port: ${ss_port}
    cipher: '${ss_cipher}'
    password: '${ss_password}'
    udp: true

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - '${ss_name}'
      - DIRECT

rules:
  # Google 走代理
  - DOMAIN-SUFFIX,google.com,Proxy
  - DOMAIN-SUFFIX,googleapis.com,Proxy
  - DOMAIN-SUFFIX,gstatic.com,Proxy

  # 其他
  - DOMAIN-SUFFIX,ad.com,REJECT
  - GEOIP,CN,DIRECT
  - DOMAIN-SUFFIX,intsig.net,DIRECT
  - MATCH,Proxy
"@ | Set-Content -Path $CLASH_DEST -Encoding UTF8
    Set-SecureFileAcl -Path $CLASH_DEST

    OK "Config written → $CLASH_DEST"
}

# ── Main proxy setup flow ──
if (Test-Proxy) {
    OK "Proxy is working (http://127.0.0.1:7890)"
} else {
    # Check if Clash Verge is installed
    $clashInstalled = (Get-Command 'clash-verge' -ErrorAction SilentlyContinue) -or
        (Test-Path "$env:LOCALAPPDATA\clash-verge") -or
        (Test-Path "$env:LOCALAPPDATA\Clash Verge") -or
        (Test-Path "${env:ProgramFiles}\Clash Verge")

    if (-not $clashInstalled) {
        Write-Host ""
        Write-Host "  `e[31mClash Verge is NOT installed.`e[0m"
        Write-Host ""
        Write-Host "  Download from: https://github.com/clash-verge-rev/clash-verge-rev/releases"
        Write-Host ""
        Read-Host "  Press Enter after installing Clash Verge (or Enter to skip)"
    }

    if (Test-Path $CLASH_DEST) {
        OK "Clash config already exists at $CLASH_DEST"
        Write-Host ""
        Write-Host "  `e[33mOpen Clash Verge and enable System Proxy, then press Enter`e[0m"
        Read-Host "  Press Enter when ready"
        if (Test-Proxy) {
            OK "Proxy is working (http://127.0.0.1:7890)"
        } else {
            Warn "Proxy not reachable, continuing without proxy (downloads may be slow)"
        }
    } else {
        Write-Host ""
        Write-Host "  `e[33mNo Clash config found at $CLASH_DEST`e[0m"
        Write-Host ""
        $createConfig = Read-Host "  Create config from Shadowsocks server info? [Y/n]"
        if ($createConfig -ne 'n' -and $createConfig -ne 'N') {
            New-ClashConfig

            Write-Host ""
            Write-Host "  `e[33mNow open Clash Verge and enable System Proxy, then press Enter`e[0m"
            Read-Host "  Press Enter when ready"
            if (Test-Proxy) {
                OK "Proxy is working (http://127.0.0.1:7890)"
            } else {
                Warn "Proxy not reachable, continuing without proxy (downloads may be slow)"
            }
        } else {
            Warn "Skipped proxy config — downloads may be slow"
        }
    }
}
Write-Host ""

# ─── Step 1: Scoop ──────────────────────────────────────────────────────────
Info "Checking Scoop..."
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    OK "Scoop already installed"
} else {
    Info "Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    OK "Scoop installed"
}

# Add extras bucket (needed for some packages)
$scoopBuckets = scoop bucket list 2>&1 | Out-String
if ($scoopBuckets -notmatch 'extras') {
    scoop bucket add extras 2>$null
    Test-ExternalCommand 'scoop' 'bucket add extras'
}

# ─── Step 2: CLI tools via Scoop ────────────────────────────────────────────
Info "Installing CLI tools..."
$SCOOP_PACKAGES = @('eza', 'bat', 'fd', 'ripgrep', 'fzf', 'zoxide', 'gh', 'nodejs')
foreach ($pkg in $SCOOP_PACKAGES) {
    $installed = scoop list $pkg 2>&1 | Out-String
    if ($installed -match [regex]::Escape($pkg)) {
        OK "$pkg already installed"
    } else {
        Info "Installing $pkg..."
        scoop install $pkg
        Test-ExternalCommand 'scoop' "install $pkg"
        OK "$pkg installed"
    }
}

# ─── Step 3: Oh My Posh ────────────────────────────────────────────────────
Info "Checking Oh My Posh..."
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    OK "Oh My Posh already installed"
} else {
    Info "Installing Oh My Posh..."
    scoop install oh-my-posh
    Test-ExternalCommand 'scoop' 'install oh-my-posh'
    OK "Oh My Posh installed"
}

# ─── Step 4: Nerd Font ─────────────────────────────────────────────────────
Info "Checking Nerd Font..."
$fontInstalled = scoop list 'Meslo-NF' 2>&1 | Select-String 'Meslo-NF'
if ($fontInstalled) {
    OK "MesloLGS Nerd Font already installed"
} else {
    Info "Installing MesloLGS Nerd Font..."
    $fontBuckets = scoop bucket list 2>&1 | Out-String
    if ($fontBuckets -notmatch 'nerd-fonts') {
        scoop bucket add nerd-fonts
        Test-ExternalCommand 'scoop' 'bucket add nerd-fonts'
    }
    scoop install nerd-fonts/Meslo-NF
    Test-ExternalCommand 'scoop' 'install nerd-fonts/Meslo-NF'
    OK "MesloLGS Nerd Font installed"
}

# ─── Step 5: uv (Python package manager) ───────────────────────────────────
Info "Checking uv..."
if (Get-Command uv -ErrorAction SilentlyContinue) {
    OK "uv already installed"
} else {
    Info "Installing uv..."
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Fail "uv installation failed. Check network/proxy and re-run."
    }
    OK "uv installed"
}

# ─── Step 6: Bun ───────────────────────────────────────────────────────────
Info "Checking Bun..."
if ((Get-Command bun -ErrorAction SilentlyContinue) -or (Test-Path "$env:USERPROFILE\.bun\bin\bun.exe")) {
    OK "Bun already installed"
} else {
    Info "Installing Bun..."
    Invoke-RestMethod https://bun.sh/install.ps1 | Invoke-Expression
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if (-not ((Get-Command bun -ErrorAction SilentlyContinue) -or (Test-Path "$env:USERPROFILE\.bun\bin\bun.exe"))) {
        Fail "Bun installation failed. Check network/proxy and re-run."
    }
    OK "Bun installed"
}

# ─── Step 7: Link config files ─────────────────────────────────────────────
Info "Setting up config files..."

# Create backup directory
New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null

# PowerShell profile
$profileSource = Join-Path $DOTFILES_DIR "config\powershell_profile.ps1"
Install-LinkedConfig -Source $profileSource -Destination $PROFILE -BackupName (Split-Path $PROFILE -Leaf) -Label "PowerShell profile"

# Oh My Posh theme
$ompDir = Join-Path $env:USERPROFILE ".config\oh-my-posh"
New-Item -ItemType Directory -Path $ompDir -Force | Out-Null
$ompDest = Join-Path $ompDir "theme.omp.json"
$ompSource = Join-Path $DOTFILES_DIR "config\oh-my-posh-theme.omp.json"
Install-LinkedConfig -Source $ompSource -Destination $ompDest -BackupName "theme.omp.json" -Label "Oh My Posh theme"

# bunfig.toml
$bunfigDest = Join-Path $env:USERPROFILE ".bunfig.toml"
$bunfigSource = Join-Path $DOTFILES_DIR "config\bunfig.toml"
Install-LinkedConfig -Source $bunfigSource -Destination $bunfigDest -BackupName ".bunfig.toml" -Label "bunfig.toml"

# Windows Terminal setup
Write-Host ""
Info "Configuring Windows Terminal..."
$wtSettingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)
$wtSettingsPath = $wtSettingsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($wtSettingsPath) {
    try {
        $wtThemePath = Join-Path $DOTFILES_DIR "config\windows-terminal-catppuccin.json"
        $wtTheme = Get-Content -Path $wtThemePath -Raw | ConvertFrom-Json -Depth 100
        $wtSettings = Get-Content -Path $wtSettingsPath -Raw | ConvertFrom-Json -Depth 100

        Copy-Item -LiteralPath $wtSettingsPath -Destination (Join-Path $BACKUP_DIR "windows-terminal-settings.json") -Force
        Warn "Backed up existing Windows Terminal settings → $BACKUP_DIR"

        if (-not $wtSettings.schemes) {
            Set-ObjectProperty -Object $wtSettings -Name 'schemes' -Value @()
        }

        $hasCatppuccin = $false
        foreach ($scheme in @($wtSettings.schemes)) {
            if ($scheme.name -eq 'Catppuccin Mocha') {
                $hasCatppuccin = $true
                break
            }
        }
        if (-not $hasCatppuccin) {
            $wtSettings.schemes = @($wtSettings.schemes) + $wtTheme
            OK "Added Catppuccin Mocha scheme"
        } else {
            OK "Catppuccin Mocha scheme already present"
        }

        if (-not $wtSettings.profiles) {
            Set-ObjectProperty -Object $wtSettings -Name 'profiles' -Value ([pscustomobject]@{})
        }
        if (-not $wtSettings.profiles.defaults) {
            Set-ObjectProperty -Object $wtSettings.profiles -Name 'defaults' -Value ([pscustomobject]@{})
        }

        Set-ObjectProperty -Object $wtSettings.profiles.defaults -Name 'colorScheme' -Value 'Catppuccin Mocha'
        if (-not $wtSettings.profiles.defaults.font) {
            Set-ObjectProperty -Object $wtSettings.profiles.defaults -Name 'font' -Value ([pscustomobject]@{})
        }
        Set-ObjectProperty -Object $wtSettings.profiles.defaults.font -Name 'face' -Value 'MesloLGS Nerd Font'
        Set-ObjectProperty -Object $wtSettings.profiles.defaults.font -Name 'size' -Value 14

        $wtSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $wtSettingsPath -Encoding UTF8
        OK "Updated Windows Terminal settings → $wtSettingsPath"
    } catch {
        Warn "Failed to auto-configure Windows Terminal: $($_.Exception.Message)"
        Write-Host ""
        Info "Windows Terminal manual setup:"
        Write-Host "  1. Open Windows Terminal Settings (Ctrl+,)"
        Write-Host "  2. Click 'Open JSON file' at bottom-left"
        Write-Host "  3. Add the contents of config\windows-terminal-catppuccin.json to the `"schemes`" array"
        Write-Host "  4. Set `"colorScheme`": `"Catppuccin Mocha`" in profile defaults"
        Write-Host "  5. Set font to `"MesloLGS Nerd Font`" and size `"14`" in profile defaults"
        Write-Host ""
    }
} else {
    Warn "Windows Terminal settings.json not found."
    Write-Host ""
    Info "Windows Terminal manual setup:"
    Write-Host "  1. Open Windows Terminal Settings (Ctrl+,)"
    Write-Host "  2. Click 'Open JSON file' at bottom-left"
    Write-Host "  3. Add the contents of config\windows-terminal-catppuccin.json to the `"schemes`" array"
    Write-Host "  4. Set `"colorScheme`": `"Catppuccin Mocha`" in profile defaults"
    Write-Host "  5. Set font to `"MesloLGS Nerd Font`" and size `"14`" in profile defaults"
    Write-Host ""
}

# ─── Step 8: Secrets ──────────────────────────────────────────────────────
$SECRETS_FILE = Join-Path $env:USERPROFILE ".secrets.ps1"
if (-not (Test-Path $SECRETS_FILE)) {
    Info "Setting up ~/.secrets.ps1..."
    Write-Host ""

    $secretValue = Read-Host "  `e[34mIntsig API Key`e[0m (hidden, Enter to skip)" -MaskInput
    Write-Host ""

    if (-not [string]::IsNullOrEmpty($secretValue)) {
        @"
# Machine-specific secrets — NOT tracked by git
`$env:INTSIG_API_KEY = '$($secretValue -replace "'", "''")'
"@ | Set-Content -Path $SECRETS_FILE -Encoding UTF8
    } else {
        @"
# Machine-specific secrets — NOT tracked by git
# `$env:INTSIG_API_KEY = 'your_key_here'
"@ | Set-Content -Path $SECRETS_FILE -Encoding UTF8
        Warn "Skipped Intsig API Key (edit ~/.secrets.ps1 later)"
    }

    OK "~/.secrets.ps1 created"
    Set-SecureFileAcl -Path $SECRETS_FILE
} else {
    OK "~/.secrets.ps1 already exists, not overwriting"
}

# ─── Step 9: GitHub CLI authentication ──────────────────────────────────────
Info "Checking GitHub CLI authentication..."
$null = gh auth status 2>&1
if ($LASTEXITCODE -eq 0) {
    OK "GitHub CLI already authenticated"
} else {
    Warn "GitHub CLI is not authenticated"
    Write-Host ""
    Write-Host "  `e[34mInteractive login will help you authenticate with GitHub.`e[0m"
    Write-Host "  This is optional — you can configure it manually later."
    Write-Host ""
    $ghLogin = Read-Host "  Run 'gh auth login' now? [y/N]"
    if ($ghLogin -eq 'y' -or $ghLogin -eq 'Y') {
        Info "Starting GitHub CLI authentication..."
        gh auth login
        if ($LASTEXITCODE -eq 0) {
            OK "GitHub CLI authentication completed"
        } else {
            Warn "GitHub CLI authentication failed (network or proxy issue?)"
            Write-Host "  You can authenticate manually later with: gh auth login"
        }
    } else {
        Info "Skipping GitHub CLI authentication — configure manually with: gh auth login"
    }
}

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================"
Write-Host "  `e[32mAll done!`e[0m"
Write-Host "============================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open a NEW PowerShell window to see the new prompt"
Write-Host "  2. If Windows Terminal was not auto-configured, follow the manual setup instructions above"
Write-Host "  Backups saved to: $BACKUP_DIR"
Write-Host ""
