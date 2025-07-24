#!/usr/bin/env bash
set -e

log() {
  echo -e "\033[1;32m[+]\033[0m $1"
}

log "Updating system..."
sudo pacman -Sy --noconfirm

log "Installing virtualization packages (iptables conflict avoided)..."
# Replace iptables with iptables-nft
sudo pacman -S iptables-nft

# Then install the virtualization packages
sudo pacman -S --noconfirm \
  virt-manager \
  qemu-full \
  libvirt \
  edk2-ovmf \
  dnsmasq \
  bridge-utils \
  virt-viewer \
  ebtables \
  dmidecode \
  swtpm \
  ovmf

log "Starting and enabling libvirt service..."
sudo systemctl enable --now libvirtd.service

log "Adding user to kvm and libvirt groups..."
sudo usermod -aG libvirt,kvm "$USER"

log "Enabling nested virtualization (Intel only)..."
if grep -q vmx /proc/cpuinfo; then
  echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf
  sudo modprobe -r kvm_intel || true
  sudo modprobe kvm_intel
fi

log "Copying OVMF firmware vars for Windows VM..."
sudo mkdir -p /etc/libvirt/qemu/nvram
sudo cp /usr/share/edk2/x64/OVMF_VARS.fd /etc/libvirt/qemu/nvram/Win10_VARS.fd

log "Enabling IOMMU for performance/passthrough..."
if ! grep -q "intel_iommu=on" /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& intel_iommu=on iommu=pt/' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  log "⚠️ Reboot required for IOMMU to apply."
fi

log "Configuring hugepages (performance tuning)..."
echo "vm.nr_hugepages=512" | sudo tee /etc/sysctl.d/99-hugepages.conf
sudo sysctl --system

log "Ensuring libvirt default network starts..."
sudo virsh net-autostart default
sudo virsh net-start default

log "✅ Setup complete!"
echo -e "\n\033[1;34m👉 Next steps:\033[0m"
echo "- 🔁 Reboot your system (for IOMMU + group changes)"
echo "- 🔧 Launch virt-manager: \033[1mvirt-manager\033[0m"
echo "- 🪟 Create a Windows 10 VM using UEFI + VirtIO + 3D acceleration"
echo "- 💡 For 3D modeling, enable host-passthrough CPU + max RAM/VRAM"


