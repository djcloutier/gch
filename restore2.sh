#!/bin/bash

#chroot and update grub on RAID1 member disks
mkdir /mnt/gch
mount /dev/md/ubuntu\:0 /mnt/gch
mount --bind /dev /mnt/gch/dev
mount --bind /proc /mnt/gch/proc
mount --bind /sys /mnt/gch/sys

#chroot and install grub
chroot /mnt/gch /bin/bash -c "grub-install /dev/sda ; grub-install /dev/sdb ; exit"
