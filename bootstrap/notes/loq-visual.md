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

## Palette: Tokyo Night "Night", darkened
Base: Tokyo Night (folke/tokyonight.nvim extras, enkia's VS Code theme), so
kitty, btop, rofi, dunst, VS Code and IntelliJ can use ready-made ports.
- Desktop surfaces (bar, rofi, notifications, lock): the two darkest
  backgrounds of the palette (bg_dark / bg_dark1), not the default #1a1b26.
- Main accent: ice cyan #7dcfff (matches the bluearch wallpaper glow).
- Second accent: blue #7aa2f7 (selection, important text).
- Alert only: pink-red #f7768e (critical battery, high temperature, urgent
  workspace). Never used as decoration.
- Apps with a ready theme (VS Code, IntelliJ, btop, cava) keep the theme's own
  background; the small difference is accepted.
- Exact hex values are copied from the upstream palette when the first piece
  uses them (not from memory).

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
1. Wallpaper: bluearch or bluesea; hyprpaper or swww (check current name).
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
