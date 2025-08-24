#!/bin/bash

# Function to check if network bridge exists and is working
check_network_bridge() {
    if ip link show virbr0 >/dev/null 2>&1; then
        echo "[INFO] Network bridge virbr0 exists"
        return 0
    else
        echo "[INFO] Network bridge virbr0 does not exist"
        return 1
    fi
}

# Function to create manual network bridge
create_manual_bridge() {
    echo "[INFO] Creating manual network bridge..."
    
    # Create bridge
    sudo ip link add virbr0 type bridge 2>/dev/null || echo "[INFO] Bridge already exists"
    sudo ip addr add 192.168.122.1/24 dev virbr0 2>/dev/null || echo "[INFO] IP already assigned"
    sudo ip link set virbr0 up
    
    # Enable IP forwarding
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null
    
    # Add NAT rule (only if not exists)
    if ! sudo iptables-legacy -t nat -C POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE 2>/dev/null; then
        sudo iptables-legacy -t nat -A POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
        echo "[INFO] Added NAT rule"
    else
        echo "[INFO] NAT rule already exists"
    fi
    
    # Start dnsmasq for DHCP if not running
    if ! pgrep -f "dnsmasq.*virbr0" >/dev/null; then
        sudo dnsmasq --interface=virbr0 --bind-interfaces \
                     --dhcp-range=192.168.122.2,192.168.122.254,12h \
                     --except-interface=lo --listen-address=192.168.122.1 \
                     --dhcp-no-override --dhcp-authoritative \
                     --pid-file=/var/run/dnsmasq-virbr0.pid \
                     --dhcp-leasefile=/var/lib/dnsmasq/dnsmasq-virbr0.leases \
                     >/dev/null 2>&1 &
        echo "[INFO] Started DHCP server on virbr0"
    else
        echo "[INFO] DHCP server already running"
    fi
    
    sleep 2
}

# Function to try starting libvirt network
try_libvirt_network() {
    if virsh --connect qemu:///system net-info default 2>/dev/null | grep -q "Active:.*yes"; then
        echo "[INFO] Default network is already active."
        return 0
    fi
    
    echo "[INFO] Trying to start default libvirt network..."
    if virsh --connect qemu:///system net-start default 2>/dev/null; then
        virsh --connect qemu:///system net-autostart default
        echo "[INFO] Default network started successfully."
        return 0
    else
        echo "[INFO] Failed to start default network via libvirt, using manual setup."
        return 1
    fi
}

# Main network setup
echo "[INFO] Setting up network..."

# Try libvirt first, fall back to manual setup
if ! try_libvirt_network; then
    if ! check_network_bridge; then
        create_manual_bridge
    else
        echo "[INFO] Using existing network bridge"
    fi
    
    # Create libvirt network definition that uses our manual bridge
    echo "[INFO] Creating libvirt network definition for manual bridge..."
    sudo tee /tmp/manual-network.xml << 'EOF' >/dev/null
<network>
  <name>default</name>
  <bridge name='virbr0'/>
  <forward mode='nat'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

    # Remove existing and create new network definition
    virsh --connect qemu:///system net-destroy default 2>/dev/null || true
    virsh --connect qemu:///system net-undefine default 2>/dev/null || true
    if virsh --connect qemu:///system net-define /tmp/manual-network.xml 2>/dev/null; then
        virsh --connect qemu:///system net-start default 2>/dev/null || echo "[INFO] Network already active"
        virsh --connect qemu:///system net-autostart default
        echo "[INFO] Created libvirt network using manual bridge"
    else
        echo "[WARNING] Could not create libvirt network definition"
    fi
fi

# Verify network is ready
if ! ip link show virbr0 >/dev/null 2>&1; then
    echo "[WARNING] virbr0 bridge not found, trying to activate libvirt network..."
    if virsh --connect qemu:///system net-start default 2>/dev/null; then
        sleep 2
        if ip link show virbr0 >/dev/null 2>&1; then
            echo "[INFO] Network bridge activated successfully"
        else
            echo "[ERROR] Network setup failed - no virbr0 bridge after activation"
            exit 1
        fi
    else
        echo "[ERROR] Failed to activate network"
        exit 1
    fi
fi

echo "[INFO] Network setup complete"

# Start the VM
echo "[INFO] Starting VM 'win10'..."
if virsh --connect qemu:///system start win10; then
    echo "[INFO] VM started successfully"
else
    echo "[ERROR] Failed to start VM 'win10'."
    exit 1
fi

# Wait for VM to boot
echo "[INFO] Waiting 30 seconds for VM to boot..."
sleep 30

# Check if RDP target is reachable
echo "[INFO] Testing connectivity to RDP target..."
if ping -c 2 -W 3 192.168.122.34 >/dev/null 2>&1; then
    echo "[INFO] VM is reachable, connecting via RDP..."
else
    echo "[WARNING] VM might not be fully booted yet, trying RDP anyway..."
fi

# Connect via RDP
echo "[INFO] Launching RDP connection..."
xfreerdp -grab-keyboard /v:192.168.122.34 /u:win10 /p:win /size:100% /d: /dynamic-resolution /gfx-h264:avc444 +gfx-progressive &

echo "[INFO] RDP connection launched. Script completed."
