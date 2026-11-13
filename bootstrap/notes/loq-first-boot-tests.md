# LOQ first boot: tests to repeat on the real hardware

Run one at a time and note the result.

- [ ] kitty opens without LIBGL_ALWAYS_SOFTWARE (gl_prefix = "" in
      machines/arch-loq.lua).
- [ ] Polkit agent: pkexec true shows the graphical window (see polkit-vm.md).
- [ ] hyprlock: run by hand with a second TTY logged in (see hyprlock-vm.md),
      then try the default screenshot background.
- [ ] Screenshots (grim/slurp) and clipboard history work.
- [ ] Waybar: battery name, backlight and temperature modules show up.
- [ ] kb_layout matches the physical keyboard.
- [ ] Monitor name and refresh rate (hyprctl monitors), 144 Hz.
- [ ] Brightness and volume keys.