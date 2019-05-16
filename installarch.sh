#!/bin/bash


set -xe
timedatectl set-ntp true

fdisk /dev/sda <<EOF
o
n
p
1
+7G
n
p
2
+512M
a
2
t
1
8e
w
EOF
setup_LVM() {
  cryptsetup luksFormat /dev/sda1
  cryptsetup open --type luks /dev/sda1 lvm
  pvcreate /dev/mapper/lvm
  vgcreate volgroup0 /dev/mapper/lvm
  lvcreate -L 3GB volgroup0 -n lv_root
  lvcreate -L 1GB volgroup0 -n lv_swap
  lvcreate -l 100%FREE volgroup0 -n lv_home
  modprobe dm_mod
 vgscan
 vgchange -ay

}
setup_LVM
mkfs.ext2 /dev/sda2
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home

mount /dev/volgroup0/lv_root /mnt 
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
mkdir /mnt/home 
mount /dev/volgroup0/lv_home /mnt/home 
#pacstrap -i /mnt base
#genfstab -U -p /mnt >> /mnt/etc/fstab

chroot() {
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
}
