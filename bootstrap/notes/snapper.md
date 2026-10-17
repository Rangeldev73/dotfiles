# Snapper on Btrfs (flatlayout: @, @home, @log, @pkg, @snapshots)

ESP is mounted at /boot (vfat), outside Btrfs, so a pacman hook copies it into the root subvolume (/.bootbackup) on every kernel update.

Steps (as root):

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
snapper -c root set-config "TIMELINE_CREATE=no" "NUMBER_LIMIT=10" "NUMBER_LIMIT_IMPORTANT=5"
systemctl enable --now snapper-cleanup.timer
systemctl disable --now snapper-timeline.timer
install -Dm644 files/etc/pacman.d/hooks/95-bootbackup.hook /etc/pacman.d/hooks/95-bootbackup.hook

Lessons learned:

- The UUID in fstab is per disk: never copy it from another machine.
- findmnt --verify only checks syntax, not wheter the subvolume exists.
Test with: mount /.snapshots
- Always pass file paths to "snapper undochange"; without them it reverts the whole subvolume
, including the pacman database.
