#!/bin/sh

##################################################################
#                                                                #
# Fichier de déploiement d'une interface Kiosk                   #
# à partir d'une image Raspbian 10                               #
#                                                                #
#                                                                #
##################################################################

VERSION="master"

# parser les arguments
while getopts v:c option; do
	case "${option}"
		in
		v) VERSION=${OPTARG};;
		c) CLEAN=0;;
	esac
done

if [ -n $CLEAN ]; then
	echo "Tout Nettoyer"
fi

echo "Version = " $VERSION

# Mise à jour 
apt update
apt upgrade -y

# Suppression des paquets inutiles
apt remove geany geany-common

# Installation de anydesk
if ! dpkg -s anydesk >/dev/null 2>&1; then
    apt install libpango1.0-0
    wget https://download.anydesk.com/rpi/anydesk_5.1.1-1_armhf.deb
    dpkg -i anydesk_5.1.1-1_armhf.deb
    rm anydesk_5.1.1-1_armhf.deb
fi

# Installation des jeux
apt install scummvm steamlink -y

# Installation de Kodi
apt install kodi -y


# Installation des plugins Chromium
for f in ./chromium/plugins/*.json; do
    # do some stuff here with "$f"
    echo 'Installation des plugins ' $f
    cp $f  /etc/chromium-browser/policies/managed
done

# Copier les fichiers/dossiers de /homepi/ dans /home/pi
cp -Rfv ./pi /home

# Installation et configuration de supervisor
apt install supervisor -y
for f in ./supervisor/*.conf; do
    echo 'Copie de ' $f ' dans /etc/supervisor/conf.d'
    cp $f  /etc/supervisor/conf.d/
done

# Installer Flaskinterface
apt install python3-flask python3-flask-sqlalchemy -y
git clone -b $VERSION http://deploy.ioconstellation.com/iostaff/flaskinterface.git
rm -R flaskinterface/.git
cp -Rfv flaskinterface /opt
chown -R pi:pi /opt/flaskinterface

# Modification du look du bureau
cp -Rfv ./raspberrypi-artwork /usr/share

# Nettoyer le cache apt
apt autoremove -y
apt autoclean

# Fermeture et nettoyage des fichiers de déploiement
cd ~/