# LOQ 15IRX9: partition and power checklist

SUPERSEDED for decisions: see loq-design.md (2026-11-21). This file only keeps
the checklist status. Hardware facts: loq-hardware.md.

Hardware: Lenovo LOQ 15IRX9 83KHS00300, i5-13450HX, 16 GB RAM, 512 GB NVMe,
RTX 4050. Linux only (no Windows).

## Partition layout
- [x] Device names: NVMe is /dev/nvme0n1 (partitions nvme0n1pN); the live USB
      is /dev/sda. Verified in the live ISO.
- [x] ESP: 2 GiB at /boot (changed from the old 1 GiB idea). Keep the /boot
      backup hook.
- [x] Btrfs flat subvolumes: @, @home, @log, @pkg, @snapshots, @swap.
- [x] LUKS: yes, LUKS2 with a passphrase, Btrfs and swapfile inside it,
      systemd initramfs with sd-encrypt.
- [x] Swap for hibernation: 20 GiB swapfile in @swap (no swap partition).

## Suspend and hibernate
- [x] mem_sleep: s2idle [deep]; deep is the default. Verified.
- [x] Resume mechanism decided: systemd initramfs + HibernateLocation EFI
      variable (no resume hook, no resume_offset).
- [ ] Test systemctl hibernate on the LOQ.
- [ ] NVIDIA with suspend/hibernate (see loq-design.md, GPU).
- [ ] hypridle: re-enable the brightness and suspend listeners.
- [ ] Lid close behavior (logind HandleLidSwitch).

## Housekeeping
- [x] TRIM: allow discards on LUKS (--allow-discards --persistent) and enable
      fstrim.timer.
- [ ] Optional: zram swap in RAM (zram-generator), independent from hibernation.
- [x] Secure Boot: off for now (decided). Revisit later; check lockdown vs
      hibernation then.
- [x] Firmware version and settings noted before changing anything
      (loq-hardware.md).
- [x] Battery name: BAT1.

## Battery health and GPU
- [x] conservation_mode exists (value 0). Cap percentage still unknown.
- [ ] Make it persistent (TLP) and measure the cap.
- [ ] Bypass/pass-through charging: unknown for the LOQ.
- [x] BIOS MUX: Dynamic Graphics; the panel is on the Intel iGPU.
- [ ] NVIDIA runtime D3 with nvidia-open; PRIME render offload for games.
- [x] Power profiles: TLP, not power-profiles-daemon.
- [ ] Check nvidia-powerd for the GPU power limit.
