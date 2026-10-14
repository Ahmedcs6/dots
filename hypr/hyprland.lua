-- Migrated from ~/.config/oldhypr/hyprland.conf (hyprlang) to Lua.
-- Hyprland 0.55+ / 0.56.x syntax. Tested on 0.56.2.
-- Refer to https://wiki.hypr.land/configuring/
-- Old config backed up in ~/.config/oldhypr/ (untouched).

------------------
---- MONITORS ----
------------------
-- See https://wiki.hypr.land/configuring/core/monitors/
-- Monitors are configured inline here (single eDP-1 laptop). The legacy
-- hyprlang monitors.conf / workspaces.conf were empty (0 bytes) and are NOT
-- sourced in Lua — they were deleted to avoid confusion.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})
-- Specific override ported from old hyprland.conf (was HDMI-A-1 1920x1080@100):
-- generic above is fallback for laptop-only / new displays.
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@100",
	position = "auto",
	scale = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
-- Old: $terminal/$fileManager/$menu/$browser
local terminal = "foot"
local fileManager = "thunar"
local menu = "rofi -show drun"
local browser = "firefox"

-------------------
---- AUTOSTART ----
-------------------
-- See https://wiki.hypr.land/configuring/core/autostart/
-- Clipboard history: two wl-paste watchers feed text+image copies into
-- cliphist (was: copyq daemon). Picker is on SUPER+v (cliphist-rofi.sh).
hl.on("hyprland.start", function()
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("quickshell")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
----- PERMISSIONS -----
-----------------------
-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Old file had these commented out; kept commented (restart required).
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 8,

		border_size = 1,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 24,
		rounding_power = 2,

		active_opacity = 1.0,
		inactive_opacity = 0.95,
		fullscreen_opacity = 1.0,

		dim_inactive = true,
		dim_strength = 0.2,

		shadow = {
			enabled = true,
			range = 12,
			render_power = 2,
			offset = "2 2",
			color = "rgba(0C0E13A6)",
		},

		blur = {
			enabled = true,
			size = 5,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Old custom beziers: wind, winIn, winOut, liner (+ built-in "default" used by fade)
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
-- HyprNova beziers
hl.curve("shot", { type = "bezier", points = { { 0.2, 1.0 }, { 0.2, 1.0 } } })
hl.curve("swipe", { type = "bezier", points = { { 0.6, 0.0 }, { 0.2, 1.05 } } })
hl.curve("progressive", { type = "bezier", points = { { 1.0, 0.0 }, { 0.6, 1.0 } } })

-- Old: windows 1,6,wind,slide / windowsIn / windowsOut / windowsMove / border /
--      borderangle loop / fade default / workspaces
-- HyprNova: windows 1,6,shot,slide / workspaces 1,6,swipe,slide / fade 1,4,progressive /
--      border 1,6,linear / borderangle loop (speed is deciseconds: 30 = 3s/loop,
--      upstream stock default; NOT a typo — 180 would be 18s/loop)
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "shot", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "progressive" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "swipe", style = "slide" })

-- "Smart gaps" block from old file, translated but left disabled:
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })

hl.config({
	dwindle = {
		preserve_split = true,
		special_scale_factor = 0.8,
		-- NOTE: dwindle:pseudotile was removed in 0.55 (was commented out anyway).
	},
})

hl.config({
	master = {
		new_status = "master",
		new_on_top = true,
		mfact = 0.5,
	},
})

hl.config({
	misc = {
		force_default_wallpaper = 0, -- 0 lets hyprpaper show; 1 forced anime wallpaper over it
		disable_hyprland_logo = true, -- old value kept (upstream example uses false)
	},
})

---------------
---- INPUT ----
---------------
hl.config({
	input = {
		kb_layout = "us,ara",
		kb_variant = "",
		kb_model = "",
		kb_options = "grp:alt_shift_toggle",
		kb_rules = "",

		follow_mouse = 1,
		sensitivity = 0,

		touchpad = {
			natural_scroll = true,
		},
	},
})

-- Old file had an empty gestures{} block; nothing to migrate.

-- Per-device config removed: epic-mouse-v1 not present
-- (hyprctl devices shows Dell mouse/touchpad only). Re-add when device exists:
-- hl.device({
--   name        = "epic-mouse-v1",
--   sensitivity = -0.5,
-- })

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Apps (old: F fullscreen 0 / T terminal / Q killactive / M exit / E files /
--          N neovide / R menu / D rofi run-shell / W browser / v clipboard picker)
-- NOTE: M used to be hl.dsp.exit() (instant logout, no confirm). Now routed
-- through wlogout like Escape to prevent accidental session loss.
local wlogout_cmd = os.getenv("HOME") .. "/.config/hypr/scripts/wlogout.sh"
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(wlogout_cmd))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("neovide"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("rofi -show drun -run-shell-command 'foot --hold {cmd}'"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + v", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/cliphist-rofi.sh"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(wlogout_cmd))

-- Lock screen (SHIFT: plain SUPER+L is workspace +1 below — letter binds are
-- case-insensitive, so SUPER+l and SUPER+L would both fire)
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

-- Core window management (were missing: floating/pseudo/pin/split/center)
-- NOTE: float is SHIFT+V because plain SUPER+V is the clipboard picker (same
-- reason as lock above). P/I/J/C have no lowercase twins, so single-mod.
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mainMod .. " + I", hl.dsp.window.pin({ action = "toggle" }))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + C", hl.dsp.window.center())

-- Move focus with mainMod + arrow keys (primary)
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
-- Vim-style focus alternative (CTRL avoids clashing with h/l workspace nav
-- below and J togglesplit above)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.focus({ direction = "right" }))

-- Switch workspace left/right (non-standard: vim users expect hjkl-focus here,
-- but arrows/CTRL+hjkl cover focus, so h/l stays as workspace nav)
hl.bind(mainMod .. " + l", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ workspace = "e-1" }))

-- Switch workspaces 1-10 / move window with SHIFT 1-0
-- (was ALT: Alt+Shift is the XKB layout toggle, so SUPER+ALT+num flipped
-- us<->ara while moving windows)
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move/resize with mouse drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- Old file had resize on mouse:273 commented out; enable if wanted:
-- hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness (old bindel = locked + repeating)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media keys (old bindl = locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Keyboard layout us <-> ara. PRIMARY: SUPER+SPACE bind below (XKB
-- grp:super_space_toggle is unreliable because Hyprland eats Super first).
-- BACKUP: Alt+Shift via kb_options above. Both stay active intentionally;
-- if you only want one, delete the other.
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))

-- Screenshots (ported from oldhypr/*.sh, now in ~/.config/hypr/scripts/)
-- Absolute paths: "~" does not reliably expand in exec_cmd.
hl.bind("Print", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot_full.sh"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot_area.sh"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- Dialogs/tools that must float instead of tiling (nm-applet, pavucontrol,
-- bluetooth, file-chooser portals).
hl.window_rule({
	name = "float-tools",
	match = { class = "^(nm-applet|Nm-applet|pavucontrol|blueman-manager|nm-connection-editor)$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "float-portals",
	match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland)$" },
	float = true,
	center = true,
})

--------------------------------
---- QUICKSHELL LAYER RULES ----
--------------------------------
-- Ported from quickshell's hyprland-layer-config.conf
hl.layer_rule({ name = "qs-blur", match = { namespace = "^(quickshell.*)$" }, blur = true })
hl.layer_rule({ name = "qs-ignore-alpha", match = { namespace = "^(quickshell.*)$" }, ignore_alpha = 0.3 })
hl.layer_rule({ name = "rofi-blur", match = { namespace = "rofi" }, blur = true, blur_popups = true })
hl.layer_rule({ name = "rofi-ignore-alpha", match = { namespace = "rofi" }, ignore_alpha = 0 })
hl.layer_rule({ name = "wlogout-blur", match = { namespace = "logout_dialog" }, blur = true, blur_popups = true })
hl.layer_rule({ name = "wlogout-ignore-alpha", match = { namespace = "logout_dialog" }, ignore_alpha = 0 })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "default", style = "popin 80%" })
