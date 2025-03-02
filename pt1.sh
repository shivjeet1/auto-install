#!/bin/bash
echo -e "Starting Installation Script by @shivjeet1"
read -p "\nNote: Have you partitioned the DISK ? [y/n]" yn
if [[ $yn != "y"]]; then
	echo -e "Perform partitioning with [fdisk/gparted] then run this script again."
	exit 1
fi

read -p "EFI Partition: " pefi
echo "Formatting efi partition to fat32"
mkfs.fat -F 32 "$pefi"

read -p "Root Partition: " proot
echo "Formatting Root Partition to ext4"
mkfs.ext4 "$proot"

read -p "Do you need SWAP ?[y/n]" syn
if [[ $syn == "y" ]];  then
	read -p "SWAP Partition: " swapp
	echo "Creating SWAP"
	mkswap "$swapp"
	echo "Mounting SWAP"
	swapon "$swapp"
fi

echo "Mounting Root"
mount "$proot" /mnt

echo "Mounting EFI"
mount --mkdir "$pefi" /mnt/boot

echo "Installing Packages"
pacstrap -K /mnt base linux linux-firmware grub efibootmgr neovim networkmanager sudo openssh intel-ucode man-db zsh git mesa || exit 1

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Chrooting into environment"
arch-chroot /mnt << EOF

echo "Setting up keyboard"
echo "LANG=en_IN.UTF-8" > /etc/locale.conf

echo "Setting up Timezone[INDIA]"
ln -sf  /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

passwd
EOF

echo "Setting up keyboard"
echo "LANG=en_IN.UTF-8" > /etc/locale.conf
echo "Setting up Timezone[INDIA]"
ln-sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "Setup password for ROOT user : "
passwd

read -p "Creating New user:" user
useradd -m -G wheel -s /bin/bash "$user"
echo "Setting password for $user"
passwd $user
echo '%wheel ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo
chsh -s /bin/zsh $user

read -p "Enter HostName : " hname
echo "$hname" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.0.1.1\tlocalhost.localdomain\t$hname" >> /etc/hosts
systemctl enable NetworkManager

echo "Setting-up Bootloader"
sed -i /etc/default/grub '/PROBER\=/s/\#//'
p_efi = $(df | grep /boot | awk '{print $1}')
grub-install ${p_efi::-1}
grub-mkconfig -o /boot/grub/grub.cfg

[ -z $user ] && pth='/root' || pth="/home/$user"

echo "Unmounting from SSD"
umount -R /mnt
echo "REBOOTING . . ."
sleep 1
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1
reboot && exit 0
