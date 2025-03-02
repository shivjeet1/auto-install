#!/bin/bash
echo -e "Starting Installation Script by @shivjeet1"

read -p "Note: Have you partitioned the DISK? [y/n] " yn
if [[ $yn != "y" ]]; then
    echo -e "Perform partitioning with [fdisk/gparted] then run this script again."
    exit 1
fi

read -p "EFI Partition: " pefi
echo "Formatting EFI partition to FAT32"
mkfs.fat -F 32 "$pefi"

read -p "Root Partition: " proot
echo "Formatting Root Partition to ext4"
mkfs.ext4 "$proot"

read -p "Do you need SWAP? [y/n] " syn
if [[ $syn == "y" ]]; then
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
arch-chroot /mnt <<EOF
echo "Setting up keyboard"
echo "LANG=en_IN.UTF-8" > /etc/locale.conf

echo "Setting up Timezone [India]"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

passwd
EOF

read -p "Creating New user: " user
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$user"
echo "Setting password for $user"
arch-chroot /mnt passwd "$user"
arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers"
arch-chroot /mnt chsh -s /bin/zsh "$user"

read -p "Enter Hostname: " hname
echo "$hname" | arch-chroot /mnt tee /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$hname.localdomain\t$hname" | arch-chroot /mnt tee -a /etc/hosts
arch-chroot /mnt systemctl enable NetworkManager

echo "Setting up Bootloader"
arch-chroot /mnt sed -i '/PROBER=/s/#//' /etc/default/grub
p_efi=$(df | grep /boot | awk '{print $1}')
arch-chroot /mnt grub-install "${p_efi::-1}"
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo "Unmounting partitions"
umount -R /mnt
echo "Rebooting..."
sleep 3
reboot

