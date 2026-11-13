# LOQ 15IRX9: partition and power checklist

Hardware: Lenovo LOQ 15IRX9 83KHS00300, i5-13450HX, 16 GB RAM, 512 GB NVMe,
RTX 4050. Decision: Linux only (no Windows).

Everything below is a checklist to research and confirm when the laptop
arrives. None of it has been verified on the real hardware yet.

## Partition layout
- [ ] Device names are nvme0n1pN, not sdaN (the snapper notes use /dev/sda2).
- [ ] ESP of about 1 GiB mounted at /boot. Kernels live there, outside Btrfs,
      so keep the /boot backup hook.
- [ ] Btrfs with flat subvolumes: @, @home, @log, @pkg, @snapshots.
- [ ] Decide LUKS. If yes, Btrfs (and swap) go inside the encrypted container;
      the initramfs needs the unlock hook and the boot entry needs matching
      kernel parameters. Rehearse it in the new VM first.
- [ ] Swap sized for hibernation (about the size of RAM, 16 GB, to be safe).
      Choose: dedicated swap partition (simpler) or a swapfile on Btrfs in
      its own @swap subvolume (needs resume_offset).

## Suspend and hibernate
- [ ] Check which suspend modes the firmware offers: cat /sys/power/mem_sleep
- [ ] Hibernate: resume hook and kernel parameters matching the swap choice,
      then test systemctl hibernate.
- [ ] NVIDIA with suspend/hibernate needs extra setup (research on arrival).
- [ ] hypridle: re-enable the brightness and suspend listeners.
- [ ] Lid close behavior (logind HandleLidSwitch).

## Housekeeping
- [ ] TRIM: enable fstrim.timer (if LUKS, check the discard settings).
- [ ] Optional: zram swap in RAM (zram-generator), independent from hibernation.
- [ ] Secure Boot: decide, and check that it does not block hibernation.
- [ ] Note the firmware version and settings before changing anything.
- [ ] Battery name in /sys/class/power_supply for the Waybar battery module.