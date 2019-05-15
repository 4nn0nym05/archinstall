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
pacstrap -i /mnt base base-devel
genfstab -U -p /mnt >> /mnt/etc/fstab

arch_chroot "passwd"
arch_chroot "pacman -S ttf-dejavu lxdm"
arch_chroot "echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf"
arch-chroot "echo "en_US.UTF-8" >> /etc/locale.gen"
arch_chroot "locale-gen"
arch_chroot "ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime"
arch_chroot "hwclock --systohc --localtime"
arch_chroot "echo "KEYMAP=cz" > /etc/vconsole.conf"
arch_chroot "echo arch > /etc/hostname"
arch_chroot "cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost arch
::1 localhost.localdomain localhost arch
EOF"
arch_chroot "pacman -S grub"
arch_chroot "grub-install --recheck /dev/sda"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
exit
umount -R /mnt
reboot



/*  /dev/sda1 -400M boot partition nonencryted make it bootable
/dev/sda2 - make it linux LVM partition


cryptsetup luksFormat /dev/sda2
cryptsetup open --type luks /dev/sda2 lvm
pvcreate --dataalignment 1m /dev/mapper/lvm -only ssd
pvcreate /dev/mapper/lvm -only hdd
vgcreate volgroup0 /dev/mapper/lvm

lvcreate -L 30GB volgroup0 -n lv_root
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
 
after chroot
pacman -S grub linux-headers wpa_supplicant wireless_tools

nano /etc/mkinitcpio.conf 
/* pod HOOKS pridat mezi block a filesystems " encrypt lvm2 "
mkinitcpio -p linux 

nano /etc/default/grub
do GRUB_CMDLINE_LINUX_DEFAULT pridat " cryptdevice=/dev/sda2:volgroup0 quiet"

grub-install --target=i386-pc --recheck /dev/sda
??? cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/localer/en.mo
grub-mkconfig -o /boot/grub/grub.cfg */
