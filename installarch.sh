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

arch-chroot "passwd"
arch-chroot "pacman -S ttf-dejavu lxdm"
arch-chrootecho "'LANG="en_US.UTF-8"' >> /etc/locale.conf"
arch-chrootecho ""en_US.UTF-8" >> /etc/locale.gen"
arch-chroot "locale-gen"
arch-chrootln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
arch-chroothwclock --systohc --localtime
arch-chrootecho "KEYMAP=cz" > /etc/vconsole.conf
arch-chroot "echo arch > /etc/hostname"
arch-chroot "cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost arch
::1 localhost.localdomain localhost arch
EOF"
arch-chroot "pacman -S grub"
arch-chroot "grub-install --recheck /dev/sda"
arch-chroot "grub-mkconfig -o /boot/grub/grub.cfg"
exit
umount -R /mnt
reboot
