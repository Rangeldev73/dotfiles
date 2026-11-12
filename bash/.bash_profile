#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start Hyprland on tty1 only. Other TTYs (tty2, tty3...) stay as plain
# consoles, so there is always a way to recover from a broken graphical session.
if [[ -z "${WAYLAND_DISPLAY:-}" && "${XDG_VTNR:-0}" -eq 1 ]]; then
    exec start-hyprland
fi