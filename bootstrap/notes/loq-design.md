# LOQ 15IRX9 design: decisions and reasons

Status (2026-11-21): installed and verified on the LOQ (see loq-install.md and
loq-first-boot-tests.md). Items marked "Hypothesis" or "untested" are still open. Hardware facts live in
loq-hardware.md (verified on the live ISO). This file supersedes the older
checklist in loq-partition-and-power.md (ESP 1 GiB, "swap partition or file").

## Decisions (2026-11-21)
- Disk encryption: LUKS2 with a passphrase only (no TPM for now).
  Reason: personal laptop that leaves home and hibernates; without LUKS anyone
  can boot a USB stick and read the disk, including the hibernation image (RAM).
  TPM unlock can be added later without reinstalling (systemd-cryptenroll,
  needs the sd-encrypt hook, which we use).
- Login: autologin on tty1 (getty drop-in). At boot only the LUKS passphrase is
  typed; Hyprland starts from ~/.bash_profile (bash stow package).
  The user password is still used by sudo, hyprlock and polkit.
  LUKS passphrase and user password are different; the LUKS passphrase is
  written on paper and kept away from the laptop.
- Initramfs: systemd-based (mkinitcpio default since v40), sd-encrypt + sd-vconsole.
- Resume from hibernation: handled by systemd (HibernateLocation EFI variable).
  No resume= and no resume_offset= on the kernel command line.
- Secure Boot: off for now (switched off in the BIOS on 2026-11-21).
  Possible later project, after a snapshot: sbctl enroll-keys -m (keep the
  Microsoft keys), a UKI, maybe TPM + systemd-pcrlock. Hypothesis to test then:
  the Arch kernel does not enable lockdown by itself with Secure Boot, so
  hibernation keeps working (check: cat /sys/kernel/security/lockdown).
- Bootloader: systemd-boot on the ESP mounted at /boot.
  Trade-off: no boot-to-snapshot menu (that is a GRUB + grub-btrfs feature);
  a full rollback is done from the live USB.

## Partitions (NVMe: /dev/nvme0n1)
The live USB is /dev/sda: never touch it. Check both with lsblk before any
destructive command. The factory layout (no LUKS) is wiped completely.
1. nvme0n1p1: ESP, 2 GiB, FAT32, type EF00, mounted at /boot.
   Holds systemd-boot, kernel and initramfs (fallback included; NVIDIA makes
   the initramfs bigger). Outside Btrfs, so keep the /boot backup hook.
2. nvme0n1p2: rest of the disk, LUKS2, opened as /dev/mapper/cryptroot,
   formatted as one Btrfs.
No Windows and no separate swap partition.

Btrfs subvolumes and mount points (options: noatime,compress=zstd:1):
- @          /
- @home      /home
- @log       /var/log
- @pkg       /var/cache/pacman/pkg
- @snapshots /.snapshots
- @swap      /swap (never snapshotted)
- @docker    /var/lib/docker (volumes, containers; added 2026-11-23)
- @containerd /var/lib/containerd (images, containerd image store; added 2026-11-23)
@docker and @containerd keep Docker data out of root snapshots and rollbacks.
Btrfs mount options are per filesystem, so @swap gets the same options;
mkswapfile marks the swapfile NOCOW and uncompressed. Steps: loq-install.md.

After the install: the factory NVRAM entry Boot0003 "lux" survives the wipe.
Remove it with efibootmgr (show the list first, confirm the number).

## LUKS2
- Format: cryptsetup luksFormat --type luks2 (defaults: argon2id, aes-xts).
- Header backup right after formatting: cryptsetup luksHeaderBackup, file
  copied off the laptop. Without the header, the passphrase is useless.
- Keymap: /etc/vconsole.conf must have the right KEYMAP before building the
  initramfs, because the passphrase is typed inside it (sd-vconsole).
  Hypothesis: br-abnt2. Check the physical keyboard in the live ISO first.
- Root password: set it, so the systemd emergency shell can be used if the
  boot fails. Otherwise recovery is from the live USB (cryptsetup open, mount).
- TRIM: dm-crypt blocks discards by default. Decided (2026-11-21): allow them,
  stored in the LUKS2 header (cryptsetup refresh --allow-discards --persistent
  cryptroot), and keep fstrim.timer. Trade-off accepted: an attacker can see
  which blocks are free, not their content.

## Initramfs and boot entry
mkinitcpio HOOKS (keymap is not needed with sd-vconsole; microcode embeds
intel-ucode in the initramfs, so no separate initrd line for it):
  HOOKS=(base systemd autodetect microcode modconf keyboard sd-vconsole block sd-encrypt filesystems fsck)
Kernel options in the systemd-boot entry:
  rd.luks.name=<UUID of nvme0n1p2>=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
Final HOOKS on the LOQ have no kms (see GPU); the file is versioned in
files-loq/etc/mkinitcpio.conf.d/10-loq.conf.

## Swap and hibernation
- Swapfile of 20 GiB in @swap (16 GiB RAM plus margin).
- Create: btrfs filesystem mkswapfile --size 20g --uuid clear /swap/swapfile
- fstab: /swap/swapfile none swap defaults 0 0
- Resume: systemd-sleep picks the swapfile and stores its location in the
  HibernateLocation EFI variable; the systemd initramfs resumes from it.
  Fallback only if resume fails: add resume=/dev/mapper/cryptroot and
  resume_offset=<btrfs inspect-internal map-swapfile -r /swap/swapfile>.
- Resume asks for the LUKS passphrase (expected).
- Do NOT put the nvidia modules in early KMS (may break resume).
- Verified 2026-11-21: systemctl hibernate, power on, passphrase, session back.
- Optional: zram swap for everyday use, with higher priority than the swapfile.
- Verified: /sys/power/mem_sleep offers deep (default) for normal suspend.

## GPU (Intel iGPU + RTX 4050)
- Verified: BIOS MUX is in Dynamic Graphics and the internal panel (eDP-1)
  is on the Intel iGPU. Keep Dynamic for daily use.
- Packages: nvidia-open (driver 620 on 2026-11-21, prebuilt, no DKMS),
  nvidia-utils (pulls the egl-* libraries), nvidia-prime, vulkan-intel,
  intel-media-driver. Steam later: multilib + lib32-nvidia-utils.
- Hyprland runs on the Intel only (implemented 2026-11-21):
  udev rule files-loq/etc/udev/rules.d/90-gpu-names.rules creates
  /dev/dri/intel-igpu and /dev/dri/nvidia-dgpu (card numbers can swap), and
  machines/arch-loq.lua sets drm_devices -> hl.env("AQ_DRM_DEVICES", ...).
  Before that Hyprland held card0/renderD129 of the NVIDIA.
  External monitor on HDMI (hypothesis: wired to the NVIDIA, untested): switch
  to the second drm_devices line in arch-loq.lua and exit Hyprland (Super+M).
- Apps and games on the NVIDIA: prime-run <cmd>; Steam launch option
  "prime-run %command%". Not tested yet (needs a GL/Vulkan app).
- Do NOT set the NVIDIA-primary variables globally (LIBVA_DRIVER_NAME=nvidia,
  __GLX_VENDOR_LIBRARY_NAME=nvidia).
- Runtime D3 (dGPU powered off when idle): NOT available on this LOQ
  (verified 2026-11-21). Driver default: "Runtime D3 status: Disabled by
  default"; with NVreg_DynamicPowerManagement=0x02: "Not supported" (reverted).
  dmesg: "failed to get platform power mode from SBIOS". The GPU firmware_node
  has no power_resources_D3hot. Under nouveau (live ISO) it did reach
  "suspended". Untested: 0x01 (coarse-grained), which would also need no
  process holding renderD129 (Hyprland and hyprpolkitagent open it).
  Kept: files-loq/etc/udev/rules.d/80-nvidia-pm.rules (power/control=auto;
  the NVIDIA HDMI audio function 01:00.1 does suspend with it).
  Battery workaround: BIOS (F2) Graphics Device = UMA Graphics turns the
  NVIDIA off in hardware (no prime-run then); back to Dynamic Graphics to play.
  Never use nvidia-smi to check power and never poll it from Waybar.
- Suspend/hibernate with nvidia-open 620: /proc/driver/nvidia/params shows
  UseKernelSuspendNotifiers: 1 (NVIDIA README 595+: open modules preserve video
  memory automatically with it), so nvidia-suspend/hibernate/resume services
  stay disabled. Hibernation verified 2026-11-21.
- No kms hook in the initramfs (files-loq/etc/mkinitcpio.conf.d/10-loq.conf):
  with it the initramfs carried nouveau.ko and 661 NVIDIA firmware files (137M);
  without it 20M. nvidia-utils blacklists nouveau (usr/lib/modprobe.d).
- GPU power limit: one report (LOQ with RTX 4070) says the GPU stayed at 35-55 W
  until nvidia-powerd was enabled and the performance profile was used.
  May apply to the 4050; unverified.

## Battery and power
- Verified: battery is BAT1 (not BAT0); AC adapter is ACAD. Battery new:
  energy_full 63190 mWh vs 60000 design (2026-11-21).
- Verified: brightness keys work through nvidia_wmi_ec_backlight.
- Charge limit: TLP 1.11 drives it through the kernel charge_types file
  (/sys/class/power_supply/BAT1/charge_types: Fast Standard Long_Life).
  STOP_CHARGE_THRESH_BAT0="1" = Long_Life = conservation mode (BAT0 name even
  though the battery is BAT1). Factory state was [Fast] (rapid charge); on the
  first boot TLP said "done" but it stayed Fast; writing Long_Life by hand
  worked and it survived a reboot (cause of the first failure unknown).
  It holds the charge ("Not charging" at 90%) and charges again only below the
  cap; the cap percentage on the LOQ is still unknown (watch where it stops).
  Decision: conservation on (laptop is almost always plugged in). For a day
  away from outlets: sudo tlp fullcharge (temporary, untested on the LOQ).
- Power management: TLP 1.11 (not power-profiles-daemon). New names: _PRF
  (performance profile, used on AC), _BAL (balanced, used on battery), _SAV.
  Config files-loq/etc/tlp.d/10-loq.conf: PRF=balanced, BAL=low-power,
  SAV=low-power. Verified: AC -> balanced, battery -> low-power.
- Bypass charging (outlet without using the battery): unknown for the LOQ.

## Still to do
- Visual chat: a beep sounds when deleting text in the terminal. Hypothesis:
  the readline bell (Backspace on an empty prompt) played by kitty; fix with
  enable_audio_bell no in kitty.conf, or set bell-style none in ~/.inputrc.
- Visual chat: with monitor scale 1 (2026-11-23) everything looks too small
  (kitty, rofi, waybar, Godot). Keep scale 1 (sharp XWayland) and raise sizes
  per app: kitty font_size, rofi and waybar font, GTK/Qt font size, Godot
  Editor Settings -> Interface -> Editor -> Display Scale, IDE fonts.
- Waybar: power-profiles-daemon module (TLP was chosen), missing
  power_menu.xml for custom/power, unused battery#bat2 (BAT2).
- hypridle: not in the autostart yet; hypridle.conf is the stock sample
  (suspends after 30 min; rgb:kbd_backlight does not exist on the LOQ).
- sshd: started by hand during setup (not enabled). Decide later.
- systemd-boot-update.service updates the bootloader at boot, outside pacman;
  the /boot backup hook catches it at the next pacman transaction.
