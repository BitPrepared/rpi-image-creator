#!/bin/bash

# enable SSH
#touch /boot/ssh

# add temporary password
echo 'pi:r3notaRE' | chpasswd

# enable zswap with default settings e modules-load=dwc2,g_ether
sed -i -e 's/$/ zswap.enabled=1 modules-load=dwc2,g_ether/' /boot/cmdline.txt

#otg
sed -i -e 's/$/ dtoverlay=dwc2 /' /boot/config.txt

# force automatic rootfs expansion on first boot:
# https://forums.raspberrypi.com/viewtopic.php?t=174434#p1117084
#wget -O /etc/init.d/resize2fs_once https://raw.githubusercontent.com/RPi-Distro/pi-gen/master/stage2/01-sys-tweaks/files/resize2fs_once
#chmod +x /etc/init.d/resize2fs_once
#systemctl enable resize2fs_once