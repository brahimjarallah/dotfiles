#!/bin/bash

# VFIO Setup Script for NVIDIA MX130 GPU Passthrough

echo "Setting up VFIO for GPU passthrough..."

# 1. Create VFIO modprobe configuration
sudo tee /etc/modprobe.d/vfio.conf > /dev/null << 'EOF'
# NVIDIA MX130 GPU
options vfio-pci ids=10de:174d

# Blacklist NVIDIA drivers for the GPU
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
EOF

# 2. Create VFIO modules configuration
sudo tee /etc/modules-load.d/vfio.conf > /dev/null << 'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF

# 3. Update initramfs
echo "Updating initramfs..."
sudo mkinitcpio -P

# 4. Create libvirt hooks directory
sudo mkdir -p /etc/libvirt/hooks

# 5. Create VFIO hook script for better GPU isolation
sudo tee /etc/libvirt/hooks/qemu > /dev/null << 'EOF'
#!/bin/bash

GUEST_NAME="$1"
HOOK_NAME="$2"
STATE_NAME="$3"
MISC="${@:4}"

BASEDIR="$(dirname $0)"

HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"

set -e # If a script exits with an error, we should as well.

if [ -f "$HOOKPATH" ]; then
    eval \""$HOOKPATH"\" "$@"
elif [ -d "$HOOKPATH" ]; then
    while read file; do
        eval \""$file"\" "$@"
    done <<< "$(find "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
fi
EOF

# Make hook executable
sudo chmod +x /etc/libvirt/hooks/qemu

# 6. Create VM-specific hook directories
sudo mkdir -p /etc/libvirt/hooks/qemu.d/win10/prepare/begin
sudo mkdir -p /etc/libvirt/hooks/qemu.d/win10/release/end

# 7. Create start script (isolate GPU)
sudo tee /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh > /dev/null << 'EOF'
#!/bin/bash

# Debugging
set -x

# Stop display manager
systemctl stop display-manager.service

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Avoid a race condition by waiting 2 seconds
sleep 2

# Unload NVIDIA drivers
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r nvidia_uvm
modprobe -r nvidia

# Unbind the GPU from display driver
echo "0000:01:00.0" > /sys/bus/pci/devices/0000:01:00.0/driver/unbind

# Load VFIO drivers
modprobe vfio-pci
EOF

# 8. Create stop script (return GPU to host)
sudo tee /etc/libvirt/hooks/qemu.d/win10/release/end/stop.sh > /dev/null << 'EOF'
#!/bin/bash

# Debugging
set -x

# Unload VFIO drivers
modprobe -r vfio-pci

# Rebind GPU to nvidia
echo "0000:01:00.0" > /sys/bus/pci/drivers/vfio-pci/unbind
echo "0000:01:00.0" > /sys/bus/pci/drivers/nvidia/bind

# Load nvidia drivers
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Rebind VTconsoles
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Rebind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

# Restart display manager
systemctl start display-manager.service
EOF

# Make scripts executable
sudo chmod +x /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
sudo chmod +x /etc/libvirt/hooks/qemu.d/win10/release/end/stop.sh

echo "VFIO setup complete!"
echo "Please reboot your system and then run the verification script."
