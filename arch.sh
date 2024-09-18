#!/bin/bash

#===========================================================================================

# PART 1 Begins

echo "NOTE: Partioning should be done before proceeding."
read -p "Proceed? [y/n]: " yn

if [ $yn != "y" ]
then
  exit 1
fi

echo -e "\n1.Grub\n2.Systemd-boot"
read -p "Select bootloader [1/2]: " yn2

read -p "EFI partition: " efi_part
echo "Formatting efi partition to fat32"
mkfs.fat -F 32 $efi_part

read -p "Is swap partition required [y/n]: " yn1
if [ $yn1 == "y" ]
then
  read -p "Swap partition: " swap_part
  echo "Creating swap"
  mkswap $swap_part
fi

read -p "Root partition: " root_part
echo "Formatting root partition to ext4"
mkfs.ext4 $root_part

echo "Mounting root."
mount $root_part /mnt 

echo "Mounting efi"
case $yn2 in
  1)
    boot_l='grub' 
    mount --mkdir $efi_part /mnt/boot/efi
    ;;
  *)
    boot_l=''
    mount --mkdir $efi_part /mnt/boot
    ;;
esac

if [ $yn1 == "y" ]
then
  echo "Mounting swap"
  swapon $swap_part
fi

echo "Installing packages."
pacstrap -i /mnt base linux linux-firmware $boot_l efibootmgr neovim networkmanager sudo || exit 1

echo "Generating fstab and storing it."
genfstab -U /mnt >> /mnt/etc/fstab

sed -ne "$(grep -in '2 begins' $PWD/auto-install/arch.sh | cut -d\: -f1 | tail -n1),\$p" < $PWD/auto-install/arch.sh > /mnt/part2.sh

echo "Execute [bash part2.sh]" 

arch-chroot /mnt

echo "Unmounting."
umount -R /mnt 

reboot && exit 0 

# PART 1 Ends 

#===========================================================================================

# PART 2 Begins

echo "Setting up"

echo "LANG=en_IN.UTF-8" > /etc/locale.conf

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

read -p "Enter hostname: " h_name
echo $h_name > /etc/hostname

echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\tlocalhost.localdomain\t$h_name" >> /etc/hosts

echo "Setting up password for root user"
passwd 

read -p "Add user [y/n]: " yn3
if [ $yn3 == y ]
then
  read -p "Username: " user 
  useradd -m -G wheel -s /bin/bash $user
  echo "Setting password for $user"
  passwd $user
  echo '%wheel ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo
fi

systemctl enable NetworkManager 

echo "Setting up bootloader"
[ -n "$(pacman -Qs grub)" ] && boot_l=grub
case $boot_l in 
  grub)
    sed -i /etc/default/grub '/PROBER\=/s/\#//'
    efi_part=$(df | grep /boot | awk '{ print $1 }')
    grub-install ${efi_part::-1}
    grub-mkconfig -o /boot/grub/grub.cfg
    ;;
  *)
    bootctl install 
    r_id=$(blkid | grep $(df | grep /$ | awk '{ print$1 }') | cut -d\" -f2)
    echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions root=UUID=$r_id rw" > /boot/loader/entries/arch.conf   
    echo -e "title   Arch Linux (fallback initramfs)\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux-fallback.img\noptions root=UUID=$r_id rw" > /boot/loader/entries/arch-fallback.conf   
    echo -e "default  arch.conf\ntimeout  0\nconsole-mode max\neditor   no" > /boot/loader/loader.conf
    ;;
esac

pacman -S zsh
chsh -s /bin/zsh $user

sed -ne "$(grep -in '3 begins' /part2.sh | cut -d\: -f1 | tail -n1),\$p" < /part2.sh > /home/$user/part3.sh

echo "After reboot login as $user and execute [bash part3.sh]"
echo "exit or ^d"

sleep 4 && exit

# PART 2 Ends 

#===========================================================================================

# PART 3 Begins

echo "Proceeding for post install."
sleep 2 
echo "Installing Packages."
sudo pacman --noconfirm -S base-devel git libx11 libxft firefox sxiv xclip xsel xf86-input-synaptics \
  qrencode xf86-video-intel xorg-server xorg-xinit xwallpaper mpv ranger ufw vnstat \
  libnotify zsh-completions zsh-syntax-highlighting pipewire pipewire-audio pipewire-pulse\
  npm nodejs bluez bluez-utils brightnessctl cmake fzf maim man-db man-pages mlocate mpc \
  htop dunst aria2 mpd ncmpcpp tmux noto-fonts-emoji picom python python-pip python-pywal \
  python-setuptools qbittorrent telegram-desktop ttf-jetbrains-mono ttf-nerd-fonts-symbols-common \
  ttf-nerd-fonts-symbols-mono ueberzug usbutils virtualbox virtualbox-guest-utils wget yt-dlp\
  zathura zathura-pdf-mupdf xorg-xrandr unzip openssh || exit 1

echo "Setting up dots"
git clone --bare https://github.com/0xguava/dotfiles.git $HOME/.dotfiles
/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout

echo "Configuring stuff."
export DISPLAY=3
source $HOME/.zprofile

wal -s -i $HOME/.local/bin/wallhaven-lqlygq.png  

sed '/urg/d' -i $XDG_CACHE_HOME/wal/colors-wal-dwm.h
sed '31s/0/256/' -i $XDG_CACHE_HOME/wal/colors-wal-st.h
sed '24s/"[^"]*"/"#000000"/' -i $XDG_CACHE_HOME/wal/colors-wal-st.h

sed "s/.*foreground.*/$(grep foreground $XDG_CACHE_HOME/wal/colors.Xresources | head -n 1 | sed s/\*/Sxiv\./g)/" -i $XRESOURCES
sed "s/.*background.*/$(grep background $XDG_CACHE_HOME/wal/colors.Xresources | head -n 1 | sed s/\*/Sxiv\./g)/" -i $XRESOURCES 

xrdb $XRESOURCES

echo "Setting up DWM"
mkdir -p $HOME/.local/src
git clone https://github.com/0xguava/dwm.git $HOME/.local/src/dwm
git clone https://github.com/0xguava/st.git $HOME/.local/src/st
git clone https://github.com/0xguava/dmenu.git $HOME/.local/src/dmenu
git clone https://github.com/0xguava/dwmblocks.git $HOME/.local/src/dwmblocks
cd $HOME/.local/src/dwm; sudo make clean install
cd $HOME/.local/src/st; sudo make clean install
cd $HOME/.local/src/dmenu; sudo make clean install
cd $HOME/.local/src/dwmblocks; sudo make clean install || sudo make install

[ -d /etc/X11/xorg.conf.d ] || sudo mkdir -p /etc/X11/xorg.conf.d
sudo cp -r /usr/share/X11/xorg.conf.d/70-synaptics.conf /etc/X11/xorg.conf.d/.
echo "#Adi's config for touchpad
section "InputClass"
        Identifier "touchpad"
        Driver "synaptics"
        MatchIsTouchpad "on"
                Option "TapButton1" "1"
                Option "TapButton2" "3"
                Option "VertScrollDelta" "-111"
EndSection" | sudo tee -a /etc/X11/xorg.conf.d/70-synaptics.conf 



# PART 3 Ends 

#===========================================================================================
