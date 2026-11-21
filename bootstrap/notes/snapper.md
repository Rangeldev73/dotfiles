# Snapper on Btrfs (flat layout: @, @home, @log, @pkg, @snapshots)

The ESP is mounted at /boot (vfat), outside Btrfs, so a pacman hook copies it
into the root subvolume (/.bootbackup) on every kernel update.

## Which device holds the Btrfs
Never copy device names or UUIDs between machines. Check with lsblk first.
- VM arch-hyprlab: /dev/sda2 (plain Btrfs).
- LOQ arch-loq: /dev/mapper/cryptroot (Btrfs inside LUKS on /dev/nvme0n1p2).
  In the LOQ live ISO, /dev/sda is the USB stick: never use it.
Below, BTRFS_DEV means the device for the machine you are on.

## LOQ (fresh install): @snapshots already exists
The LOQ install guide (loq-install.md, manual steps from the live ISO)
creates @snapshots together with the other subvolumes, and genfstab
writes the /.snapshots line. Only the snapper config is
needed (as root, after the first boot):

umount /.snapshots
rmdir /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

Why: snapper create-config refuses to run if /.snapshots exists, and it creates
its own nested /.snapshots subvolume, which we replace by the @snapshots mount.

## VM (done once, kept for reference): adding @snapshots later
mount -o subvolid=5 /dev/sda2 /mnt
btrfs subvolume create /mnt/@snapshots
umount /mnt
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
# append to /etc/fstab (UUID comes from: blkid -s UUID -o value /dev/sda2):
# UUID=<uuid> /.snapshots btrfs rw,noatime,compress=zstd:1,space_cache=v2,subvol=/@snapshots,nofail 0 0
mount /.snapshots
chmod 750 /.snapshots

## Both machines: settings, timers and the /boot hook
snapper -c root set-config "TIMELINE_CREATE=no" "NUMBER_LIMIT=10" "NUMBER_LIMIT_IMPORTANT=5"
systemctl enable --now snapper-cleanup.timer
systemctl disable --now snapper-timeline.timer
install -Dm644 files/etc/pacman.d/hooks/95-bootbackup.hook /etc/pacman.d/hooks/95-bootbackup.hook
(install.sh already does the timers and the hook once the root config exists.)

Check:
snapper -c root list
findmnt /.snapshots

## Lessons learned
- The UUID in fstab is per disk: never copy it from another machine.
  With LUKS, the fstab UUID is the one of the Btrfs inside cryptroot
  (blkid /dev/mapper/cryptroot), not the LUKS UUID of nvme0n1p2.
- findmnt --verify only checks syntax, not whether the subvolume exists.
  Test with: mount /.snapshots
- Always pass file paths to "snapper undochange"; without them it reverts the
  whole subvolume, including the pacman database.
- @swap (swapfile) and @home are not in the root config: snapper only covers @.
