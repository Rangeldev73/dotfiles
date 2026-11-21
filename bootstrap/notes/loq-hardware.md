# LOQ 15IRX9: hardware facts (read-only discovery, 2026-11-21)

Collected from the BIOS screens and the Arch live ISO (archlinux-2026.11, over SSH).
Nothing on the NVMe was changed. "Verified" = seen in BIOS or command output.
"Hypothesis" = my reading, still to test.

## BIOS (verified)
- BIOS NECN50WW, EC NEEC50WW. MTM 83KHS00300.
- Storage Controller Mode: AHCI (no Intel VMD/RST, NVMe visible to Linux).
- Graphics Device (MUX): Dynamic Graphics (current) / UMA Graphics / Discrete Graphics.
- Intel VT-x: Enabled. Hyper-Threading: Enabled. BIOS Back Flash: Disabled.
- Intel PTT (firmware TPM 2.0): Enabled. Kernel sees /sys/class/tpm/tpm0.
- Secure Boot: was Enabled; CHANGED to Disabled on 2026-11-21 to boot the Arch ISO.
  Undo: Security > Secure Boot > Enabled, F10.
- USB Boot: Enabled. Keys: F2 = BIOS setup, F12 = boot menu (both worked).
- VT-d value: not recorded.

## Firmware boot (verified)
- UEFI 64-bit (fw_platform_size = 64). efibootmgr Timeout: 0.
- Factory entry Boot0003 "lux": \EFI\lux\shimx64.efi on nvme0n1p2 (shim, signed).
  BootOrder: 0003,0000,2002,2003,2001.

## Disk (verified)
- NVMe: SK hynix BC901 (DRAM-less), HFS512GEJ4X112N, /dev/nvme0n1, 476.9G.
- USB stick in the live session: /dev/sda (never touch it during install).
- Factory layout (to be wiped; no LUKS anywhere):
  p1 1M ext4 | p2 512M vfat (ESP) | p3 1G btrfs | p4 5G swap | p5 466.4G btrfs | p6 4G ext4
  Hypothesis: p3 = /boot, p5 = root, p6 = recovery. Factory OS name not checked.
- Factory ESP is 512M; the design wants 2 GiB, so the partition table is recreated.

## PCI devices and live-ISO drivers (verified)
- 00:02.0 Intel Raptor Lake-S UHD [8086:a78b]: i915 (xe module also available).
- 01:00.0 NVIDIA AD107M RTX 4050 Mobile [10de:28e1]: nouveau in the live ISO.
- 01:00.1 NVIDIA HDA audio: snd_hda_intel.
- 00:14.3 Intel CNVi Wi-Fi (700 series) [8086:7a70]: iwlwifi. Worked out of the box.
- 00:1f.3 Intel HD Audio [8086:7a50]: snd_hda_intel (hypothesis: SOF firmware not needed).
- 06:00.0 SK hynix BC901 NVMe: nvme.
- 07:00.0 Realtek RTL8111/8168 Ethernet: r8169 (interface enp7s0).

## USB devices (verified)
- 30c9:00a7 Luxvisions Integrated Camera.
- 8087:0026 Intel AX201 Bluetooth.
- 048d:c996 ITE Device(8176). Hypothesis: keyboard backlight controller.

## Display (verified)
- card0 = NVIDIA (0000:01:00.0), card1 = Intel (0000:00:02.0) in this boot.
  Card numbers can change between boots; use /dev/dri/by-path if AQ_DRM_DEVICES is needed.
- Internal panel: card1-eDP-1 connected -> in Dynamic Graphics the panel is on the iGPU.
  NVIDIA also has eDP-2 (disconnected; used in Discrete mode, hypothesis).
- NVIDIA connectors: HDMI-A-5, DP-3. Hypothesis: the HDMI port is wired to the NVIDIA,
  so an external monitor wakes it. Test with a monitor.
- eDP-1 modes: 1920x1080 (listed twice; hypothesis: 144 Hz and 60 Hz). Check with hyprctl.

## Power (verified)
- /sys/power/mem_sleep: s2idle [deep] (deep/S3 is the default).
- platform_profile choices: low-power balanced performance max-power custom (now balanced).
- conservation_mode exists: /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode = 0.
  Cap percentage: unknown, test after install.
- NVIDIA runtime PM with nouveau: control auto, runtime_status suspended
  (re-check with nvidia-open; nouveau result is not conclusive).
- power_supply: ACAD, BAT1 (not BAT0), ucsi-source-psy-USBC000:001.
  Waybar battery module must use BAT1.
- backlight: only nvidia_wmi_ec_backlight (no intel_backlight). Hypothesis: brightness
  goes through the EC; test the brightness keys and the Waybar backlight module.

## Still to test after install
See loq-first-boot-tests.md, plus: brightness via nvidia_wmi_ec_backlight, conservation
cap %, NVIDIA runtime D3 with nvidia-open, external HDMI on NVIDIA, 144 Hz, keyboard layout.

## Verified after the install (2026-11-21, Arch on the NVMe)
- Keyboard: physical ABNT2 (has a Ç key); console keymap br-abnt2, Hyprland
  kb_layout "br". The LUKS passphrase is typed with br-abnt2 at boot.
- Panel: eDP-1 1920x1080, 144 Hz and 60 Hz modes; Hyprland uses 144 Hz.
- Brightness keys work through nvidia_wmi_ec_backlight.
- Battery: charge_types offers Fast/Standard/Long_Life (factory: Fast);
  Long_Life (conservation) works. energy_full 63190 mWh (design 60000).
- NVIDIA (nvidia-open 620): runtime D3 not available ("Disabled by default";
  "Not supported" with NVreg_DynamicPowerManagement=0x02). See loq-design.md.
- ESP: the Lenovo firmware writes \BackupSbb.bin (8 MiB) into the ESP
  (hypothesis: firmware backup file; leave it alone).
- NVRAM: after the wipe the firmware removed "lux" by itself and re-pointed
  its own "EFI Hard Drive" entry (Boot0000) to the new ESP fallback path.

