-- Look of the Hyprland windows (loaded by hyprland.lua with require("theme")).
-- Style "B, balanced": square-ish corners, small gaps, 2 px border, solid ice
-- cyan on the active window, no shadow, light blur, short animations.
-- Palette and reasons: bootstrap/notes/loq-visual.md (piece 4).
-- Hyprland reloads this on save; errors show in a red bar, session survives.

local c = {
    accent = "rgba(7dcfffff)", -- ice cyan (active border)
    border = "rgba(30363dff)", -- GitHub Dark border (inactive)
}

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = c.accent,
            inactive_border = c.border,
        },
    },

    decoration = {
        rounding       = 4,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- No shadow: saves GPU work, fits the flat terminal style.
        shadow = {
            enabled = false,
        },

        -- Light blur behind transparent windows (kitty at 0.90).
        blur = {
            enabled  = true,
            size     = 4,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Short animations without bounce (speed is in tenths of a second).
hl.curve("snappy", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0},    {1, 1}   } })

hl.animation({ leaf = "global",     enabled = true, speed = 2,   bezier = "snappy" })
hl.animation({ leaf = "border",     enabled = true, speed = 2,   bezier = "snappy" })
hl.animation({ leaf = "windows",    enabled = true, speed = 2,   bezier = "snappy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 2,   bezier = "snappy", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear", style = "popin 95%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1.5, bezier = "snappy" })
hl.animation({ leaf = "layers",     enabled = true, speed = 1.5, bezier = "snappy", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2,   bezier = "snappy", style = "slide" })
