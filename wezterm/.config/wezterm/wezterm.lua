local wezterm = require("wezterm")
local act = wezterm.action
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local config = {}
-- Use config builder object if possible
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Theme
config.color_scheme = "Dracula (Official)"
local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
local dracula = {
	background = scheme.background,
	foreground = scheme.foreground,
	black = scheme.ansi[1],
	red = scheme.ansi[2],
	green = scheme.ansi[3],
	yellow = scheme.ansi[4],
	blue = scheme.ansi[5],
	magenta = scheme.ansi[6],
	cyan = scheme.ansi[7],
	white = scheme.ansi[8],
	br_black = scheme.brights[1],
	br_red = scheme.brights[2],
	br_green = scheme.brights[3],
	br_yellow = scheme.brights[4],
	br_blue = scheme.brights[5],
	br_magenta = scheme.brights[6],
	br_cyan = scheme.brights[7],
	br_white = scheme.brights[8],
	comment = scheme.brights[1],
}

-- General settings
config.enable_wayland = false

config.default_prog = { "zsh" }

config.font_size = 20
config.font = wezterm.font_with_fallback({
	{ family = "monospace" },
})

config.window_background_opacity = 1.0
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"

-- Dim inactive panes
config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

-- Keys
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 10000 }
config.keys = {
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },

	-- Workspaces
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "c", mods = "LEADER|CTRL", action = act.SwitchToWorkspace({ name = "new" }) },
	{ key = "s", mods = "LEADER|CTRL", action = act.SwitchWorkspaceRelative(1) },
	{
		key = "R",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Workspace...:" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					wezterm.mux.rename_workspace(window:active_workspace(), line)
				end
			end),
		}),
	},

	-- Tabs
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "LEADER|CTRL", action = act.ActivateLastTab },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Tab Title...:" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Panes
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = ";", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Resurrect: save/restore workspace state
	{
		key = "w",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
		end),
	},
	{
		key = "W",
		mods = "ALT",
		action = resurrect.window_state.save_window_action(),
	},
	{
		key = "T",
		mods = "ALT",
		action = resurrect.tab_state.save_tab_action(),
	},
	{
		key = "s",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
			resurrect.window_state.save_window_action()
		end),
	},
	{
		key = "r",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^([^/]+)") -- match before '/'
				id = string.match(id, "([^/]+)$") -- match after '/'
				id = string.match(id, "(.+)%..+$") -- remove file extention
				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					close_open_tabs = true,
					window = pane:window(),
				}
				if type == "workspace" then
					local state = resurrect.state_manager.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					local state = resurrect.state_manager.load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				elseif type == "tab" then
					local state = resurrect.state_manager.load_state(id, "tab")
					resurrect.tab_state.restore_tab(pane:tab(), state, opts)
				end
			end)
		end),
	},

	--  {
	-- 	key = "S",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action_callback(function(win, pane)
	-- 		resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
	-- 	end),
	-- },
	-- {
	-- 	key = "r",
	-- 	mods = "LEADER|CTRL",
	-- 	action = wezterm.action_callback(function(win, pane)
	-- 		resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
	-- 			local type = string.match(id, "^([^/]+)")
	-- 			id = string.gsub(string.match(id, "([^/]+)$"), "%.json$", "")
	-- 			local state = resurrect.state_manager.load_state(id, type)
	-- 			local mux_win = win:mux_window()
	-- 			local restore_opts = {
	-- 				window = mux_win,
	-- 				relative = true,
	-- 				resize_window = false,
	-- 				on_pane_restore = resurrect.tab_state.default_on_pane_restore,
	-- 			}
	-- 			if type == "workspace" then
	-- 				resurrect.workspace_state.restore_workspace(state, restore_opts)
	-- 			elseif type == "window" then
	-- 				resurrect.window_state.restore_window(mux_win, state, restore_opts)
	-- 			elseif type == "tab" then
	-- 				resurrect.tab_state.restore_tab(mux_win:active_tab(), state, restore_opts)
	-- 			end
	-- 		end)
	-- 	end),
	-- },
	--
	-- Key Tables
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },
}

config.key_tables = {
	resize_pane = {
		{ key = "j", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = ";", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(-1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = ";", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- Navigate tabs with index
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- Status bar
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
		active_tab = {
			bg_color = dracula.background,
			fg_color = dracula.foreground,
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = dracula.background,
			fg_color = dracula.comment,
		},
		inactive_tab_hover = {
			bg_color = dracula.background,
			fg_color = dracula.magenta,
		},
		new_tab = {
			bg_color = dracula.background,
			fg_color = dracula.comment,
		},
		new_tab_hover = {
			bg_color = dracula.background,
			fg_color = dracula.magenta,
		},
	},
}

wezterm.on("update-status", function(window, pane)
	-- Workspace name
	local stat = window:active_workspace()
	local stat_color = dracula.blue
	if window:active_key_table() then
		stat = window:active_key_table()
		stat_color = dracula.cyan
	end
	if window:leader_is_active() then
		stat_color = dracula.magenta
	end

	local basename = function(s)
		return string.gsub(s, "(.*[/\\])(.*)", "%2")
	end

	-- Current working directory
	local cwd = pane:get_current_working_dir()
	if cwd then
		cwd = basename(cwd.file_path)
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

return config
