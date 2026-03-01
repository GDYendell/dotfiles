local wezterm = require("wezterm")
local act = wezterm.action

local config = {}
-- Use config builder object if possible
if wezterm.config_builder then config = wezterm.config_builder() end

-- Settings
config.default_prog = { "zsh" }

local fav_themes = { "tokyonight", "nordfox" }
config.color_scheme = fav_themes[2]
local custom_colors = {
  red = "#D06F79",     --> Tokyonight: "#F7768e"
  cyan = "#88C0D0",    --> Tokyonight: "#7DCFFF"
  magenta = "#B48EAD", --> Tokyonight: "#BB9AF7"
  yellow = "#EBCB8B",  --> Tokyonight: "#E0AF68"
  blue = "#81A1C1",    --> Nordfox blue, matches tmux fg=blue
}

-- 12 for ComicCode, 16 for official Nerd Fonts
local font_sizes = { 12.5, 16 }
config.font_size = font_sizes[1]
config.font = wezterm.font_with_fallback({
  { family = "monospace", },
})
config.window_background_opacity = 0.9
config.macos_window_background_blur = 24
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"

-- Dim inactive panes
config.inactive_pane_hsb = {
  saturation = 0.24,
  brightness = 0.5
}

-- Keys
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 10000 }
config.keys = {
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = ":", mods = "LEADER", action = act.ActivateCommandPalette },

  -- Workspace (similar to session in Tmux)
  { key = "s", mods = "LEADER", action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },

  -- Tab (similar to window in Tmux)
  { key = "w", mods = "LEADER", action = act.ShowTabNavigator },
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  {
    key = ",",
    mods = "LEADER",
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Renaming Tab Title...:" },
      },
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end)
    }
  },
  -- Key table for moving tabs around
  { key = ".",          mods = "LEADER", action = act.ActivateKeyTable { name = "move_tab", one_shot = false } },

  -- Pane
  { key = "\"",         mods = "LEADER", action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "%",          mods = "LEADER", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "h",          mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j",          mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k",          mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l",          mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "phys:Space", mods = "LEADER", action = act.RotatePanes "Clockwise" },
  { key = "z",          mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x",          mods = "LEADER", action = act.CloseCurrentPane { confirm = true } },
  -- We can make separate keybindings for resizing panes
  -- But Wezterm offers custom "mode" in the name of "KeyTable"
  { key = "r",          mods = "LEADER", action = act.ActivateKeyTable { name = "resize_pane", one_shot = false } },
}

-- Navigate tabs with index
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1)
  })
end

config.key_tables = {
  resize_pane = {
    { key = "h",      action = act.AdjustPaneSize { "Left", 1 } },
    { key = "j",      action = act.AdjustPaneSize { "Down", 1 } },
    { key = "k",      action = act.AdjustPaneSize { "Up", 1 } },
    { key = "l",      action = act.AdjustPaneSize { "Right", 1 } },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter",  action = "PopKeyTable" },
  },
  move_tab = {
    { key = "h",      action = act.MoveTabRelative(-1) },
    { key = "j",      action = act.MoveTabRelative(-1) },
    { key = "k",      action = act.MoveTabRelative(1) },
    { key = "l",      action = act.MoveTabRelative(1) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter",  action = "PopKeyTable" },
  }
}

-- Tab bar
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.status_update_interval = 1000

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane
  local cmd = pane.foreground_process_name
  cmd = cmd and cmd:match("([^/\\]+)$") or pane.title
  local title = (tab.tab_index + 1) .. " " .. cmd
  if tab.is_active then
    return {
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. title .. " " },
    }
  end
  return { { Text = " " .. title .. " " } }
end)

config.colors = {
  tab_bar = {
    background = "#2e3440",
    active_tab = {
      bg_color = "#2e3440",
      fg_color = "#ECEFF4",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#2e3440",
      fg_color = "#4C566A",
    },
    inactive_tab_hover = {
      bg_color = "#2e3440",
      fg_color = "#D8DEE9",
    },
    new_tab = {
      bg_color = "#2e3440",
      fg_color = "#4C566A",
    },
    new_tab_hover = {
      bg_color = "#2e3440",
      fg_color = "#D8DEE9",
    },
  },
}

wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = custom_colors.blue
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = custom_colors.cyan
  end
  if window:leader_is_active() then
    stat_color = custom_colors.magenta
  end

  local basename = function(s)
    -- Nothing a little regex can't fix
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    cwd = basename(cwd.file_path) --> URL object introduced in 20240127-113634-bbcac864 (type(cwd) == "userdata")
    -- cwd = basename(cwd) --> 20230712-072601-f4abf8fd or earlier version
  else
    cwd = ""
  end

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = "  " },
    { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
    { Text = "  | " },
  }))

  -- Right status
  window:set_right_status(wezterm.format({
    { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd .. "  " },
  }))
end)

config.enable_wayland = false

return config
