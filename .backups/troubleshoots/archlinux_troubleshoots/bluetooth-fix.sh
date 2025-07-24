#!/bin/bash
## install bluetooth drivers :
yay -S  blueman bluez bluez-utils

# enable bluetooth service
systemctl enable --now bluetooth

# finally => go to bluetooth manager and enable bluetooth there
