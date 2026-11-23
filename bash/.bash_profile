#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# .NET SDK 11 from Microsoft's dotnet-install.sh in ~/.dotnet: Arch only ships
# .NET 10 and the game (Ypykuara global.json) pins 11.0.100. Set before
# Hyprland starts, so Godot and the IDEs see it too. When Arch packages
# .NET 11, remove this block and ~/.dotnet.
if [[ -x "$HOME/.dotnet/dotnet" ]]; then
    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
fi
# Do not send .NET CLI usage statistics to Microsoft.
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Start Hyprland on tty1 only. Other TTYs (tty2, tty3...) stay as plain
# consoles, so there is always a way to recover from a broken graphical session.
if [[ -z "${WAYLAND_DISPLAY:-}" && "${XDG_VTNR:-0}" -eq 1 ]]; then
    exec start-hyprland
fi