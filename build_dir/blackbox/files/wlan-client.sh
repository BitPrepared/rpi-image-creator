ifconfig wlan0 0.0.0.0 down
wpa_supplicant -B -i wlan0 -c /root/wpa-bitprepared.conf
ifconfig wlan0 172.16.6.2 netmask 255.255.255.0
