#!/bin/bash

VM_NAME="win10"
VM_IP="192.168.122.34"
USER="win10"
PASS="win"
WAIT_SECONDS=30
NOTIF_ID=9999  # Arbitrary ID for replacing notification
FREERDP_CMD="xfreerdp -grab-keyboard /v:$VM_IP /u:$USER /p:$PASS /size:100% /dynamic-resolution /gfx-h264:avc444 +gfx-progressive"

# Check if VM is already running
if virsh --connect qemu:///system domstate "$VM_NAME" | grep -q running; then
    dunstify -r $NOTIF_ID "Win10 VM" "VM already running. Connecting..."
else
    # Start VM
    dunstify -r $NOTIF_ID "Win10 VM" "Starting VM..."
    virsh --connect qemu:///system start "$VM_NAME"

    # Countdown-style wait with dynamic notification update
    for ((i=WAIT_SECONDS; i>0; i--)); do
        dunstify -r $NOTIF_ID "Win10 VM" "Waiting for VM to boot... ($i seconds left)"
        sleep 1
    done
    dunstify -r $NOTIF_ID "Win10 VM" "VM should be ready now."
fi

# Launch FreeRDP
$FREERDP_CMD &

# Monitor VM shutdown in background
(
while virsh --connect qemu:///system domstate "$VM_NAME" | grep -q running; do
    sleep 10
done

dunstify -r $NOTIF_ID "Win10 VM" "VM shut down. Stopping via virsh..."
virsh --connect qemu:///system shutdown "$VM_NAME"
) &

