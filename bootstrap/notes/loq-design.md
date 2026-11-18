# LOQ 15IRX9 design: decisions and reasons

Status: proposal from research. Nothing is verified on the real hardware yet.
The checklists in loq-partition-and-power.md and loq-first-boot-tests.md are
what to verify when the laptop arrives.

## Partitions (NVMe: nvme0n1pN)
1. ESP 2 GiB FAT32 at /boot (kernel, initramfs, fallback; NVIDIA makes the
   initramfs bigger). Keep the /boot backup hook.
2. Rest of the disk: one Btrfs (inside LUKS2 if chosen), same mount options as
   the VM (noatime, compress=zstd:1).
   Subvolumes: @, @home, @log, @pkg, @snapshots, @swap.
No Windows and no separate swap partition.

## Swap and hibernation
- Swapfile of 20 GiB in @swap (16 GiB RAM plus margin; revisit the size rule).
- Create: btrfs filesystem mkswapfile --size 20g --uuid clear /swap/swapfile
- @swap is never snapshotted.
- Hibernation needs the resume offset:
  btrfs inspect-internal map-swapfile -r /swap/swapfile
- Systemd-based initramfs on UEFI may not need resume= (mkinitcpio >= 38,
  systemd >= 255). Classic (busybox) initramfs needs the resume hook, after
  udev (and after encrypt with LUKS). A missing resume hook makes the machine
  reboot instead of resuming. Decide the initramfs flavor in the VM rehearsal.
- With LUKS, resume must point to the unlocked (mapped) device.
- Do NOT put the nvidia modules in early KMS (may break resume).
- Test: systemctl hibernate, power on, check that the session is back.
- Optional: zram swap for everyday use, with higher priority than the swapfile.

## GPU (Intel iGPU + RTX 4050)
- Goal: compositor on the iGPU, NVIDIA only on demand.
- Packages: nvidia-open (prebuilt, no DKMS), nvidia-utils, egl-wayland,
  nvidia-prime, vulkan-intel. Steam: multilib + lib32-nvidia-utils.
- Run a game on NVIDIA: prime-run <cmd>
- Do NOT set the NVIDIA-primary variables globally (LIBVA_DRIVER_NAME=nvidia,
  __GLX_VENDOR_LIBRARY_NAME=nvidia): they make apps prefer NVIDIA and keep it
  awake (my reasoning, verify).
- If Hyprland picks the wrong primary GPU: AQ_DRM_DEVICES with the iGPU first.
- Runtime D3 is on by default for Ampere or newer notebooks with a supported
  configuration. Verify: cat /sys/bus/pci/devices/<nvidia bus id>/power/runtime_status
  (should be "suspended" when idle). Never use nvidia-smi for this and never
  poll it from Waybar: it wakes the GPU.
- BIOS: look for a hybrid/discrete (MUX) option. Keep hybrid for battery;
  discrete-only is a workaround for external monitor problems.
- Suspend: nvidia-suspend/hibernate/resume services and
  nvidia.NVreg_PreserveVideoMemoryAllocations=1. The Hyprland wiki says Arch
  does this already; check with systemctl is-enabled and cat /proc/cmdline.
- GPU power limit: one report (LOQ with RTX 4070) says the GPU stayed at 35-55 W
  until nvidia-powerd was enabled and the performance profile was used.
  May apply to the 4050; unverified.

## Battery
- Charge limit: ideapad_laptop conservation mode
  (/sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode, 0/1), a fixed
  cap (about 60% on documented models; the value on the LOQ is unknown).
  It exists on the LOQ 15IRX9 in Windows (Lenovo Vantage); check the sysfs file.
- Power management: TLP, not power-profiles-daemon (they conflict; PPD covers
  only a subset of TLP's settings). TLP can set the charge cap and switch the
  platform profile between AC and battery. Remove the power-profiles-daemon
  module from the Waybar config.
- To test: AC = performance or balanced, battery = low-power. On LOQs the
  profile mostly changes the GPU power limit and the fan curve.
- Bypass charging (outlet without using the battery): unknown for the LOQ.