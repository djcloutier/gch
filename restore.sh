#!/bin/bash

#mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
#Run Rescuezilla
#rescuezillz
#chroot and update grub on RAID1 member disks
mkdir /mnt/gch
mount /dev/md/ubuntu\:0 /mnt/gch
mount --bind /dev /mnt/gch/dev
mount --bind /proc /mnt/gch/proc
mount --bind /sys /mnt/gch/sys

chroot /mnt/gch

#install grub
grub-install /dev/sda
grub-install /dev/sdb

exit
