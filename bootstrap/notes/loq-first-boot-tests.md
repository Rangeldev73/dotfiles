# LOQ first boot: tests on the real hardware

Results from 2026-11-21 (Arch installed with loq-install.md).

- [x] kitty opens without LIBGL_ALWAYS_SOFTWARE (gl_prefix = "").
- [x] Polkit agent: pkexec true shows the graphical window; log says
      "registered polkit agent for session 1". The VM problem does not happen.
- [x] hyprlock locks and unlocks (it was missing from the package lists;
      hyprlock and hypridle added to pkgs-common.txt). Default screenshot
      background: not tried yet (visual chat).
- [x] Screenshots (Shift+Print to ~/Pictures/Screenshots) and clipboard
      history (Super+Shift+V).
- [x] Waybar: battery, backlight and temperature modules show up.
- [x] kb_layout "br" matches the physical ABNT2 keyboard.
- [x] Monitor eDP-1 at 1920x1080@144 (modes: 144 Hz and 60 Hz); "preferred"
      already picks 144 Hz.
- [x] Brightness (nvidia_wmi_ec_backlight) and volume keys.
- [x] Wi-Fi selection: nm-applet --indicator in the waybar tray (added
      2026-11-22; before that only nmtui/nmcli in a terminal).
- [x] Hibernate and resume (session back after the LUKS passphrase).
- [x] Snapper: pacman creates pre/post snapshots; /.bootbackup holds /boot.
- [x] TLP: AC -> balanced, battery -> low-power; conservation mode (Long_Life).
- [ ] NVIDIA idle power: runtime D3 not available (see loq-design.md, GPU).
- [x] prime-run with a real app (2026-11-23): godot-mono alone uses
      "Mesa Intel(R) Graphics (RPL-S)"; prime-run godot-mono uses "NVIDIA GeForce
      RTX 4050 Laptop GPU" (OpenGL, driver 620.73.04). Steam game through
      Proton with prime-run %command% also on the RTX 4050 (2026-11-23).
- [x] Monitor scale: "auto" picked 1.5 and blurred XWayland apps (Godot);
      set scale = 1 in machines/arch-loq.lua (2026-11-23).
- [ ] External monitor on HDMI (needs the second drm_devices line).
- [ ] Conservation cap percentage (watch where charging stops).
- [ ] GitHub over port 443 on the university network (eduroam blocks port 22):
      ssh -T git@github.com (uses ~/.ssh/config -> ssh.github.com:443), then
      git push from ~/dotfiles. Verified at home on 2026-11-21.
