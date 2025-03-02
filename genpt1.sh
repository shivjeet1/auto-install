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
echo "Formatting Root Partition to EXT4"
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

echo "Chrooting into environment. Run the following commands manually after chroot:"
echo "1. Set locale: echo 'LANG=en_IN.UTF-8' > /etc/locale.conf"
echo "2. Set timezone: ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && hwclock --systohc"
echo "3. Run passwd to set root password"
echo "4. Create user using: useradd -m -G wheel -s /bin/bash <username>"
echo "5. Set password using: passwd <username>"
echo "6. Edit sudoers: echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo"
echo "7. Change shell: chsh -s /bin/zsh <username>"
echo "8. Set hostname: echo '<hostname>' > /etc/hostname"
echo "9. Add hosts: echo -e '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.0.1.1\tlocalhost.localdomain\t<hostname>' >> /etc/hosts"
echo "10. Enable NetworkManager: systemctl enable NetworkManager"
echo "11. Install bootloader: grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
echo "12. Generate GRUB config: grub-mkconfig -o /boot/grub/grub.cfg"

arch-chroot /mnt /bin/bash

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

