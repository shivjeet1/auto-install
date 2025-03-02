#!/bin/bash
echo -e "Starting Installation Script by @shivjeet1"

# Check if disk partitioning is done
read -p "Note: Have you partitioned the DISK? [y/n] " yn
if [[ $yn != "y" ]]; then
    echo -e "Perform partitioning with [fdisk/gparted] then run this script again."
    exit 1
fi

# Get EFI partition
read -p "EFI Partition: " pefi
echo "Formatting EFI partition to FAT32"
mkfs.fat -F 32 "$pefi"

# Get Root partition
read -p "Root Partition: " proot
echo "Formatting Root Partition to EXT4"
mkfs.ext4 "$proot"

# Setup SWAP if needed
read -p "Do you need SWAP? [y/n] " syn
if [[ $syn == "y" ]]; then
    read -p "SWAP Partition: " swapp
    echo "Creating SWAP"
    mkswap "$swapp"
    echo "Mounting SWAP"
    swapon "$swapp"
fi

# Mount partitions
echo "Mounting Root"
mount "$proot" /mnt

echo "Mounting EFI"
mount --mkdir "$pefi" /mnt/boot

# Install base system
echo "Installing Packages"
pacstrap -K /mnt base linux linux-firmware grub efibootmgr neovim networkmanager sudo openssh intel-ucode man-db zsh git mesa || exit 1

# Generate fstab
echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and execute commands
arch-chroot /mnt /bin/bash <<EOF

# Set up locale
echo "LANG=en_IN.UTF-8" > /etc/locale.conf

# Set up timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Set root password
echo -e "root\nroot" | passwd

# Create new user
read -p "Creating New user: " user
useradd -m -G wheel -s /bin/bash "\$user"
echo -e "password\npassword" | passwd "\$user"

# Grant sudo privileges
echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
chsh -s /bin/zsh "\$user"

# Set hostname
read -p "Enter HostName: " hname
echo "\$hname" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.0.1.1\tlocalhost.localdomain\t\$hname" >> /etc/hosts

# Enable NetworkManager
systemctl enable NetworkManager

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Unmount and reboot
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

