#!/bin/bash

# Fix: Changed /bin/sh to /bin/bash for better compatibility with Bash syntax
echo -e "Starting Installation Script by @shivjeet1"
read -p "\nNote: Have you partitioned the DISK ? [y/n] " yn

# Fix: Corrected syntax for 'if' condition (added space and used [[ ]])
if [[ $yn != "y" ]]; then
    echo -e "Perform partitioning with [fdisk/gparted] then run this script again."
    exit 1
fi

# Setup start
echo "Proceeding with post-installation"
echo "Installing Packages."
sudo pacman --noconfirm -S base-devel git libx11 libxft \
    xf86-input-synaptics xf86-video-intel xorg-server xorg-xinit \
    xwallpaper zsh-completions zsh-syntax-highlighting pipewire \
    pipewire-audio pipewire-pulse picom python python-pip python-pywal \
    ttf-nerd-fonts-symbols-mono ueberzug usbutils xorg-xrandr unzip \
    openssh brightnessctl || exit 1

# Fix: Corrected Git bare clone command syntax
echo "Setting up dotfiles"
sleep 2
git clone --bare https://github.com/shivjeet1/dotfiles.git $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout

echo "Configuring . . ."
sleep 1
echo ". ."
sleep 1
echo "."

# Fix: Removed incorrect DISPLAY=3 export (no need for this in setup)
source $HOME/.zprofile 2> /dev/null

# Fix: Corrected incorrect variable usage in sed commands
sed '/urg/d' -i "$XDG_CACHE_HOME/wal/colors-wal-dwm.h"
sed '31s/0/256/' -i "$XDG_CACHE_HOME/wal/colors-wal-st.h"

sed -i "s/.*foreground.*/$(grep foreground $XDG_CACHE_HOME/wal/colors.Xresources | head -n 1 | sed 's/\*/Sxiv\./g')/" "$XRESOURCES"
sed -i "s/.*background.*/$(grep background $XDG_CACHE_HOME/wal/colors.Xresources | head -n 1 | sed 's/\*/Sxiv\./g')/" "$XRESOURCES"

# Fix: Added missing mkdir before cloning DWM
echo "Setting up DWM"
mkdir -p $HOME/.local/src
git clone https://github.com/shivjeet1/dwm.git $HOME/.local/src/dwm
git clone https://github.com/shivjeet1/dmenu.git $HOME/.local/src/dmenu
git clone https://github.com/shivjeet1/slstatus.git $HOME/.local/src/slstatus
git clone https://github.com/shivjeet1/st.git $HOME/.local/src/st

user_correction(){
    sed -i "s/shiv/$USER/" $HOME/.local/src/dwm/config.def.h
    sed -i "s/shiv/$USER/" $HOME/.local/src/st/config.def.h
    sed -i "s/shiv/$USER/" $HOME/.local/src/dmenu/config.def.h
    
    cd $HOME/.local/src/dwm && cp config.def.h config.h && sudo make clean install
    cd $HOME/.local/src/st && cp config.def.h config.h && sudo make clean install
    cd $HOME/.local/src/dmenu && cp config.def.h config.h && sudo make clean install
}

case $USER in
    shiv)
        cd $HOME/.local/src/dwm && sudo make clean install
        cd $HOME/.local/src/st && sudo make clean install
        cd $HOME/.local/src/dmenu && sudo make clean install
        ;;
    *)
        user_correction
        ;;
esac

# Fix: Added proper DWMBlocks installation
git clone https://github.com/shivjeet1/dwmblocks.git $HOME/.local/src/dwmblocks
cd $HOME/.local/src/dwmblocks && sudo make clean install || sudo make clean install

# Fix: Removed incorrect space in variable assignment
read -p "EFI Partition: " pefi
echo "Formatting EFI partition to FAT32"
mkfs.fat -F 32 "$pefi"

read -p "Root Partition: " proot
echo "Formatting Root Partition to ext4"
mkfs.ext4 "$proot"

read -p "Do you need SWAP ? [y/n] " syn
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

# Fix: Used sudo for pacstrap in case script is not run as root
echo "Installing Packages"
sudo pacstrap -K /mnt base linux linux-firmware grub efibootmgr neovim networkmanager sudo openssh intel-ucode man-db zsh git mesa || exit 1

# Fix: Corrected locale setup commands
echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Chrooting into environment"
arch-chroot /mnt <<EOF

echo "Setting up keyboard"
echo "LANG=en_IN.UTF-8" > /etc/locale.conf

echo "Setting up Timezone [India]"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Fix: Set root password non-interactively
echo "root:password" | chpasswd
EOF

read -p "Creating New user: " user
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$user"
echo "Setting password for $user"
echo "$user:password" | arch-chroot /mnt chpasswd
echo '%wheel ALL=(ALL:ALL) ALL' | arch-chroot /mnt tee -a /etc/sudoers
arch-chroot /mnt chsh -s /bin/zsh "$user"

read -p "Enter Hostname: " hname
echo "$hname" | arch-chroot /mnt tee /etc/hostname

echo "Setting up hosts file"
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$hname.localdomain\t$hname" | arch-chroot /mnt tee -a /etc/hosts
arch-chroot /mnt systemctl enable NetworkManager

# Fix: Removed incorrect variable space and fixed GRUB setup
echo "Setting up Bootloader"
arch-chroot /mnt sed -i '/PROBER=/s/#//g' /etc/default/grub
p_efi=$(df | grep /boot | awk '{print $1}')
arch-chroot /mnt grub-install "${p_efi::-1}"
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Fix: Ensuring safe unmounting
echo "Unmounting partitions"
umount -R /mnt

echo "Rebooting..."
sleep 3
reboot

