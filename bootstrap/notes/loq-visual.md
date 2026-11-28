# LOQ visual: decisions and plan

Status (2026-11-26): plan agreed, nothing applied yet. Each piece below is
done, tested and committed on its own, in this order.

## Direction
- Style: "terminal/hacker". Near-black background, one accent colour,
  monospace font everywhere, thin borders, small corners (4 px), small gaps.
- Colour rule 60-30-10: ~60% dark background, ~30% slightly lighter surfaces,
  ~10% accent. Same accent, border width, corner radius and font in every
  piece (bar, windows, rofi, notifications, lock screen).
- Monitor scale stays 1 (sharp XWayland). Sizes are raised per app.

## Palette: GitHub Dark (Primer) + ice cyan accent
History: started on Tokyo Night (2026-11-26) and dropped the same day. Not
only its background (#1a1b26, red > green) but its text (#c0caf5 lavender),
blue (#7aa2f7 periwinkle), comments (#565f89) and keywords (#bb9af7) lean
violet. The goal is black + dark blue + light blue, no purple.

Base: GitHub Dark / Primer (kitty ships it as GitHub_Dark; VS Code has the
official "GitHub Theme"; JetBrains has GitHub theme plugins).
- Backgrounds:
    #010409  deepest  (header bars, GTK sidebar, waybar)
    #0d1117  base     (windows, views, terminal)
    #161b22  raised   (menus, dialogs, cards, popups)
    #30363d  border / inactive lines
  Pure #000000 was rejected: areas would merge into one block.
- Text: #c9d1d9 (main), #7d8590 (muted, comments).
- Accent (lines, borders, prompt, cursor): ice cyan #7dcfff, the glow of the
  bluearch wallpaper. Blues: #58a6ff, #79c0ff (light), #a5d6ff (strings).
- Filled selection: #1f6feb with white text. A #7dcfff fill with Thunar's
  light text measured 1.06:1 (unreadable).
- Alerts only: red #ff7b72 (fill #da3633). Success #3fb950, warning #d29922.
- Apps with a ready theme (VS Code, IntelliJ, btop) use their GitHub Dark port.

## Layout decisions
- Bar: full width, flush to the top (not floating), thin (~28 px), solid dark
  background with a 1 px bottom line.
  Left: workspaces, music (mpris, only when playing).
  Centre: time and date.
  Right: CPU, RAM, temperature, Wi-Fi, Bluetooth, volume, battery, idle
  inhibitor, tray, power menu.
  Removed: mpd, keyboard language (only br), power-profiles-daemon (TLP is
  used), battery#bat2. Never poll nvidia-smi from the bar.
- Windows: border 2 px, active = solid ice cyan (no gradient), inactive almost
  invisible; corners 4 px; gaps 4 inside / 8 outside; short, fast animations.
- Terminal (kitty): ~90% opacity with light blur. IDEs and browser stay solid.
  If blur costs battery, turn it off on battery (to test).
- Font: JetBrains Mono Nerd Font everywhere, GTK interface included.
- Icons: Papirus-Dark. Cursor: theme chosen in piece 2.
- Showcase workspace: fastfetch, big clock, cava, btop, cmatrix in the palette,
  opened by a keybind. Not running all the time (cava/cmatrix redraw nonstop
  and cost CPU and battery).

## Pieces, in order
0. This file.
1. Wallpaper (done 2026-11-26): bluearch.png, drawn by hyprpaper (autostart
   in hyprland.lua, config hyprpaper.conf). swww was renamed awww (extra);
   not needed for a static wallpaper. The image is NOT in the repo (public
   repo, third-party art): it lives in ~/Pictures/Wallpapers/ and
   ~/Pictures/Wallpapers/current is a symlink to it (verified: hyprpaper
   follows it, no file extension needed). Change it with
   ln -sfn <image> ~/Pictures/Wallpapers/current and restart hyprpaper.
   bluesea is kept for later; looking for a better wallpaper someday.
2. Base: GTK/Qt font and size, dark theme, icons, cursor (new stow package).
3. kitty + prompt (done 2026-11-26): kitty package (kitty.conf +
   loq-colors.conf, GitHub Dark 16 colours), JetBrainsMono Nerd Font 13 pt
   (tested 12 and 14, settled on 13), opacity 0.90, padding 10.
   Fonts compared with real renders: JetBrains Mono kept (same as GTK and
   IntelliJ); Iosevka Term (narrow, huge package) and Geist Mono rejected.
   Prompt: Starship (starship package, one info line + input line); bash
   package now versions .bashrc (old one in ~/.dotfiles-backup/).
   Bell: verified gone with enable_audio_bell no (Backspace on empty prompt).
4. Hyprland look (done 2026-11-26): style "B, balanced" in
   hypr/.config/hypr/theme.lua (hyprland.lua only does require("theme")):
   gaps 4/8, border 2 px solid #7dcfff active / #30363d inactive, rounding 4,
   no shadow, blur size 4 passes 2, short animations without bounce
   (0.15-0.2 s). Rejected: A (1 px border, hard to see the active window),
   C (cyan glow = coloured shadow, extra GPU, "islands" look).
   Touchpad: 3-finger horizontal swipe switches workspaces (hl.gesture in
   hyprland.lua, already there).
5. waybar (done 2026-11-26): style "A, solid strip" (#010409, 1 px line,
   active workspace cyan with underline). Left: workspaces, mpris. Centre:
   clock. Right: cpu, memory, temperature, network, bluetooth, pulseaudio,
   battery (BAT1), idle_inhibitor, tray, power menu (power_menu.xml). All bar
   texts and menu labels in English (changed from Portuguese on request). Removed: mpd, language, power-profiles-daemon, bat2,
   backlight, keyboard-state. Temperature: hwmon-name coretemp (the default
   acpitz board sensor read ~28 C; hwmonN numbers change between boots).
   Clicks: Wi-Fi -> nmtui, Bluetooth -> bluetui (extra), both in a floating
   kitty (class floating-tui, window rule in hyprland.lua); volume ->
   pavucontrol. Icons are Nerd Font glyphs coloured with Pango <span>.
   Rejected: B (pills, "islands" look), C (icons only, hides CPU/RAM numbers).
6. rofi (done 2026-11-26): rofi package, rofi 2.1.1. Launcher (Super+R) =
   style B, two panels: wallpaper on the left (themes/launcher.rasi), apps
   with Papirus icons on the right, apps/run/window buttons. Text lists =
   style A (themes/list.rasi), used by the clipboard (Super+Shift+V uses
   -theme list). Shared palette and item style: themes/loq-base.rasi.
   C (dmenu strip) rejected. The power menu stays in waybar.
   Wallpaper path is absolute (/home/rangel/...): rofi does not expand ~ or
   ${HOME} inside url() (tested; JPG and PNG both load). Old 52-byte
   ~/.config/rofi/config.rasi moved to ~/.dotfiles-backup/.
7. Notifications (done 2026-11-26): swaync replaces dunst (removed). swaync
   package: config.json (top right, 420 px pop-ups, 6 s / 4 s low / critical
   stays, side panel 460 px with title + Clear all, Do not disturb, list,
   mpris) and style.css with overrides only (verified in swaync v0.12.6
   source: the packaged CSS loads first, the user CSS on top). Cyan border,
   red for critical. Waybar bell (custom/notification, from the swaync
   README): click = panel, right click = Do not disturb (bell turns red).
   Plain dunst rejected: no history, no one-click Do not disturb.
8. Lock and idle (done 2026-11-26):
   - hyprlock.conf, style "C, side panel" (same family as the rofi launcher):
     640 px #0d1117 panel + cyan divider over the "current" wallpaper (full
     path), 24 h clock, English date (LC_TIME=C), user/host/wm/battery lines,
     password field cyan / blue while checking / red on failure. Rejected:
     A (blurred wallpaper, centred clock), B (sharp wallpaper, corner clock).
   - hypridle.conf, profile "B, balanced": dim 5 min, lock 10, screen off 11,
     suspend 20 only on battery (scripts/suspend-on-battery.sh reads
     /sys/class/power_supply/ACAD/online). Lock before sleep/lid close.
     No kbd_backlight listener (does not exist on the LOQ). Started from the
     hyprland.lua autostart; the waybar coffee pauses it.
   - Super+L locks (pidof hyprlock || hyprlock).
   - Tested with a TTY2 login open; rescue: pkill -USR1 hyprlock (unlocks).
9. Showcase (done 2026-11-26): Super+D (scripts/showcase.sh) opens one kitty
   (class "showcase", opacity 0.80, font 11) on special:showcase via a window
   rule (not "silent", so the first press shows it); later presses show/hide,
   Super+C closes. Layout from kitty/showcase.session (splits): fastfetch over
   btop | clock over cmatrix over cava. Lessons: kitty session arguments do
   not expand ~ (clock runs through bash); --next-to does not work in session
   files, use focus_matching_window (kitty docs pattern); cmatrix paints with
   colour 0 (grey in GitHub Dark), so that pane gets --color color0=bg; btop
   needs at least 80x24. Clock: own block-digit script
   (scripts/showcase-clock.sh); figlet tried and dropped (looked bad),
   tty-clock / clock-rs are AUR only. Packages fastfetch, btop (loq.theme),
   cava (30 fps, blue-cyan gradient). decoration.dim_special = 0.
10. Apps:
   - VS Code (done 2026-11-26): settings.json versioned in the vscode package
     (rewritten from the old Windows-synced one, backup in
     ~/.dotfiles-backup/vscode/). GitHub Dark Default theme
     (GitHub.github-vscode-theme), JetBrainsMono Nerd Font 14 + ligatures,
     terminal Nerd Font 13 (Starship icons), custom title bar, menu on Alt,
     no minimap, sticky scroll, trim whitespace on save, telemetry off.
     Python formatting moved to Ruff (charliermarsh.ruff): the old
     "ms-python.python" formatter setting did nothing. Godot path
     /usr/bin/godot-mono. Settings Sync: turn off "Settings" so sync does
     not bring the old Windows settings back.
   - IntelliJ (done 2026-11-27, not versioned: config dir has the version in
     its name and mixes state/licence; use JetBrains Backup and Sync).
     Plugin "GitHub Primer Theme" (Toby Johnson, id Intellij_GitHub_Dark_Theme,
     #0d1117 base) with theme + editor scheme "GitHub Dark Islands"
     (options/laf.xml themeId intellij_github_dark_islands_theme,
     options/colors.scheme.xml). Removed: "GitHub Theme" (bhushan, #252526
     grey UI, unmaintained since 2024) and "GitHub Primer Dark Color Scheme"
     (2020, #24292e). Editor font JetBrains Mono 14, line 1.5, ligatures.
     Pending: Project SDK -> JDK 25 when Java work resumes.
   - Godot (done 2026-11-27, editor settings only, not the project):
     ~/.config/godot/editor_settings-4.7.tres: display_scale 3 (125%),
     theme color_preset "Custom", base #0d1117, accent #58a6ff (blue rather
     than cyan: the accent is used on many small items). Godot 4.7 key names:
     interface/editor/appearance/display_scale, interface/theme/color_preset.
     The grey 2D viewport is the project's default_clear_color (left alone).
   - Chrome (done 2026-11-27, via menu in each of the 3 profiles):
     chrome://settings/appearance -> Theme GTK (uses gtk.css), mode follows
     the system (prefer-dark), page zoom 110%. Not edited by file: Chrome
     signs parts of Preferences (Secure Preferences) and reverts outside edits.
Optional, at the end: boot visuals (plymouth); touches the boot, decide then.

## Rules for every piece
- Start with a clean git tree; undo = git restore on the changed files.
- Keep a kitty open while testing; Hyprland reloads on save and shows errors
  in a red bar without killing the session.
- hyprlock tests: log in on TTY2 first, so a stuck lock can be killed.
- New stow packages are added to install.sh in the same commit.
- AUR packages not from the vendor: read the PKGBUILD before installing.
- One commit per finished piece (Conventional Commits, English).
