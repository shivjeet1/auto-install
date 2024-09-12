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
pacstrap -i /mnt base linux linux-firmware base-devel $boot_l efibootmgr openssh neovim networkmanager git

echo "Generating fstab and storing it."
genfstab -U /mnt >> /mnt/etc/fstab

sed -ne "$(grep -in '2 begins' arch.sh | cut -d\: -f1 | tail -n1),\$p" < arch.sh > /mnt/part2.sh

echo "Execute [bash part2.sh]" 

arch-chroot /mnt

echo "Umounting."
umount -R /mnt 

echo lolololo && exit 0 

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
[ -n "$(pacman -Qs grub)"] && boot_l=grub
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

exit 0

# PART 2 Ends 

#===========================================================================================

# PART 3 Begins

