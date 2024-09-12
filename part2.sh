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
systemctl enable NetworkManager 

echo "Setting up bootloader"

case $boot_l in 
  grub)
    sed -i /etc/default/grub '/PROBER\=/s/\#//'
    grub-install ${efi_part::-1}
    grub-mkconfig -o /boot/grub/grub.cfg
    ;;
  *)
    bootctl install 
    r_id=$(blkid | grep $root_part | cut -d\" -f2)
    echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions root=UUID=$r_id rw" > /boot/loader/entries/arch.conf   
    echo -e "title   Arch Linux (fallback initramfs)\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux-fallback.img\noptions root=UUID=$r_id rw" > /boot/loader/entries/arch-fallback.conf   
    echo -e "default  arch.conf\ntimeout  0\nconsole-mode max\neditor   no" > /boot/loader/loader.conf
    ;;
esac

echo "Execute [umount -R /mnt] & Reboot."
exit

# PART 2 Ends 

#===========================================================================================

# PART 3 Begins

