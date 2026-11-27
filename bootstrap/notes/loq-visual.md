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
3. kitty + prompt + no bell (beep when deleting: readline bell, hypothesis).
4. Hyprland look: borders, gaps, corners, blur, animations.
5. waybar: clean-up, style, new modules (check that bluez is installed).
6. rofi: launcher, clipboard, power menu (new stow package).
7. Notifications: dunst or swaync (new stow package).
8. hyprlock + hypridle (into the autostart; no rgb:kbd_backlight on the LOQ;
   review the 30 min suspend) + keybind to lock the screen.
9. Showcase workspace (configs + script + keybind).
10. Apps: VS Code, IntelliJ, Godot (Display Scale), Chrome.
Optional, at the end: boot visuals (plymouth); touches the boot, decide then.

## Rules for every piece
- Start with a clean git tree; undo = git restore on the changed files.
- Keep a kitty open while testing; Hyprland reloads on save and shows errors
  in a red bar without killing the session.
- hyprlock tests: log in on TTY2 first, so a stuck lock can be killed.
- New stow packages are added to install.sh in the same commit.
- AUR packages not from the vendor: read the PKGBUILD before installing.
- One commit per finished piece (Conventional Commits, English).
