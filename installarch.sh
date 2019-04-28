#!/bin/bash
pacman -Sy

fdisk /dev/sda <<EOF
n
p
1


w
EOF
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt 
#pacstrap -U -p /mnt >> /mnt/etc/fstab