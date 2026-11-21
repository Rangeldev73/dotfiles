# LOQ 15IRX9 design: decisions and reasons

Status (2026-11-21): the decisions below are final. Items marked "To test" or
"Hypothesis" still need the real hardware. Hardware facts live in
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
  HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
Kernel options in the systemd-boot entry:
  rd.luks.name=<UUID of nvme0n1p2>=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
To test: lsinitcpio shows whether the kms hook pulls the nvidia modules into
the initramfs (we do not want NVIDIA in early KMS, see GPU).

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
- Test: systemctl hibernate, power on, type the passphrase, session is back.
- Optional: zram swap for everyday use, with higher priority than the swapfile.
- Verified: /sys/power/mem_sleep offers deep (default) for normal suspend.

## GPU (Intel iGPU + RTX 4050)
- Verified: BIOS MUX is in Dynamic Graphics and the internal panel (eDP-1)
  is on the Intel iGPU. Keep Dynamic for battery; Discrete only as a
  workaround for external monitor problems.
- Goal: compositor on the iGPU, NVIDIA only on demand.
- Packages: nvidia-open (prebuilt, no DKMS), nvidia-utils, egl-wayland,
  nvidia-prime, vulkan-intel. Steam: multilib + lib32-nvidia-utils.
- Run a game on NVIDIA: prime-run <cmd>
- Do NOT set the NVIDIA-primary variables globally (LIBVA_DRIVER_NAME=nvidia,
  __GLX_VENDOR_LIBRARY_NAME=nvidia): they make apps prefer NVIDIA and keep it
  awake (my reasoning, verify).
- If Hyprland picks the wrong GPU: AQ_DRM_DEVICES with the iGPU first, using
  /dev/dri/by-path (card numbers changed between boots in the live ISO).
- Runtime D3: on by default for Ampere or newer notebooks with a supported
  configuration. To test with nvidia-open:
  cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status (want "suspended").
  Never use nvidia-smi for this and never poll it from Waybar: it wakes the GPU.
- Hypothesis: the HDMI port is wired to the NVIDIA, so an external monitor
  wakes it. Test with a monitor.
- Suspend/hibernate: nvidia-suspend/hibernate/resume services and
  nvidia.NVreg_PreserveVideoMemoryAllocations=1. The Hyprland wiki says Arch
  does this already; check with systemctl is-enabled and cat /proc/cmdline.
- GPU power limit: one report (LOQ with RTX 4070) says the GPU stayed at 35-55 W
  until nvidia-powerd was enabled and the performance profile was used.
  May apply to the 4050; unverified.

## Battery and power
- Verified: battery is BAT1 (not BAT0); AC adapter is ACAD.
- Verified: brightness only through nvidia_wmi_ec_backlight (no intel_backlight).
  To test: brightness keys, brightnessctl and the Waybar backlight module.
- Charge limit: ideapad_laptop conservation mode exists (verified):
  /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode (now 0).
  It is a fixed on/off cap; the percentage on the LOQ is unknown (test).
- Power management: TLP, not power-profiles-daemon (they conflict). TLP can set
  the conservation mode and switch platform_profile between AC and battery.
  Verified choices: low-power balanced performance max-power custom.
  To test: AC = balanced or performance, battery = low-power. On LOQs the
  profile mostly changes the GPU power limit and the fan curve.
- Bypass charging (outlet without using the battery): unknown for the LOQ.

## Repo fixes found in the 2026-11-21 review (still to do)
- (fixed) 95-bootbackup.hook now runs after every pacman transaction.
  Remaining gap: systemd-boot-update.service updates the bootloader at boot,
  outside pacman; the backup catches it at the next pacman transaction.
- Waybar: power-profiles-daemon module (TLP was chosen), missing
  power_menu.xml for custom/power, unused battery#bat2 (BAT2).
- hypridle.conf: rgb:kbd_backlight probably does not exist on the LOQ.
- (fixed) install.sh (loq profile): autologin drop-in (only when / is on
  cryptroot), TLP + masked systemd-rfkill, bluetooth, systemd-boot-update,
  files-loq/ for loq-only system files (TLP config). Disk/LUKS/boot stay manual.
