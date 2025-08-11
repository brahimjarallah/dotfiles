#!/bin/bash
pid=$(ps -eo pid,%cpu --sort=-%cpu | awk 'NR==2 {print $1}')
[ -n "$pid" ] && kill -9 "$pid"

pkill -f firefox
pkill -f chrome
pkill -f electron
pkill -f code
pkill -f brave
pkill -9 -f gnome-software
