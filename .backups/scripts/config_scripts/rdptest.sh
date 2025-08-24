#!/bin/bash
VM_NAME="win10"
USER="win10"
PASS="win"
WAIT_SECONDS=30
NOTIF_ID=9999
LOG_FILE="/tmp/freerdp_debug.log"

# Function to get VM IP dynamically
get_vm_ip() {
    local ip=""
    local mac="52:54:00:73:ae:f5"  # Your VM's MAC address
    
    # Method 1: virsh domifaddr
    ip=$(virsh --connect qemu:///system domifaddr "$VM_NAME" 2>/dev/null | grep -oE '192\.168\.122\.[0-9]+' | head -1)
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    
    # Method 2: DHCP leases
    ip=$(virsh --connect qemu:///system net-dhcp-leases default 2>/dev/null | grep "$VM_NAME" | awk '{print $5}' | cut -d'/' -f1)
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    
    # Method 3: Check ARP table for VM's MAC address
    ip=$(arp -a | grep -i "$mac" | grep -oE '192\.168\.122\.[0-9]+' | head -1)
    if [[ -n "$ip" ]]; then
        echo "Found IP via ARP: $ip" >&2
        echo "$ip"
        return 0
    fi
    
    # Method 4: Scan for any responding IPs in the range
    echo "Scanning network range for responding hosts..." >&2
    for i in {2..254}; do
        test_ip="192.168.122.$i"
        if timeout 1 ping -c 1 "$test_ip" >/dev/null 2>&1; then
            echo "Found responding host at $test_ip" >&2
            echo "$test_ip"
            return 0
        fi
    done
    
    # Method 5: Check for APIPA (169.254.x.x) addresses
    echo "Checking for APIPA addresses..." >&2
    ip=$(arp -a | grep -i "$mac" | grep -oE '169\.254\.[0-9]+\.[0-9]+' | head -1)
    if [[ -n "$ip" ]]; then
        echo "Found APIPA address: $ip (Windows networking issue)" >&2
        echo "$ip"
        return 0
    fi
    
    return 1
}

# Function to check if RDP port is open
check_rdp_port() {
    local ip="$1"
    timeout 5 bash -c "</dev/tcp/$ip/3389" 2>/dev/null
    return $?
}

# Check libvirt network status
echo "Checking libvirt network..." | tee $LOG_FILE
if ! virsh --connect qemu:///system net-list | grep -q "default.*active"; then
    echo "Starting libvirt default network..." | tee -a $LOG_FILE
    sudo virsh --connect qemu:///system net-start default
fi

# Check if VM is already running
if virsh --connect qemu:///system domstate "$VM_NAME" | grep -q running; then
    dunstify -r $NOTIF_ID "Win10 VM" "VM already running. Getting IP address..."
    echo "VM already running" | tee -a $LOG_FILE
else
    # Start VM
    dunstify -r $NOTIF_ID "Win10 VM" "Starting VM..."
    echo "Starting VM..." | tee -a $LOG_FILE
    virsh --connect qemu:///system start "$VM_NAME"
    
    # Countdown-style wait
    for ((i=WAIT_SECONDS; i>0; i--)); do
        dunstify -r $NOTIF_ID "Win10 VM" "Waiting for VM to boot... ($i seconds left)"
        sleep 1
    done
fi

# Get VM IP address
echo "Getting VM IP address..." | tee -a $LOG_FILE
VM_IP=""
for ((i=0; i<10; i++)); do
    VM_IP=$(get_vm_ip)
    if [[ -n "$VM_IP" ]]; then
        echo "Found VM IP: $VM_IP" | tee -a $LOG_FILE
        break
    fi
    echo "Waiting for VM to get IP address... (attempt $((i+1))/10)" | tee -a $LOG_FILE
    sleep 3
done

if [[ -z "$VM_IP" ]]; then
    dunstify -r $NOTIF_ID "Win10 VM" "ERROR: Could not get VM IP address!"
    echo "ERROR: Could not determine VM IP address" | tee -a $LOG_FILE
    echo "This usually means:" | tee -a $LOG_FILE
    echo "  1. Windows network adapter is disabled" | tee -a $LOG_FILE
    echo "  2. Network drivers not installed in Windows" | tee -a $LOG_FILE
    echo "  3. VM network interface not properly configured" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "Try accessing VM console with: virt-viewer $VM_NAME" | tee -a $LOG_FILE
    echo "Or check network config with: virsh domiflist $VM_NAME" | tee -a $LOG_FILE
    
    # Try to open virt-viewer as fallback
    if command -v virt-viewer >/dev/null 2>&1; then
        echo "Opening VM console with virt-viewer..." | tee -a $LOG_FILE
        dunstify -r $NOTIF_ID "Win10 VM" "Opening VM console to check network..."
        virt-viewer --connect qemu:///system "$VM_NAME" &
    fi
    exit 1
fi

# Updated FreeRDP command
FREERDP_CMD="xfreerdp /v:$VM_IP /u:$USER /p:$PASS /cert:ignore /size:1920x1080 /dynamic-resolution /gfx:avc444 +clipboard +drives"

# Wait for RDP port to be available
echo "Waiting for RDP service on $VM_IP..." | tee -a $LOG_FILE
for ((i=0; i<30; i++)); do
    if check_rdp_port "$VM_IP"; then
        echo "RDP port is open on $VM_IP!" | tee -a $LOG_FILE
        break
    fi
    echo "RDP port not ready, retrying... ($((30-i)) attempts left)" | tee -a $LOG_FILE
    sleep 2
done

# Final check before connecting
if ! check_rdp_port "$VM_IP"; then
    dunstify -r $NOTIF_ID "Win10 VM" "ERROR: RDP service not available on $VM_IP!"
    echo "ERROR: Cannot connect to RDP port 3389 on $VM_IP" | tee -a $LOG_FILE
    echo "VM might still be booting or RDP is not enabled" | tee -a $LOG_FILE
    exit 1
fi

dunstify -r $NOTIF_ID "Win10 VM" "Connecting to $VM_IP via RDP..."
echo "Launching FreeRDP: $FREERDP_CMD" | tee -a $LOG_FILE

# Launch FreeRDP
$FREERDP_CMD 2>&1 | tee -a $LOG_FILE &
FREERDP_PID=$!

# Monitor VM shutdown in background
(
while virsh --connect qemu:///system domstate "$VM_NAME" | grep -q running; do
    sleep 10
done
dunstify -r $NOTIF_ID "Win10 VM" "VM shut down. Stopping via virsh..."
virsh --connect qemu:///system shutdown "$VM_NAME"
kill $FREERDP_PID 2>/dev/null
) &
