#!/bin/bash

# Access point together with a wireless client connection is possible thanks to raspberry pi wifi device.
# Device is compatible with the 802.11n standard (dual-band 2.4GHz).
# The 802.11n standard uses 2 channels to double the communication capacity.
# Here we use each of the channels for a desired functionality.
# One for Access Point (AP), the other for wifi (WLAN),
# This is the reason why it is not possible to be compatible with a wireless network
# using more than one wifi channel.

# to test capability of device you can check with command
# sudo iw list | grep -A4 "valid interface combinations:"
# You need to see somethink like: #{ managed } <= 1, #{ AP } <= 1,

# Target is:
#                  wifi                         wifi uplink         wan
# mobile-phone <~.~.~.~.~> (ap@wlan0)RPi(wlan0) <.~.~.~.~.> router <───> INTERNET
#             ╲             ╱               ╲
#            (dhcp    172.20.1.1           (dhcp
#          from RPi)                    from router)

#----------------
# to list wifi do:
# sudo iwlist wlan0 scan | grep SSID | cut -d':' -f2 | sed 's/"//g'
#-----------------
# to configure new wireless
# update /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
# and set:
# network={
#    ssid="YOUR WIFI SSID"
#    psk="WIFI PASSWORD"
# }
#
# to do that at first time you can do something like:
# wpa_passphrase "YOUR WIFI SSID" "WIFI PASSWORD" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
#
#------------------
# After setting new parameter reload configuration file with:
# wpa_cli -i wlan0 reconfigure

# Store all input options in an array:
options=("$@")
#echo "Input options are: ${options[@]}"

apIpDefault="172.20.1.1"
apDhcpRangeDefault="172.20.1.50,172.20.1.100,12h"
apCountryCodeDefault="FR"
apChannelDefault="1"
apIpCloud="54.38.42.84"

apIp="$apIpDefault"
apDhcpRange="$apDhcpRangeDefault"
apCountryCode="$apCountryCodeDefault"
apChannel="$apChannelDefault"
apSsid=""
apPasswordConfig=""

apCountryCodeValid=true
apIpAddrValid=true
apSsidValid=false
apPassphraseValid=false

# REFERENCE: https://en.wikipedia.org/wiki/Private_network#Private_IPv4_addresses
# Visit above site to know more about Reserved Private IP Address for LAN/WLAN communication.
function validIpAddress()
{
    local  ip=$1
    local  status=1
    if [[ $ip =~ ^(10|172|192)\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        
        IFS='.' read ipi1 ipi2 ipi3 ipi4 <<< "$ip"
        IFS='.' read -r -a wlanIpMaskArr <<< "$wlanIpMask"
        IFS='.' read -r -a wlanIpAddrArr <<< "$wlanIpAddr"
        
        wlanIpStartWith=""
        wlanIpStartWithCount=0
        
        for i in ${!wlanIpMaskArr[@]}; do
	        mskVal=${wlanIpMaskArr[$i]}
            if [ $mskVal == 255 ]; then
                if [ -z "$wlanIpStartWith" ]; then
                    wlanIpStartWith="${wlanIpAddrArr[$i]}"
                else
                    wlanIpStartWith="$wlanIpStartWith.${wlanIpAddrArr[$i]}"
                fi
                wlanIpStartWithCount=$((wlanIpStartWithCount+1))
            fi
        done
        
        wlanIpStartWith="$wlanIpStartWith."
        
        case $ipi1 in
        10) 
            [[ ( $ip != $wlanIpAddr && ! $ip =~ ${wlanIpStartWith}* ) && \
                ((${#ipi2} -eq 1 && ${ipi2} -le 255) || (${#ipi2} -gt 1 && "${ipi2}" != 0* && ${ipi2} -le 255)) && \
                ((${#ipi3} -eq 1 && ${ipi3} -le 255) || (${#ipi3} -gt 1 && "${ipi3}" != 0* && ${ipi3} -le 255)) && \
                ((${#ipi4} -eq 1 && ${ipi4} -le 255) || (${#ipi4} -gt 1 && "${ipi4}" != 0* && ${ipi4} -le 255))
             ]]
            status=$?
        ;;
        172) 
            [[  ( $ip != $wlanIpAddr && ! $ip =~ ${wlanIpStartWith}* ) && \
                ("${ipi2}" != 0* && ${ipi2} -ge 16 && ${ipi2} -le 31) && \
                ((${#ipi3} -eq 1 && ${ipi3} -le 255) || (${#ipi3} -gt 1 && "${ipi3}" != 0* && ${ipi3} -le 255)) && \
                ((${#ipi4} -eq 1 && ${ipi4} -le 255) || (${#ipi4} -gt 1 && "${ipi4}" != 0* && ${ipi4} -le 255))
             ]]
            status=$?
        ;;
        192) 
            [[  ( $ip != $wlanIpAddr && ! $ip =~ ${wlanIpStartWith}* ) && \
                ("${ipi2}" != 0* && ${ipi2} -eq 168) && \
                ((${#ipi3} -eq 1 && ${ipi3} -le 255) || (${#ipi3} -gt 1 && "${ipi3}" != 0* && ${ipi3} -le 255)) && \
                ((${#ipi4} -eq 1 && ${ipi4} -le 255) || (${#ipi4} -gt 1 && "${ipi4}" != 0* && ${ipi4} -le 255))
             ]]
            status=$?
        ;;
        esac
    fi
    return $status
}


for i in ${!options[@]}; do

    option="${options[$i]}"
    
    if [[ "$option" == --ap-ssid=* ]]; then
        apSsid="$(echo $option | awk -F '=' '{print $2}')"
        if [[ "$apSsid" =~ ^[A-Za-z0-9_-]{3,}$ ]]; then
            apSsidValid=true
        fi
    fi
    
    if [[ "$option" == --ap-password=* ]]; then
            apPassphrase="$(echo $option | awk -F '=' '{print $2}')"
        if [[ "$apPassphrase" =~ ^[A-Za-z0-9@#$%^\&*_+-]{8,}$ ]]; then
                apPassphraseValid=true
        fi
    fi
    
    if [[ "$option" == --ap-country-code=* ]]; then
	    apCountryCodeTemp="$(echo $option | awk -F '=' '{print $2}')"
	    if [ ! -z "$apCountryCodeTemp" ]; then
            if [[ "${countryCodeArray[@]}" =~ "${apCountryCodeTemp}" ]]; then
                if [[ ! -z "${wlanCountryCode}" && \
                    (( ! "${countryCodeArray[@]}" =~ "${wlanCountryCode}") || \
                    ( ! "${apCountryCodeTemp}" =~ "${wlanCountryCode}")) ]]; then
                    apCountryCodeValid=false
                else
                    apCountryCodeValid=true
                    apCountryCode="$apCountryCodeTemp"
                fi
            else
                apCountryCodeValid=false
            fi
        fi
    fi
    
    if [[ "$option" == --ap-ip-address=* ]]; then
        apIpAddrTemp="$(echo $option | awk -F '=' '{print $2}')"
        if [ ! -z "$apIpAddrTemp" ]; then
            if validIpAddress "$apIpAddrTemp"; then
                apIpAddrValid=true
                # Successful validation. Now set apIp, apDhcpRange and apSetupIptablesMasquerade:
                apIp="$apIpAddrTemp"
            else
                apIpAddrValid=false
            fi
        fi
    fi
done

# Process AP Password encryption:
for i in ${!options[@]}; do
    option="${options[$i]}"
    if [ "$apSsidValid" = true -a "$apPassphraseValid" = true ]; then
	    apWpaPsk="$( wpa_passphrase ${apSsid} ${apPassphrase} | awk '{$1=$1};1' | grep -P '^psk=' | awk -F '=' '{print $2}' )"
	    apPasswordConfig="wpa_psk=$apWpaPsk"
    fi
done

if [ "$apIpAddrValid" = true ]; then
                IFS='.' read -r -a apIpArr <<< "$apIp"
                apIpSubnetSize=24
                apIpFirstThreeDigits="${apIpArr[0]}.${apIpArr[1]}.${apIpArr[2]}"
                apIpLastDigit=${apIpArr[3]}
                div=$((apIpLastDigit/100))
                minCalcDigit=1
                maxCalcDigit=100
                
                case $div in
                # Between (0-99)
                0) minCalcDigit=$((apIpLastDigit+1)); maxCalcDigit=$((minCalcDigit+100)) ;;
                # Between (100-199)
                1) minCalcDigit=$((200-apIpLastDigit)); maxCalcDigit=$((minCalcDigit+100)) ;;
                # Between (200-255)
                2) minCalcDigit=$((256-apIpLastDigit)); maxCalcDigit=$((minCalcDigit+100)) ;;
                *) minCalcDigit=1; maxCalcDigit=100 ;;
                esac
                
                case ${apIpArr[0]} in
                10) apIpSubnetSize=24 ;;
                172) apIpSubnetSize=20 ;;
                192) apIpSubnetSize=16 ;;
                *) apIpSubnetSize=24 ;;
                esac
                
                apDhcpRange="${apIpFirstThreeDigits}.${minCalcDigit},${apIpFirstThreeDigits}.${maxCalcDigit},12h"
fi

if [ "$apSsidValid" = false -o "$apPassphraseValid" = false \
    -o "$apCountryCodeValid" = false -o "$apIpAddrValid" = false ]; then

echo '
--ap-ssid              Mandatory field for installation: Set Access Point(AP) SSID. Atleast 3 chars long.
                       Allowed special chars are: _ -
'

echo '
--ap-password          Mandatory field for installation: Set Access Point(AP) Password. Atleast 8 chars long.
                       Allowed special chars are: @ # $ %% ^ & * _ + -
'

echo '
--ap-country-code      Optional field for installation: Set Access Point(AP) Country Code. Default value is: '$apCountryCodeDefault'. 
                       Make sure that  the entered Country Code matches WiFi Country Code if it exists in /etc/wpa_supplicant/wpa_supplicant.conf
                       Allowed Country codes, look at https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
'

echo '
--ap-ip-address        Optional field for installation: Set Access Point(AP) IP Address. Default value is: '$apIpDefault'.
                       LAN/WLAN reserved private Access Point(AP) IP address must in the below range:
                       [10.0.0.0 - 10.255.255.255] or [172.16.0.0 - 172.31.255.255] or [192.168.0.0 - 192.168.255.255]
                       (Refer site: https://en.wikipedia.org/wiki/Private_network#Private_IPv4_addresses to know more 
                       about above IP address range).
                       Access Point(AP) IP address must not be equal to WiFi Station.
'

    exit 1
fi
#================================
#echo "IP: $apIp/$apIpSubnetSize"
#echo "DHCP range: $apDhcpRange"
#echo "SSID: $apSsid, pwd:${apPassphrase}"
#echo "encrypt pwd: $apWpaPsk"
#echo "Country code: $apCountryCode"

#exit 0
#================================

apt update && apt upgrade -y

echo "-----------------------------"
echo " Network install in progress"
echo "-----------------------------"

########################################################
# deinstall classic networking (works out of the box)
apt --autoremove purge ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog -y
apt-mark hold ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog raspberrypi-net-mods openresolv
rm -r /etc/network /etc/dhcp

########################################################
# setup/enable systemd-resolved and systemd-networkd

apt --autoremove purge avahi-daemon -y
apt-mark hold avahi-daemon libnss-mdns
apt install libnss-resolve -y
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable systemd-networkd.service systemd-resolved.service

########################################################
# set configuration file to ethernet with dynamic DHCP adress

cat > /etc/systemd/network/04-wired.network <<EOF
[Match]
Name=e*

[Network]
## Uncomment only one option block
# Option: using a DHCP server and multicast DNS
LLMNR=no
LinkLocalAddressing=no
MulticastDNS=yes
DHCP=ipv4

# Option: using link-local ip addresses and multicast DNS
#LLMNR=no
#LinkLocalAddressing=yes
#MulticastDNS=yes

# Option: using static ip address and multicast DNS
# (example, use your settings)
#Address=192.168.50.60/24
#Gateway=192.168.50.1
#DNS=8.8.8.8 1.1.1.1
#MulticastDNS=yes
EOF

########################################################
# set configuration file to wireless with dynamic DHCP address

cat > /etc/systemd/network/08-wifi.network <<EOF
[Match]
Name=wl*

[Network]
## Uncomment only one option block
# Option: using a DHCP server and multicast DNS
LLMNR=no
LinkLocalAddressing=no
MulticastDNS=yes
DHCP=ipv4

# Option: using link-local ip addresses and multicast DNS
#LLMNR=no
#LinkLocalAddressing=yes
#MulticastDNS=yes

# Option: using static ip address and multicast DNS
# (example, use your settings)
#Address=192.168.50.61/24
#Gateway=192.168.50.1
#DNS=8.8.8.8 1.1.1.1
#MulticastDNS=yes
EOF

################################################################
# Set Access Point

apt install hostapd -y

cat > /etc/hostapd/hostapd.conf <<EOF
driver=nl80211
ssid=$apSsid
$apPasswordConfig
country_code=$apCountryCode
ignore_broadcast_ssid=0
hw_mode=g
channel=1
auth_algs=1
# Without WPA
wpa=0
# Wth WPA
#wpa=2
#wpa_key_mgmt=WPA-PSK
#wpa_pairwise=TKIP
#rsn_pairwise=CCMP
# Enable hostapd_cli
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
EOF

chmod 600 /etc/hostapd/hostapd.conf

cat > /etc/systemd/system/accesspoint@.service <<EOF
[Unit]
Description=accesspoint with hostapd (interface-specific version)
Wants=wpa_supplicant@%i.service

[Service]
ExecStartPre=/sbin/iw dev %i interface add ap@%i type __ap
ExecStart=/usr/sbin/hostapd -i ap@%i /etc/hostapd/hostapd.conf
ExecStopPost=-/sbin/iw dev ap@%i del

[Install]
WantedBy=sys-subsystem-net-devices-%i.device
EOF

systemctl enable accesspoint@wlan0.service
rfkill unblock wlan


################################################################
# Set Wireless configuration (wpa_supplicant to client connection)
# Note to obtain hiding password you can do:
# wpa_passphrase YOUR_SSID YOUR_PASSWORD

cat >/etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF
country=FR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

EOF

chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
systemctl disable wpa_supplicant.service
mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.orig

###############################################################
# Extend wpa_supplicant

SYSTEMD_EDITOR=tee systemctl edit wpa_supplicant@wlan0.service <<EOF
[Unit]
BindsTo=accesspoint@%i.service
After=accesspoint@%i.service
EOF

###############################################################
# Define AP static configuration

cat > /etc/systemd/network/12-ap.network <<EOF
[Match]
Name=ap@*

[Network]
LLMNR=no
MulticastDNS=yes
IPMasquerade=yes
Address=$apIp/$apIpSubnetSize
DHCPServer=yes

#[DHCPServer]
#DNS=8.8.8.8 1.1.1.1
EOF

#############################################################
# Need to adjust conf file for python in flaskinterface

EDITFILE="/opt/flaskinterface/wifi.py"
if [ -f ${EDITFILE} ]; then
  sed -i 's/wpa_supplicant.conf/wpa_supplicant-wlan0.conf/g' ${EDITFILE}
fi

#reboot


