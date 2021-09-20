#!/bin/bash
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sdb
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

#create software RAID1 
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
#Run Rescuezilla (user must restore file)
rescuezilla
#chroot and update grub on RAID1 member disks
mkdir /mnt/gch
mount /dev/md/ubuntu\:0 /mnt/gch
mount --bind /dev /mnt/gch/dev
mount --bind /proc /mnt/gch/proc
mount --bind /sys /mnt/gch/sys

#chroot and install grub
chroot /mnt/gch /bin/bash -c "grub-install /dev/sda ; grub-install /dev/sdb ; exit"

exit
