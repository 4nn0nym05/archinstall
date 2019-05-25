#!/bin/bash

set -xe

timedatectl set-ntp true

parted <<EOF
mklabel msdos
mkpart primary ext2 1 400M
mkpart primary ext4 400M 100%
set 1 boot on
set 2 LVM on
quit
EOF
cryptsetup luksFormat /dev/sda2
cryptsetup open --type luks /dev/sda2 lvm
#pvcreate --dataalignment 1m /dev/mapper/lvm #ssd
pvcreate /dev/mapper/lvm #only hdd
vgcreate volgroup0 /dev/mapper/lvm
lvcreate -L 10GB volgroup0 -n lv_root
lvcreate -L 3GB volgroup0 -n lv_swap
lvcreate -l 100%FREE volgroup0 -n lv_home
modprobe dm_mod
vgscan
vgchange -ay

mkfs.ext2 /dev/sda1
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home

mount /dev/volgroup0/lv_root /mnt 
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home 
mount /dev/volgroup0/lv_home /mnt/home 
pacstrap -i /mnt base
genfstab -U -p /mnt >> /mnt/etc/fstab


arch-chroot /mnt passwd
arch-chroot /mnt useradd -m -g wheel joker 
arch-chroot /mnt passwd joker
arch-chroot /mnt pacman -S --noconfirm grub linux-headers ttf-dejavu i3 dmenu sddm networkmanager xorg-server 
arch-chroot /mnt systemctl enable sddm 
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
arch-chroot /mnt echo "en_US.UTF-8" >> /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
arch-chroot /mnt hwclock --systohc --localtime
arch-chroot /mnt echo "KEYMAP=cz" > /etc/vconsole.conf
arch-chroot /mnt echo arch > /etc/hostname
arch-chroot /mnt cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost arch
::1 localhost.localdomain localhost arch
EOF
   cat > /etc/mkinitcpio.conf <<EOF
# vim:set ft=sh
# MODULES
# The following modules are loaded before any boot hooks are
# run.  Advanced users may wish to specify all system modules
# in this array.  For instance:
#     MODULES="piix ide_disk reiserfs"
MODULES="ext4"
# BINARIES
# This setting includes any additional binaries a given user may
# wish into the CPIO image.  This is run last, so it may be used to
# override the actual binaries included by a given hook
# BINARIES are dependency parsed, so you may safely ignore libraries
BINARIES=""
# FILES
# This setting is similar to BINARIES above, however, files are added
# as-is and are not parsed in any way.  This is useful for config files.
# Some users may wish to include modprobe.conf for custom module options
# like so:
#    FILES="/etc/modprobe.d/modprobe.conf"
FILES=""
# HOOKS
# This is the most important setting in this file.  The HOOKS control the
# modules and scripts added to the image, and what happens at boot time.
# Order is important, and it is recommended that you do not change the
# order in which HOOKS are added.  Run 'mkinitcpio -H <hook name>' for
# help on a given hook.
# 'base' is _required_ unless you know precisely what you are doing.
# 'udev' is _required_ in order to automatically load modules
# 'filesystems' is _required_ unless you specify your fs modules in MODULES
# Examples:
##   This setup specifies all modules in the MODULES setting above.
##   No raid, lvm2, or encrypted root is needed.
#    HOOKS="base"
#
##   This setup will autodetect all modules for your system and should
##   work as a sane default
#    HOOKS="base udev autodetect pata scsi sata filesystems"
#
##   This is identical to the above, except the old ide subsystem is
##   used for IDE devices instead of the new pata subsystem.
#    HOOKS="base udev autodetect ide scsi sata filesystems"
#
##   This setup will generate a 'full' image which supports most systems.
##   No autodetection is done.
#    HOOKS="base udev pata scsi sata usb filesystems"
#
##   This setup assembles a pata mdadm array with an encrypted root FS.
##   Note: See 'mkinitcpio -H mdadm' for more information on raid devices.
#    HOOKS="base udev pata mdadm encrypt filesystems"
#
##   This setup loads an lvm2 volume group on a usb device.
#    HOOKS="base udev usb lvm2 filesystems"
#
##   NOTE: If you have /usr on a separate partition, you MUST include the
#    usr, fsck and shutdown hooks.
HOOKS="base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck"
# COMPRESSION
# Use this to compress the initramfs image. By default, gzip compression
# is used. Use 'cat' to create an uncompressed image.
#COMPRESSION="gzip"
#COMPRESSION="bzip2"
#COMPRESSION="lzma"
#COMPRESSION="xz"
#COMPRESSION="lzop"
# COMPRESSION_OPTIONS
# Additional options for the compressor
#COMPRESSION_OPTIONS=""
EOF
