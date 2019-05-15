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
