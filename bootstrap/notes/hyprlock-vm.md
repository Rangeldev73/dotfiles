# hyprlock in the VirtualBox VM (parked)

Status: crashes when locking in the VM. Revisit on the LOQ.

Setup: hyprlock 0.9.6, Hyprland 0.56.2, VirtualBox VMSVGA with 3D acceleration.

What we saw:
- "Disconnected from pollfd id 0" is generic: the compositor closed the
  Wayland connection (hyprpaper prints the same message).
- Default config (background path = screenshot): crash with a zwlr_screencopy
  "invalid arguments" protocol error.
- Solid-color configs (minimal, with labels, with the custom input field):
  crash at "Starting fade in". One minimal solid-color test had worked before.
- --immediate-render --no-fade-in, with and without LIBGL_ALWAYS_SOFTWARE=1:
  still crashes.
- Never checked: Hyprland-side log (hyprctl rollinglog) after the crash.
- Test configs: bootstrap/tests/lock-a.conf, lock-b.conf, lock-c.conf.

On the LOQ:
1. Run hyprlock by hand first, with a second TTY logged in
   (pkill Hyprland to recover a stuck locked session).
2. Only then add hypridle to the autostart in hyprland.lua.
3. Install brightnessctl; hypridle.conf is still the stock sample
   (it suspends after 30 minutes).
4. If hyprlock still crashes, pick another lock screen.