#!/bin/bash

#===========================================================================================

# PART 1 Begins

set -e
# shopt -s nullglob
config=$PWD/config.json

# echo "NOTE: Partioning should be done before proceeding."
# read -p "Proceed? [y/n]: " yn

# if [ $yn != "y" ]
# then
#   exit 1
# fi

disk=/dev/$(lsblk -dn -o NAME /dev/{*d[a-z],nvme[0-9]n[0-9]} 2> /dev/null | head -n1)
disk_type=$(lsblk -dn -o NAME /dev/{*d[a-z],nvme[0-9]n[0-9]} 2> /dev/null | head -n1)
disk_size=$(lsblk -dn -o SIZE /dev/{*d[a-z],nvme[0-9]n[0-9]} 2> /dev/null | head -n1)

parted -s $disk mklabel gpt
parted -s $disk -a opt mkpart efi fat32 1MiB 512MiB
parted -s $disk -a opt mkpart rootfs ext4 513MiB 100% 

if [[ "$disk_type" =~ nvme* ]]; then
  efi_part=${disk}p1
  root_part=${disk}p2
else
  efi_part=${disk}1
  root_part=${disk}2
fi

# echo -e "\n1.Grub\n2.Systemd-boot"
# read -p "Select bootloader [1/2]: " yn2

# read -p "EFI partition: " efi_part
echo "Formatting efi partition to fat32"
mkfs.fat -F 32 $efi_part

# read -p "Is swap partition required [y/n]: " yn1
# if [ $yn1 == "y" ]
# then
#   read -p "Swap partition: " swap_part
#   echo "Creating swap"
#   mkswap $swap_part
# fi

# read -p "Root partition: " root_part
echo "Formatting root partition to ext4"
mkfs.ext4 -F $root_part

echo "Mounting root."
mount $root_part /mnt 

echo "Mounting efi"
# case $yn2 in
#   1)
    # boot_l='grub' 
    mount --mkdir $efi_part /mnt/boot/efi
#     ;;
#   *)
#     boot_l=''
#     mount --mkdir $efi_part /mnt/boot
#     ;;
# esac

# if [ $yn1 == "y" ]
# then
#   echo "Mounting swap"
#   swapon $swap_part
# fi

# pacman-key --init
pacman -Sy --noconfirm archlinux-keyring jq

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -c "India" --sort=rate > /etc/pacman.d/mirrorlist

echo "Installing packages."
pacstrap /mnt base linux linux-firmware grub git efibootmgr neovim networkmanager sudo \
  base-devel git ufw vnstat cmake fzf man-db man-pages unzip openssh 


echo "Generating fstab and storing it."
genfstab -U /mnt >> /mnt/etc/fstab

# sed -ne "$(grep -in '2 begins' $PWD/auto-install/arch.sh | cut -d\: -f1 | tail -n1),\$p" < $PWD/auto-install/arch.sh > /mnt/part2.sh

# echo "Execute [bash part2.sh]" 

# arch-chroot /mnt


# PART 1 Ends 

#===========================================================================================

# PART 2 Begins

echo "Setting up"

echo "LANG=en_IN.UTF-8" > /mnt/etc/locale.conf

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
arch-chroot /mnt hwclock --systohc

# read -p "Enter hostname: " h_name
h_name=$(jq -r '.hostname' $config)
echo $h_name > /mnt/etc/hostname

echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\tlocalhost.localdomain\t$h_name" >> /mnt/etc/hosts

echo "Setting up password for root user"
echo "root:$(jq -r '.credentials.rootpassword' $config)" | chpasswd --root /mnt

# read -p "Add user [y/n]: " yn3
yn3=$(jq -r '.adduser' $config)
if [ $yn3 == y ]
then
  # read -p "Username: " user 
  user=$(jq -r '.credentials.username' $config)
  arch-chroot /mnt useradd -m -G wheel -s /bin/bash $user
  echo "Setting password for $user"
  echo "$user:$(jq -r '.credentials.password' $config)" | chpasswd --root /mnt
  arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo"
fi

arch-chroot /mnt systemctl enable NetworkManager 

echo "Setting up bootloader"
# [ -n "$(pacman -Qs grub)" ] && boot_l=grub
# case $boot_l in 
#   grub)
  #  sed -i /mnt/etc/default/grub '/PROBER\=/s/\#//'
    # efi_part=$(df | grep /mnt/boot | awk '{ print $1 }')
    arch-chroot /mnt grub-install ${efi_part::-1}
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
#     ;;
#   *)
#     arch-chroot /mnt bootctl install 
#     r_id=$(blkid | grep $(df | grep /mnt$ | awk '{ print$1 }') | cut -d\" -f2)
#     echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions root=UUID=$r_id rw" > /mnt/boot/loader/entries/arch.conf   
#     echo -e "title   Arch Linux (fallback initramfs)\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux-fallback.img\noptions root=UUID=$r_id rw" > /mnt/boot/loader/entries/arch-fallback.conf   
#     echo -e "default  arch.conf\ntimeout  0\nconsole-mode max\neditor   no" > /mnt/boot/loader/loader.conf
#     ;;
# esac

#[ -z $user ] && pth='/mnt/root' || pth="/mnt/home/$user"

# sed -ne "$(grep -in '3 begins' $PWD/part2.sh | cut -d\: -f1 | tail -n1),\$p" < $PWD/part2.sh > $pth/part3.sh

# echo "After reboot login as $user and execute [bash part3.sh]"
# echo "exit or ^d"

# exit

# PART 2 Ends 

#===========================================================================================

# PART 3 Begins

# echo "Proceeding for user's daily setup."
# sleep 2 
# echo "Installing Packages."

# echo "Setting up dots"
# arch-chroot /mnt git clone --bare https://github.com/0xguava/dotfiles.git $pth/.dotfiles
# arch-chroot /mnt /usr/bin/git --git-dir=$pth/.dotfiles/ --work-tree=$pth checkout

# echo "Configuring stuff."
# export DISPLAY=3
# source $pth/.zprofile 2> /dev/null

# aux_pth="/$(echo $pth | cut -d \/ -f3-)"

# arch-chroot /mnt wal -s -i $aux_pth/.local/share/inff/wallp.png  

# echo "Setting up DWM"
# mkdir -p $pth/.local/src
# git clone https://github.com/0xguava/dwm.git $pth/.local/src/dwm
# git clone https://github.com/0xguava/st.git $pth/.local/src/st
# git clone https://github.com/0xguava/dmenu.git $pth/.local/src/dmenu
# git clone https://github.com/0xguava/dwmblocks.git $pth/.local/src/dwmblocks

# arch-chroot /mnt bash -c "cd $aux_pth/.local/src/dwm; sudo make clean install"
# arch-chroot /mnt bash -c "cd $aux_pth/.local/src/st; sudo make clean install"
# arch-chroot /mnt bash -c "cd $aux_pth/.local/src/dmenu; sudo make clean install"
#
# arch-chroot /mnt bash -c "cd $pth/.local/src/dwmblocks; sudo make clean install || sudo make install"
#
# [ -d /mnt/etc/X11/xorg.conf.d ] || sudo mkdir -p /mnt/etc/X11/xorg.conf.d
# sudo cp -r /mnt/usr/share/X11/xorg.conf.d/70-synaptics.conf /mnt/etc/X11/xorg.conf.d/.
# echo "#Adi's config for touchpad
# section \"InputClass\"
#         Identifier \"touchpad\"
#         Driver \"synaptics\"
#         MatchIsTouchpad \"on\"
#                 Option \"TapButton1\" \"1\"
#                 Option \"TapButton2\" \"3\"
#                 Option \"VertScrollDelta\" \"-111\"
# EndSection" | sudo tee -a /mnt/etc/X11/xorg.conf.d/70-synaptics.conf 

# echo "Wrapping up"
# sudo rm -rf /part2.sh 
# sudo rm -rf $HOME/.bash*
# sudo rm -rf $HOME/part3.sh

echo "Relogin or execute [startx] to see MAGIC"

echo "Unmounting."
umount -R /mnt 

reboot && exit 0 

# PART 3 Ends 

#===========================================================================================
