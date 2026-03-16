# dotfiles-managed — do not edit manually (changes will be overwritten by install.ps1)
# ============================================================
# Oh My Posh Prompt
# ============================================================
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = Join-Path $env:USERPROFILE ".config\oh-my-posh\theme.omp.json"
    if (Test-Path $ompTheme) {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    }
}

# ============================================================
# Environment
# ============================================================
$env:LANG = 'en_US.UTF-8'
$env:EDITOR = 'code'
$env:OPENCODE_PORT = '4097'

# ============================================================
# Proxy (auto-detect on shell startup, manual toggle: pon / poff)
# ============================================================
function pon {
    $env:HTTP_PROXY  = 'http://127.0.0.1:7890'
    $env:HTTPS_PROXY = 'http://127.0.0.1:7890'
    $env:ALL_PROXY   = 'socks5://127.0.0.1:7891'
    $env:NO_PROXY    = 'localhost,127.0.0.1,::1'
    $env:http_proxy  = $env:HTTP_PROXY
    $env:https_proxy = $env:HTTPS_PROXY
    $env:all_proxy   = $env:ALL_PROXY
    $env:no_proxy    = $env:NO_PROXY
}

function poff {
    @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY',
      'http_proxy','https_proxy','all_proxy','no_proxy') | ForEach-Object {
        Remove-Item "Env:\$_" -ErrorAction SilentlyContinue
    }
}

# Auto-enable proxy if Clash is running
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect('127.0.0.1', 7890)
    $tcp.Close()
    pon
} catch { }

# ============================================================
# Bun
# ============================================================
$env:BUN_INSTALL = Join-Path $env:USERPROFILE ".bun"
$bunBin = Join-Path $env:BUN_INSTALL "bin"
if ((Test-Path $bunBin) -and ($env:PATH -notlike "*$bunBin*")) {
    $env:PATH = "$bunBin;$env:PATH"
}

# ============================================================
# UV Python Manager
# ============================================================
if (Get-Command uv -ErrorAction SilentlyContinue) {
    $env:UV_PYTHON_PREFERENCE = 'managed'
    function pip { uv pip @args }
    function venv { uv venv @args }
    function pyi { uv pip install @args }
    function pyu { uv pip install --upgrade @args }
}

# ============================================================
# API Keys (loaded from ~/.secrets.ps1 if exists)
# ============================================================
$secretsPath = Join-Path $env:USERPROFILE ".secrets.ps1"
if (Test-Path $secretsPath) { . $secretsPath }

# ============================================================
# Modern CLI Tool Aliases
# ============================================================

# Remove built-in aliases so our functions take precedence
Remove-Item alias:cat -Force -ErrorAction SilentlyContinue
Remove-Item alias:ls -Force -ErrorAction SilentlyContinue

# eza (better ls)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls  { eza --icons --group-directories-first @args }
    function ll  { eza -l --icons --group-directories-first --git --time-style=long-iso @args }
    function la  { eza -la --icons --group-directories-first --git --time-style=long-iso @args }
    function lt  { eza --tree --icons --level=2 --group-directories-first @args }
    function lta { eza --tree --icons --level=3 --group-directories-first -a @args }
}

# bat (better cat)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat  { bat --paging=never @args }
    function catp { bat --plain --paging=never @args }
}

# fd (better find)
if (Get-Command fd -ErrorAction SilentlyContinue) {
    function ff { fd @args }
}

# ============================================================
# FZF Configuration
# ============================================================
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # Use fd for fzf if available
    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
        $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
        $env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --follow --exclude .git'
    }

    # Catppuccin Mocha color scheme for fzf (exact values from zshrc)
    $env:FZF_DEFAULT_OPTS = '--height 60% --layout=reverse --border rounded --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --preview "bat --color=always --style=numbers --line-range=:500 {}" --bind "ctrl-/:toggle-preview"'
}

# ============================================================
# Zoxide (better cd)
# ============================================================
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# ============================================================
# Useful Aliases & Functions
# ============================================================

# Quick navigation
function ..   { Set-Location .. }
function ...  { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Git shortcuts (mirrors zshrc aliases)
function glog { git log --oneline --graph --decorate --all @args }
function gst  { git status -sb @args }

# System
function reload { . $PROFILE }

# Mkdir and cd into it
function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# Show top 10 most used commands
function topcmd {
    $histFile = (Get-PSReadLineOption).HistorySavePath
    if (Test-Path $histFile) {
        Get-Content $histFile |
            ForEach-Object { ($_ -split ' ')[0] } |
            Group-Object |
            Sort-Object Count -Descending |
            Select-Object -First 10 |
            Format-Table Count, Name -AutoSize
    }
}

# ============================================================
# PSReadLine Configuration
# ============================================================
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -MaximumHistoryCount 10000
    Set-PSReadLineOption -HistoryNoDuplicates $true
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd $true

    # Predictive IntelliSense (PSReadLine 2.2+) — graceful fallback for older versions
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        # Older PSReadLine — basic history prediction only
        try { Set-PSReadLineOption -PredictionSource History } catch { }
    }

    # Catppuccin Mocha syntax colors
    try {
        Set-PSReadLineOption -Colors @{
            Command            = '#89b4fa'   # Blue
            Parameter          = '#94e2d5'   # Teal
            Operator           = '#89dceb'   # Sky
            Variable           = '#cdd6f4'   # Text
            String             = '#a6e3a1'   # Green
            Number             = '#fab387'   # Peach
            Type               = '#f9e2af'   # Yellow
            Comment            = '#7f849c'   # Overlay1
            Keyword            = '#cba6f7'   # Mauve
            Member             = '#74c7ec'   # Sapphire
            Error              = '#f38ba8'   # Red
            Emphasis           = '#f5c2e7'   # Pink
            InlinePrediction   = '#585b70'   # Surface2
            ListPrediction     = '#a6adc8'   # Subtext0
            ListPredictionSelected = "`e[38;2;205;214;244;48;2;88;91;112m"  # Text on Surface2
        }
    } catch { }

    # Key bindings
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab -Function MenuCompleteBackward
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key 'Ctrl+r' -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Key 'Ctrl+RightArrow' -Function AcceptNextSuggestionWord
}

# ============================================================
# Utility Functions
# ============================================================

# Disk usage (human-readable, top-level summary of current or given directory)
function duh {
    param([string]$Path = '.')
    Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $size = (Get-ChildItem -Path $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{
                Size = if ($size -ge 1GB) { '{0:N1} GB' -f ($size / 1GB) }
                       elseif ($size -ge 1MB) { '{0:N1} MB' -f ($size / 1MB) }
                       elseif ($size -ge 1KB) { '{0:N1} KB' -f ($size / 1KB) }
                       else { '{0} B' -f $size }
                Name = $_.Name
            }
        } | Sort-Object { (Get-ChildItem -Path (Join-Path $Path $_.Name) -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum } -Descending |
        Format-Table -AutoSize
}

# Disk free (human-readable)
function dfh {
    Get-PSDrive -PSProvider FileSystem |
        Where-Object { $_.Used -or $_.Free } |
        ForEach-Object {
            [PSCustomObject]@{
                Drive = $_.Root
                Used  = '{0:N1} GB' -f ($_.Used / 1GB)
                Free  = '{0:N1} GB' -f ($_.Free / 1GB)
                Total = '{0:N1} GB' -f (($_.Used + $_.Free) / 1GB)
                'Use%' = '{0:N0}%' -f ($_.Used / ($_.Used + $_.Free) * 100)
            }
        } | Format-Table -AutoSize
}
