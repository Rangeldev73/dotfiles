# LOQ keybinds cheat sheet

Source of truth: hypr/.config/hypr/hyprland.lua (KEYBINDINGS section),
kitty defaults, rofi defaults, waybar config.jsonc. Checked 2026-11-27.
Super = the Windows key.

## Hyprland: apps and session

| Keys | Action |
|---|---|
| Super+Q | Terminal (kitty) |
| Super+R | App launcher (rofi, two panels) |
| Super+E | File manager (Thunar) |
| Super+C | Close the active window |
| Super+L | Lock the screen (hyprlock) |
| Super+D | Showcase dashboard: first press opens, then show/hide (close with Super+C) |
| Super+Shift+V | Clipboard history (rofi list) |
| Super+M | **Exit Hyprland** (logs out; autologin starts it again). Save work first! |

## Hyprland: windows

| Keys | Action |
|---|---|
| Super+Arrows | Move focus left/right/up/down |
| Super+V | Toggle floating for the active window |
| Super+J | Toggle split direction (dwindle) |
| Super+P | Pseudo-tile |
| Super+left mouse drag | Move a window |
| Super+right mouse drag | Resize a window |

## Hyprland: workspaces

| Keys | Action |
|---|---|
| Super+1..9, Super+0 | Go to workspace 1..9, 10 |
| Super+Shift+1..0 | Move the active window to workspace 1..10 |
| Super+mouse wheel | Next / previous workspace |
| 3-finger horizontal swipe | Next / previous workspace (touchpad) |
| Super+S | Show/hide the scratchpad (special:magic) |
| Super+Shift+S | Send the active window to the scratchpad |

## Hyprland: screenshots and media

| Keys | Action |
|---|---|
| Print | Screenshot of a selected area (saved in ~/Pictures/Screenshots, copied) |
| Shift+Print | Screenshot of the whole screen (saved and copied) |
| Volume / mute / mic keys | Volume (wpctl), work even on the lock screen |
| Brightness keys | Screen brightness (brightnessctl) |
| Media keys | Play/pause, next, previous (playerctl) |

## kitty (defaults)

| Keys | Action |
|---|---|
| Ctrl+Shift+C / Ctrl+Shift+V | Copy / paste |
| Ctrl+Shift+= / Ctrl+Shift+- | Font size +2 / -2 pt (this window) |
| Ctrl+Shift+Backspace | Reset font size |
| Ctrl+Shift+F5 | Reload kitty.conf |
| Ctrl+Shift+Enter | New split inside the same kitty window |
| Ctrl+Shift+T | New tab |

## rofi

| Keys | Action |
|---|---|
| Type | Filter |
| Enter | Open / pick |
| Ctrl+Tab | Next mode (apps -> run -> window) |
| Esc | Close |

## Waybar clicks

| Where | Click |
|---|---|
| Wi-Fi | nmtui in a floating terminal |
| Bluetooth | bluetui in a floating terminal |
| Volume | pavucontrol (scroll changes volume) |
| Coffee | Pause / resume auto-lock (hypridle) |
| Bell | Notification panel; right click = Do not disturb |
| Power | Menu: Lock, Suspend, Hibernate, Log out, Reboot, Shut down |

## Lock screen (hyprlock)

| Keys | Action |
|---|---|
| Type password + Enter | Unlock |
| Esc | Clear the typed password |
| Rescue (from TTY2, Ctrl+Alt+F2) | pkill -USR1 hyprlock |

## Two computers, one repo (habit)

Start working on a machine: git pull. Finish: git commit and git push.
