#!/usr/bin/env bash
# Post-install bootstrap for the Arch + Hyprland setup.
# Usage: bash bootstrap/install.sh [--dry-run] [vm|loq]
# Safe to run more than once. Run it as your normal user (it uses sudo),
# from a TTY (not inside Hyprland).
# Disk, LUKS, bootloader and fstab are NOT done here: they are manual steps
# from the live ISO (bootstrap/notes/loq-install.md).
set -euo pipefail

DRY=false
PROFILE=""
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY=true ;;
        vm|loq) PROFILE="$arg" ;;
        *)
            printf 'Unknown argument: %q\n' "$arg" >&2
            echo "Usage: bash $0 [--dry-run] [vm|loq]" >&2
            exit 1
            ;;
    esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

step() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Run a command, or only print it in dry-run mode.
run() {
    if $DRY; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

# Run a command inside a directory (same dry-run behavior).
run_in() {
    local dir="$1"
    shift
    if $DRY; then
        printf '[dry-run] (cd %q &&' "$dir"
        printf ' %q' "$@"
        printf ')\n'
    else
        (cd "$dir" && "$@")
    fi
}

# Write a root-owned file (mode 644) with the given content.
write_root_file() {
    local dest="$1" content="$2" tmp
    if $DRY; then
        printf '[dry-run] write %s:\n%s\n' "$dest" "$content"
        return 0
    fi
    tmp="$(mktemp)"
    printf '%s\n' "$content" > "$tmp"
    sudo install -Dm644 "$tmp" "$dest"
    rm -f "$tmp"
}

# Copy every file under a directory to the same path under /.
install_tree() {
    local src="$1" f rel
    [[ -d "$src" ]] || return 0
    while IFS= read -r -d '' f; do
        rel="${f#"$src/"}"
        run sudo install -Dm644 "$f" "/$rel"
    done < <(find "$src" -type f -print0)
}

# Print the entries of a package list, skipping comments and blank lines.
read_list() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        warn "missing list: $file"
        return 0
    fi
    grep -vE '^\s*(#|$)' "$file" || true
}

[[ $EUID -ne 0 ]] || die "Run as your normal user, not root (the script calls sudo)."
command -v pacman >/dev/null || die "pacman not found: this script is for Arch Linux."
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && ! $DRY; then
    die "Run this from a TTY (Ctrl+Alt+F3), not inside Hyprland: the upgrade replaces Hyprland while it is running."
fi

if [[ -z "$PROFILE" ]]; then
    case "$(cat /etc/hostname)" in
        arch-hyprlab) PROFILE=vm ;;
        arch-loq)     PROFILE=loq ;;
        *) die "Unknown hostname. Pass the profile: bash $0 vm|loq" ;;
    esac
fi
echo "Profile: $PROFILE (dry-run: $DRY)"

# Ask for the sudo password once, up front.
$DRY || sudo -v

# ---------------------------------------------------------------- packages
step "Updating the system and installing packages"
mapfile -t PKGS < <(read_list "$HERE/pkgs-common.txt"; read_list "$HERE/pkgs-$PROFILE.txt")
((${#PKGS[@]})) || die "No packages found in the lists."
run sudo pacman -Syu
run sudo pacman -S --needed "${PKGS[@]}"

step "AUR packages"
mapfile -t AUR < <(read_list "$HERE/pkgs-aur.txt" | grep -vE -- '-debug$' || true)
if ((${#AUR[@]})); then
    if ! command -v yay >/dev/null; then
        warn "yay not found: building yay-bin from the AUR"
        tmp="$(mktemp -d)"
        run git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        run_in "$tmp/yay-bin" makepkg -si
    fi
    run yay -S --needed "${AUR[@]}"
fi

# ---------------------------------------------------------------- dotfiles
step "Linking dotfiles with GNU Stow"
cd "$REPO"
for dir in */; do
    pkg="${dir%/}"
    [[ "$pkg" == "bootstrap" ]] && continue
    # Real files that would block the links are moved to a backup folder.
    # Two message formats: older stow ("existing target is neither a link nor
    # a directory: FILE") and stow 2.4+ ("cannot stow ... over existing target
    # FILE since neither a link nor a directory and --adopt not specified").
    conflicts="$(stow --no-folding -n -d "$REPO" -t "$HOME" "$pkg" 2>&1 \
        | sed -n \
            -e 's/.*existing target is neither a link nor a directory: //p' \
            -e 's/.*over existing target \(.*\) since neither a link nor a directory.*/\1/p' \
        || true)"
    while IFS= read -r rel; do
        [[ -n "$rel" ]] || continue
        warn "moving existing ~/$rel to $BACKUP_DIR/"
        run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        run mv "$HOME/$rel" "$BACKUP_DIR/$rel"
    done <<< "$conflicts"
    run stow --no-folding -R -v -d "$REPO" -t "$HOME" "$pkg"
done

# ---------------------------------------------------------------- system files
# files/ is for every machine, files-<profile>/ only for that profile.
step "Installing system files (bootstrap/files and bootstrap/files-$PROFILE -> /)"
install_tree "$HERE/files"
install_tree "$HERE/files-$PROFILE"

# ---------------------------------------------------------------- autologin
# Only behind LUKS: the passphrase at boot already proves who you are.
if [[ "$PROFILE" == loq ]]; then
    step "Autologin on tty1"
    root_src="$(findmnt -no SOURCE /)"
    if [[ "$root_src" == /dev/mapper/cryptroot* ]]; then
        write_root_file /etc/systemd/system/getty@tty1.service.d/autologin.conf \
"[Service]
ExecStart=
ExecStart=-/sbin/agetty --noreset --noclear --autologin $USER - \${TERM}"
        run sudo systemctl daemon-reload
    else
        warn "/ is on '$root_src', not on /dev/mapper/cryptroot: autologin skipped (only safe behind LUKS)."
    fi
fi

# ---------------------------------------------------------------- services
step "Enabling services"
run sudo systemctl enable --now NetworkManager.service
run sudo systemctl enable --now fstrim.timer

if [[ -f /etc/snapper/configs/root ]]; then
    run sudo systemctl enable --now snapper-cleanup.timer
    run sudo systemctl disable --now snapper-timeline.timer
else
    warn "snapper 'root' config not found (/etc/snapper/configs/root): follow bootstrap/notes/snapper.md first."
fi

run systemctl --user enable --now pipewire pipewire-pulse wireplumber \
    || warn "could not enable the audio services (no user session?). Log in on a TTY and run: systemctl --user enable --now pipewire pipewire-pulse wireplumber"

if [[ "$PROFILE" == loq ]]; then
    # TLP replaces power-profiles-daemon; the TLP docs ask to mask systemd-rfkill.
    if pacman -Q power-profiles-daemon &>/dev/null; then
        warn "power-profiles-daemon is installed and conflicts with TLP. Remove it: sudo pacman -Rns power-profiles-daemon"
    fi
    run sudo systemctl enable --now tlp.service
    run sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
    run sudo systemctl enable --now bluetooth.service
    # Updates systemd-boot on the ESP at boot when the systemd package changed.
    run sudo systemctl enable systemd-boot-update.service
fi

step "Done"
echo "Reminders:"
echo " - snapper setup is manual: bootstrap/notes/snapper.md"
echo " - if the kernel was updated, reboot before starting Hyprland"
echo " - log in on tty1 to start Hyprland (the bash package does it)"
if [[ "$PROFILE" == loq ]]; then
    echo " - first boot tests: bootstrap/notes/loq-first-boot-tests.md"
    echo " - battery care: sudo tlp-stat -b (conservation mode, see files-loq/etc/tlp.d)"
fi
if [[ -d "$BACKUP_DIR" ]]; then
    echo " - files replaced by dotfile links were moved to: $BACKUP_DIR"
fi
