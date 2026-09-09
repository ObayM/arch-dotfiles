local mod = "SUPER"
local terminal = "kitty"
local file_manager = "dolphin"

hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
        col = {
            active_border = "#89b4fa",
            inactive_border = "#313244",
        },
    },
    decoration = {
        rounding = 8,
        blur = { enabled = true, size = 6, passes = 2 },
        shadow = { enabled = true, range = 12 },
    },
    input = {
        kb_layout = "us,ara",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

hl.curve("smooth", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "smooth", style = "slide" })

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c mine")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

hl.bind(mod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + M", hl.dsp.exit())

for key, direction in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

for i = 1, 9 do
    hl.bind(string.format("%s + %d", mod, i), hl.dsp.focus({ workspace = i }))
    hl.bind(string.format("%s + SHIFT + %d", mod, i), hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for key, command in pairs({
    XF86AudioRaiseVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
    XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    XF86MonBrightnessUp = "brightnessctl set 5%+",
    XF86MonBrightnessDown = "brightnessctl set 5%-",
}) do
    hl.bind(key, hl.dsp.exec_cmd(command), { repeating = true, locked = true })
end

hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })

pcall(dofile, os.getenv("HOME") .. "/.config/hypr/local.lua")
