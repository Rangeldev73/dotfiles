# LOQ 15IRX9: install guide (live ISO -> first Hyprland session)

Decisions behind every step: loq-design.md. Hardware: loq-hardware.md.
Rules while following this guide:
- One step at a time; paste the output before the next step.
- Steps marked [DESTRUCTIVE] need an explicit "yes" first: they erase data.
- In the live ISO, /dev/sda is the USB stick and /dev/nvme0n1 is the SSD.
  Run lsblk before every destructive step and check the model and size.
- Config files during the install are written with printf one-liners
  (copy and paste), not edited by hand. Dotfiles come from the repo later.
- Linux user: rangel.

## Phase 0: before booting (Windows PC)
- LUKS passphrase chosen (4-5 random words) and written on paper, kept away
  from the laptop. User password chosen (different).
- Charger connected. Ethernet cable if possible (r8169, enp7s0), else Wi-Fi.
- If ssh complains about a changed host key (every live boot makes a new one):
  ssh-keygen -R <IP>   (on Windows, then ssh again)

## Phase 1: live ISO, keyboard, network, SSH
1. Boot the USB stick (F12 boot menu). Secure Boot stays off.
2. Keyboard (on the laptop): loadkeys br-abnt2
   Test it: type the characters you plan to use in the LUKS passphrase.
   If they come out wrong, try another layout before going on: the same
   layout goes into /etc/vconsole.conf (Phase 6) for the boot prompt.
3. Network: Ethernet works alone. Wi-Fi: iwctl station wlan0 connect "SSID"
   Check: ping -c 3 archlinux.org
4. SSH: passwd (temporary root password, live session only), then
   ip -brief addr   -> on Windows: ssh root@<IP>
5. Checks (paste the output):
   cat /sys/firmware/efi/fw_platform_size   (want 64)
   timedatectl                               (want "System clock synchronized: yes")

## Phase 2: identify the disks (read-only)
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,MOUNTPOINTS
Expected: nvme0n1 476.9G SK hynix (HFS512GEJ4X112N), sda = the USB stick.
Stop if it does not match.

## Phase 3: partition the SSD [DESTRUCTIVE: erases the whole SSD]
Risk: the factory Linux ("lux") is erased for good. That is planned; there is
no undo. The USB stick is not touched.
wipefs -a /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/nvme0n1p3 /dev/nvme0n1p4 /dev/nvme0n1p5 /dev/nvme0n1p6
sgdisk --zap-all /dev/nvme0n1
sgdisk -n1:0:+2GiB -t1:ef00 -c1:EFI -n2:0:0 -t2:8309 -c2:cryptroot /dev/nvme0n1
partprobe /dev/nvme0n1
lsblk -o NAME,SIZE,TYPE,PARTLABEL /dev/nvme0n1
Expected: nvme0n1p1 2G (EFI), nvme0n1p2 about 474.9G (cryptroot).

## Phase 4: LUKS2 [DESTRUCTIVE on nvme0n1p2]
Check the keyboard layout from Phase 1 is still loaded before typing.
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
  (type YES in capitals, then the passphrase twice)
cryptsetup open --allow-discards --persistent /dev/nvme0n1p2 cryptroot
cryptsetup luksDump /dev/nvme0n1p2 | grep -i flags     (want allow-discards)
Header backup (the live /root is in RAM):
cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file /root/luks-header-loq.img
On Windows (new terminal): scp root@<IP>:/root/luks-header-loq.img .
Keep that file off the laptop (pendrive or cloud). It unlocks with the
passphrase that existed when it was made.
Undo before Phase 5: cryptsetup close cryptroot and run luksFormat again.

## Phase 5: Btrfs, subvolumes, ESP, swapfile [DESTRUCTIVE: formats]
mkfs.btrfs -L arch /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@ /mnt/@home /mnt/@log /mnt/@pkg /mnt/@snapshots /mnt/@swap
umount /mnt
O=noatime,compress=zstd:1
mount -o $O,subvol=@ /dev/mapper/cryptroot /mnt
mount --mkdir -o $O,subvol=@home /dev/mapper/cryptroot /mnt/home
mount --mkdir -o $O,subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount --mkdir -o $O,subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount --mkdir -o $O,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount --mkdir -o $O,subvol=@swap /dev/mapper/cryptroot /mnt/swap
mkfs.fat -F 32 -n EFI /dev/nvme0n1p1
mount --mkdir -o fmask=0077,dmask=0077 /dev/nvme0n1p1 /mnt/boot
btrfs filesystem mkswapfile --size 20g --uuid clear /mnt/swap/swapfile
findmnt -R /mnt
Notes: Btrfs mount options apply to the whole filesystem, so @swap also shows
compress=zstd:1; mkswapfile marks the swapfile NOCOW and uncompressed, which
is what swap needs. fmask/dmask keep /boot private (systemd-boot warns
about a world-readable random seed otherwise).

## Phase 6: base system
Optional, faster mirrors: reflector --country Brazil --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs networkmanager sudo neovim git
genfstab -U /mnt >> /mnt/etc/fstab
printf '/swap/swapfile none swap defaults 0 0\n' >> /mnt/etc/fstab
cat /mnt/etc/fstab   (paste it: check subvol= on each Btrfs line and the swap line)

arch-chroot /mnt
ln -sf /usr/share/zoneinfo/America/Araguaina /etc/localtime
hwclock --systohc
printf 'en_US.UTF-8 UTF-8\npt_BR.UTF-8 UTF-8\n' >> /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=br-abnt2\n' > /etc/vconsole.conf      (the layout chosen in Phase 1)
printf 'arch-loq\n' > /etc/hostname
(America/Araguaina is the Tocantins time zone. System messages in English:
easier to search errors; pt_BR is generated for apps that want it.)

Users:
passwd                                   (root password, for the emergency shell)
useradd -m -G wheel rangel
passwd rangel
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel
visudo -c                                (want "parsed OK")

Initramfs (systemd hooks + LUKS):
printf 'HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)\n' > /etc/mkinitcpio.conf.d/10-loq.conf
mkinitcpio -P
lsinitcpio /boot/initramfs-linux.img | grep -E 'systemd-cryptsetup|vconsole'
(want both: the unlock tool and the keymap are inside the initramfs)

## Phase 7: bootloader (systemd-boot) [changes the firmware boot entries]
Risk: adds a "Linux Boot Manager" entry to the NVRAM. Undo: efibootmgr -b <num> -B.
bootctl install
printf 'default arch.conf\ntimeout 3\neditor no\n' > /boot/loader/loader.conf
UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
OPTS="rd.luks.name=$UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw"
printf 'title Arch Linux\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img\noptions %s\n' "$OPTS" > /boot/loader/entries/arch.conf
printf 'title Arch Linux (fallback)\nlinux /vmlinuz-linux\ninitrd /initramfs-linux-fallback.img\noptions %s\n' "$OPTS" > /boot/loader/entries/arch-fallback.conf
cat /boot/loader/entries/arch.conf
bootctl list
(No intel-ucode initrd line: the microcode hook puts it in the initramfs.)

systemctl enable NetworkManager.service systemd-boot-update.service
exit
umount -R /mnt
cryptsetup close cryptroot
reboot   (remove the USB stick when the screen goes black)

## Phase 8: first boot
1. Passphrase prompt (keyboard test). Log in as rangel on tty1.
2. Wi-Fi if needed: nmcli device wifi connect "SSID" --ask
3. Remove the factory NVRAM entry: efibootmgr (paste the list), then
   sudo efibootmgr -b 0003 -B   (only after confirming 0003 is still "lux")
4. Dotfiles (HTTPS, read-only until the SSH key exists):
   git clone https://github.com/Rangeldev73/dotfiles.git ~/dotfiles
   cd ~/dotfiles && bash bootstrap/install.sh --dry-run   (paste the output)
   bash bootstrap/install.sh
5. Snapper: bootstrap/notes/snapper.md, section "LOQ (fresh install)",
   then run install.sh again (it enables the snapper timers).
6. reboot: passphrase -> autologin -> Hyprland.

## Phase 9: tests on the real hardware (one at a time, results into the notes)
- Hibernate: systemctl hibernate, power on, passphrase, session is back.
- loq-first-boot-tests.md (kitty, polkit, hyprlock, waybar, keys, 144 Hz).
- GPU: NVIDIA runtime_status "suspended" when idle; prime-run works.
- TLP: sudo tlp-stat -b and -p; conservation cap percentage.
- Brightness via nvidia_wmi_ec_backlight; external HDMI.
- Snapshot: a pacman install creates pre/post snapshots (snapper list).

## Later (separate chats)
1. Git/GitHub: SSH key, git config, switch the dotfiles remote to SSH.
2. Dev tools: IntelliJ, VS Code, Docker, JDK, C/C++ toolchain, .NET (C# for
   Godot), Python, Godot (pkgs-dev list, decided item by item).
3. Visual (dark blue and black, JetBrains Mono Nerd Font), piece by piece.
4. Optional: Secure Boot (sbctl), TPM unlock, zram, Steam (multilib).
