ifconfig wlan0 0.0.0.0 down
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
ifconfig wlan0 172.16.6.2 netmask 255.255.255.0
route add default gw 172.16.6.254
