#!/usr/bin/env bash
# Copy the GTK look from ~/.config/gtk-3.0/settings.ini (gtk stow package)
# into gsettings, which GTK apps and the GTK file chooser portal read on
# Wayland. Run from the Hyprland autostart; safe to run again by hand.
set -euo pipefail

ini="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
schema="org.gnome.desktop.interface"

# Value of a key in the ini file (empty if missing).
get() { sed -n "s/^$1=//p" "$ini" | head -n 1; }

set_if() {
    local key="$1" value="$2"
    [[ -n "$value" ]] && gsettings set "$schema" "$key" "$value"
}

set_if gtk-theme    "$(get gtk-theme-name)"
set_if icon-theme   "$(get gtk-icon-theme-name)"
set_if cursor-theme "$(get gtk-cursor-theme-name)"
set_if cursor-size  "$(get gtk-cursor-theme-size)"
set_if font-name    "$(get gtk-font-name)"
# Dark variant for GTK 4 / libadwaita apps.
gsettings set "$schema" color-scheme prefer-dark
