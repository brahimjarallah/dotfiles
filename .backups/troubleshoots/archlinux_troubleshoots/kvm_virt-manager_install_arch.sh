# sudo pacman -S qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat libguestfs
# sudo pacman -Syy
# sudo pacman -S archlinux-keyring

sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo systemctl status libvirtd.service

sudo sed -i '85s/.//' /etc/libvirt/libvirtd.conf
sudo sed -i '108s/.//' /etc/libvirt/libvirtd.conf

# -- uncomment these:
# sudo vim /etc/libvirt/libvirtd.conf
# unix_sock_group = "libvirt"
# unix_sock_rw_perms = "0770"


sudo newgrp libvirt
sudo usermod -a -G libvirt $(whoami)

sudo systemctl restart libvirtd.service

### Intel Processor ###
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel nested=1

sudo echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf

### Intel Processor ###
#$ systool -m kvm_intel -v | grep nested
#    nested              = "Y"

sudo cat /sys/module/kvm_amd/parameters/nested 
#Y

#reboot
