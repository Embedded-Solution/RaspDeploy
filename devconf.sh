#!/bin/sh

##################################################################
#                                                                #
# Fichier de déploiement des outils de développement             #
#                                                                #
##################################################################

##################### rmate #######################

sudo apt-get install ruby shellcheck -y
wget -O /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate#!/bin/sh
sudo chmod a+x /usr/local/bin/rmate
 
##################### Anydesk #######################

if ! dpkg -s anydesk >/dev/null 2>&1; then
    apt install libpango1.0-0 libegl1-mesa -y
    wget https://download.anydesk.com/rpi/anydesk_5.1.1-1_armhf.deb
    dpkg -i anydesk_5.1.1-1_armhf.deb
    rm anydesk_5.1.1-1_armhf.deb
    echo 'ad.security.interactive_access=0' | sudo tee -a /etc/anydesk/system.conf
    echo 'ad.security.file_manager=false' | sudo tee -a /etc/anydesk/system.conf
    echo 'ad.security.clipboard.files=false' | sudo tee -a /etc/anydesk/system.conf
    echo 'ad.security.hear_audio=false' | sudo tee -a /etc/anydesk/system.conf
    sudo systemctl daemon-reload
fi



# Installation des scripts iomanage
cp -f ./iomanagescripts/* /usr/local/sbin
cp -f ./supervisor/iomanage.conf /etc/supervisor/conf.d/