#!/bin/bash

# install freerdp2
#sudo pacman -S freerdp2

# The startup freerdp command is:
#xfreerdp -grab-keyboard /v:YOURIP /u:raabe /p:YOURPASSWORD /size:100% /d: /dynamic-resolution /gfx-h264:avc444 +gfx-progressive

virsh --connect qemu:///system start win10

sleep 30

xfreerdp -grab-keyboard /v:192.168.122.34 /u:win10 /p:win /size:100% /d: /dynamic-resolution /gfx-h264:avc444 +gfx-progressive &


