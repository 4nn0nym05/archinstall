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
arch-chroot /mnt /bin/bash
passwd
pacman -S ttf-dejavu lxdm
echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
echo "en_US.UTF-8" >> /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
hwclock --systohc --localtime
echo "KEYMAP=cz" > /etc/vconsole.conf
echo arch > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost arch
::1 localhost.localdomain localhost arch
EOF
pacman -S grub
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
exit
umount -R /mnt
reboot
