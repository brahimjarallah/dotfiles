#!/bin/bash

VM_NAME="win10"
USER="win10"
PASS="win"

echo "=== Starting VM and connecting via RDP ==="

# Start VM if not running
echo "Checking VM status..."
if ! virsh --connect qemu:///system domstate "$VM_NAME" 2>/dev/null | grep -q running; then
    echo "Starting VM..."
    virsh --connect qemu:///system start "$VM_NAME"
    echo "Waiting for VM to boot..."
    sleep 45  # Give Windows time to fully boot
else
    echo "VM already running"
fi

# Function to get VM IP
get_vm_ip() {
    # Method 1: Direct query
    local ip=$(virsh --connect qemu:///system domifaddr "$VM_NAME" 2>/dev/null | grep -oE '192\.168\.122\.[0-9]+' | head -1)
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    
    # Method 2: Check DHCP leases
    ip=$(virsh --connect qemu:///system net-dhcp-leases default 2>/dev/null | grep "$VM_NAME" | awk '{print $5}' | cut -d'/' -f1)
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    
    # Method 3: ARP table
    ip=$(arp -a 2>/dev/null | grep -i "52:54:00:73:ae:f5" | grep -oE '192\.168\.122\.[0-9]+' | head -1)
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    
    # Method 4: Network scan
    echo "Scanning network..."
    for i in {2..254}; do
        test_ip="192.168.122.$i"
        if timeout 1 ping -c 1 "$test_ip" >/dev/null 2>&1; then
            echo "$test_ip"
            return 0
        fi
    done
    
    return 1
}

# Get IP address
echo "Getting VM IP address..."
VM_IP=""
for attempt in {1..6}; do
    echo "Attempt $attempt/6..."
    VM_IP=$(get_vm_ip)
    if [[ -n "$VM_IP" ]]; then
        echo "Found VM at IP: $VM_IP"
        break
    fi
    echo "No IP found, waiting 10 seconds..."
    sleep 10
done

if [[ -z "$VM_IP" ]]; then
    echo "ERROR: Could not find VM IP address!"
    echo "This usually means Windows networking is not configured properly."
    echo ""
    echo "Try these solutions:"
    echo "1. Connect to VM console: virt-viewer --connect qemu:///system $VM_NAME"
    echo "2. In Windows, check if network adapter is enabled"
    echo "3. In Windows CMD: ipconfig /renew"
    echo "4. Check if virtio network drivers are installed"
    
    # Try to open console
    if command -v virt-viewer >/dev/null 2>&1; then
        echo ""
        echo "Opening VM console for manual configuration..."
        virt-viewer --connect qemu:///system "$VM_NAME" &
    fi
    exit 1
fi

# Test RDP port
echo "Testing RDP connection to $VM_IP..."
if ! timeout 5 bash -c "</dev/tcp/$VM_IP/3389" 2>/dev/null; then
    echo "WARNING: RDP port 3389 not responding on $VM_IP"
    echo "Make sure Remote Desktop is enabled in Windows"
    echo "Opening VM console for manual configuration..."
    if command -v virt-viewer >/dev/null 2>&1; then
        virt-viewer --connect qemu:///system "$VM_NAME" &
    fi
    exit 1
fi

# Connect via RDP
echo "Connecting to $VM_IP via RDP..."
FREERDP_CMD="xfreerdp /v:$VM_IP /u:$USER /p:$PASS /cert:ignore /size:1920x1080 /dynamic-resolution +clipboard"

echo "Running: $FREERDP_CMD"
exec $FREERDP_CMD
