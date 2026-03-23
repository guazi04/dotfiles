-- dotfiles-managed — do not edit manually; changes will be overwritten by install.ps1
--
-- WezTerm configuration — mirrors tmux.conf keybindings and Catppuccin Mocha theme
-- Session persistence via mux server (Named Pipes on Windows)
--

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ============================================================
-- Catppuccin Mocha Colors (exact hex values from tmux.conf)
-- ============================================================

local thm = {
  bg      = '#1e1e2e',
  fg      = '#cdd6f4',
  cyan    = '#89dceb',
  black   = '#181825',
  gray    = '#313244',
  magenta = '#cba6f7',
  pink    = '#f5c2e7',
  red     = '#f38ba8',
  green   = '#a6e3a1',
  yellow  = '#f9e2af',
  blue    = '#89b4fa',
  orange  = '#fab387',
  black4  = '#585b70',
}

-- Nerd Font / Powerline glyphs
local SOLID_RIGHT = utf8.char(0xe0b0)
local SOLID_LEFT  = utf8.char(0xe0b2)

-- ============================================================
-- General Settings
-- ============================================================

config.default_prog = { 'pwsh.exe' }
config.scrollback_lines = 50000
config.font = wezterm.font('MesloLGS Nerd Font')
config.font_size = 14
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.window_close_confirmation = 'NeverPrompt'
config.default_workspace = 'main'

-- ============================================================
-- Session Persistence (Mux Server)
-- ============================================================
-- On Windows, unix_domains uses Named Pipes internally.
-- Sessions survive closing the WezTerm window — just relaunch to reattach.
-- Use Leader + d to detach cleanly.

config.unix_domains = {
  { name = 'unix' },
}
config.default_gui_startup_args = { 'connect', 'unix' }

-- ============================================================
-- Custom Color Scheme
-- ============================================================

config.color_schemes = {
  ['Catppuccin Mocha Custom'] = {
    foreground = thm.fg,
    background = thm.bg,
    cursor_bg = thm.fg,
    cursor_fg = thm.bg,
    cursor_border = thm.fg,
    selection_fg = thm.bg,
    selection_bg = thm.pink,
    ansi = {
      thm.black, thm.red, thm.green, thm.yellow,
      thm.blue, thm.magenta, thm.cyan, thm.fg,
    },
    brights = {
      thm.black4, thm.red, thm.green, thm.yellow,
      thm.blue, thm.magenta, thm.cyan, '#ffffff',
    },
    split = thm.gray,
  },
}
config.color_scheme = 'Catppuccin Mocha Custom'

-- ============================================================
-- Tab Bar (retro style at bottom — matches tmux window status)
-- ============================================================

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

config.colors = {
  tab_bar = {
    background = thm.bg,
    -- Active tab: green bg, black text, bold (tmux: window-status-current-format)
    active_tab = { bg_color = thm.green, fg_color = thm.black, intensity = 'Bold' },
    -- Inactive tab: black4 text on bg (tmux: window-status-format)
    inactive_tab = { bg_color = thm.bg, fg_color = thm.black4 },
    inactive_tab_hover = { bg_color = thm.gray, fg_color = thm.fg },
    new_tab = { bg_color = thm.bg, fg_color = thm.black4 },
    new_tab_hover = { bg_color = thm.gray, fg_color = thm.fg },
  },
  -- Pane split color (tmux: pane-border-style fg=gray)
  split = thm.gray,
}

-- Dim inactive panes (since WezTerm lacks per-pane border colors like tmux)
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.75 }

-- ============================================================
-- Key Bindings (mirrors tmux.conf — prefix C-b)
-- ============================================================

-- Leader key: CTRL+B (same as tmux prefix)
config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 2000 }

config.keys = {
  -- Pass through CTRL+B when pressed twice (tmux: bind C-b send-prefix)
  { key = 'b', mods = 'LEADER|CTRL', action = act.SendKey { key = 'b', mods = 'CTRL' } },

  -- Split panes: | horizontal, - vertical (tmux: bind | split-window -h, bind - split-window -v)
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER',       action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- New tab in current directory (tmux: bind c new-window -c "#{pane_current_path}")
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Vim-style pane navigation (tmux: bind h/j/k/l select-pane -L/D/U/R)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Resize panes by 5 units (tmux: bind -r H/J/K/L resize-pane -L/D/U/R 5)
  { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- Reload config (tmux: bind r source-file ~/.tmux.conf)
  { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },

  -- Detach from mux — sessions persist in background (like tmux detach)
  { key = 'd', mods = 'LEADER', action = act.DetachDomain 'CurrentPaneDomain' },

  -- Rename tab (tmux: bind , command-prompt -I "#W" "rename-window '%%'")
  { key = ',', mods = 'LEADER', action = act.PromptInputLine {
    description = 'Enter new tab name',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  } },

  -- Close current pane with confirmation
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- Tab navigation by number (maps to 0-indexed tabs, matching tmux base-index 1 visually)
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
  { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
  { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
  { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
  { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },
}

-- ============================================================
-- Status Bar (mirrors tmux status-left and status-right)
-- ============================================================

wezterm.on('update-status', function(window, pane)
  local workspace = window:active_workspace()

  -- Left: workspace name on blue background (tmux: status-left "  #S  ")
  window:set_left_status(wezterm.format {
    { Background = { Color = thm.blue } },
    { Foreground = { Color = thm.black } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = '  ' .. workspace .. ' ' },
    { Background = { Color = thm.bg } },
    { Foreground = { Color = thm.blue } },
    { Text = SOLID_RIGHT .. ' ' },
  })

  -- Right: LEADER indicator (when active) + time + date
  local right = ''

  if window:leader_is_active() then
    right = right .. wezterm.format {
      { Foreground = { Color = thm.yellow } },
      { Text = SOLID_LEFT },
      { Background = { Color = thm.yellow } },
      { Foreground = { Color = thm.black } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = ' LEADER ' },
      { Background = { Color = thm.bg } },
      { Text = ' ' },
    }
  end

  -- Time block: gray bg (tmux: "  %H:%M ")
  -- Date block: magenta bg, bold (tmux: "  %Y-%m-%d ")
  right = right .. wezterm.format {
    { Foreground = { Color = thm.gray } },
    { Text = SOLID_LEFT },
    { Background = { Color = thm.gray } },
    { Foreground = { Color = thm.fg } },
    { Text = '  ' .. wezterm.strftime '%H:%M' .. ' ' },
    { Foreground = { Color = thm.magenta } },
    { Text = SOLID_LEFT },
    { Background = { Color = thm.magenta } },
    { Foreground = { Color = thm.black } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = '  ' .. wezterm.strftime '%Y-%m-%d' .. ' ' },
  }

  window:set_right_status(right)
end)

return config
