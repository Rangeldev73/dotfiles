# Polkit agent in the VM (parked)

Status: the graphical password window does not appear when hyprpolkitagent is
started by the Hyprland autostart in the VM. Retest on the LOQ.

Facts:
- Started by hand from kitty (env LIBGL_ALWAYS_SOFTWARE=1): the window appears
  and the request completes.
- Started by the autostart (also with a 3 s delay): process alive, correct
  environment (WAYLAND_DISPLAY, session id, software GL), inside the session
  scope cgroup, but its log never shows an authentication request and pkexec
  falls back to the terminal prompt.
- It worked through the autostart on 2026-10-08, when Hyprland was started by
  hand. Since then Hyprland starts from ~/.bash_profile (bash package) and the
  per-machine layer was added. Cause not found.
- polkitd runs with --log-level=notice, so agent registrations probably are not
  shown in the journal (not tested at a more detailed level).
- Only hyprpolkitagent is running; polkit-kde-agent is installed but not
  running, so it is not the cause.
- The terminal prompt of pkexec rejected the password while sudo accepted it.
  Unexplained.

If it persists on the LOQ:
- Start the agent through the systemd user unit shipped by the package
  (hyprpolkitagent.service).
- Compare with starting Hyprland by hand on tty2.

Workaround meanwhile: use sudo in a terminal for privileged actions.