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
pvcreate --dataalignment 1m /dev/mapper/lvm
#pvcreate /dev/mapper/lvm #only hdd
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
arch-chroot /mnt echo arch > /etc/hostname
arch-chroot /mnt cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost arch
::1 localhost.localdomain localhost arch
EOF
arch-chroot /mnt sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
arch-chroot /mnt nano /etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -p linux
arch-chroot /mnt sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=/dev/sda2:volgroup0 quiet"/g' /etc/default/grub
arch-chroot /mnt nano /etc/default/grub
arch-chroot /mnt grub-install --recheck /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
