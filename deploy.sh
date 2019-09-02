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
apt remove geany geany-common -y

# Installation de anydesk
if ! dpkg -s anydesk >/dev/null 2>&1; then
    apt install libpango1.0-0 libegl1-mesa -y
    wget https://download.anydesk.com/rpi/anydesk_5.1.1-1_armhf.deb
    dpkg -i anydesk_5.1.1-1_armhf.deb
    rm anydesk_5.1.1-1_armhf.deb
fi

# Installation des jeux
apt install scummvm

#enlever la souris de l'écran
apt install unclutter

#installer un clavier
apt install matchbox

#installtion de libwidevine binary and extract pour useragent
cd /usr/lib/chromium-browser
wget http://blog.vpetkov.net/wp-content/uploads/2019/08/libwidevinecdm.so_.zip
unzip libwidevinecdm.so_.zip && chmod 755 libwidevinecdm.so

#Messagerie Thunderbird pour travailler en off line
sudo apt install thunderbird thunderbird-l10n-fr

# Installation des plugins Chromium
for f in ./chromium/plugins/*.json; do
    # do some stuff here with "$f"
    echo 'Installation des plugins ' $f
    cp $f  /etc/chromium-browser/policies/managed
done


# Installation de l'extension TotemHome
#cp ./ExtensionsIo/boonncnoiobakmnakbmefocmcgibnjld.json /usr/share/chromium-browser/

# Copier les fichiers/dossiers de /homepi/ dans /home/pi
cp -Rfv ./pi /home
chown -R pi:pi /home/pi


# Installation et configuration de supervisor
apt install supervisor -y
for f in ./supervisor/*.conf; do
    echo 'Copie de ' $f ' dans /etc/supervisor/conf.d'
    cp $f  /etc/supervisor/conf.d/
done

# Installation de Iomanage
cp -f ./iomanage/iomanage.py /usr/local/sbin/
cp -f ./iomanage/logmanage.py /usr/local/sbin/

# Installer Flaskinterface
apt install python3-flask python3-flask-sqlalchemy -y
git clone -b $VERSION http://deploy.ioconstellation.com/iostaff/flaskinterface.git
rm -R flaskinterface/.git
cp -Rfv flaskinterface /opt
chown -R pi:pi /opt/flaskinterface

# Modification du look du bureau
cp -Rfv ./raspberrypi-artwork /usr/share
cp -fv ./divers/temple.jpg /usr/share/rpd-wallpaper/temple.jpg
### à faire: changer framboise ###########################

# Copier les fichiers de boot et de splash
cp -Rfv ./boot /
cp -fv ./divers/splash.png /usr/share/plymouth/themes/pix/splash.png


# Nettoyer le cache apt
apt autoremove -y
apt autoclean

# Fermeture et nettoyage des fichiers de déploiement
cd ~/

# Reboot