#!/usr/bin/env bash
# Super+D: first press opens the showcase (kitty session, class "showcase");
# a window rule in hyprland.lua puts it on special:showcase, which then shows
# up by itself. Later presses only show/hide it. Close it with Super+C.
if hyprctl clients -j | grep -q '"class": "showcase"'; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("showcase")'
else
    # More transparent than normal terminals (0.80 vs 0.90): it is for show.
    # Font 11 (not 13) so every pane gets enough rows: btop needs 80x24.
    setsid -f kitty --class showcase -o background_opacity=0.80 -o font_size=11 \
        --session ~/.config/kitty/showcase.session
fi
