#!/bin/sh

##################################################################
#                                                                #
# Fichier de déploiement d'une interface Kiosk                   #
# à partir d'une image Raspbian 10                               #
#                                                                #
##################################################################

# parser les arguments
while getopts v:c option; do
	case "${option}"
		in
		v) VERSION=${OPTARG};;
		c) CLEAN=0;;
	esac
done

VERSION="master"
KUSER="edkuser"
GRPSADMIN="adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio"
GRPSREST="dialout,cdrom,audio,video,games,users,input,netdev,gpio"
INFOS=$(curl http://deploy.ioconstellation.com/infos/infos.txt)
eval $INFOS

echo "Version = " $VERSION

if [ -n $CLEAN ]; then
	echo "Tout Nettoyer"
fi

############## PAQUETS, BIBLIOTEQUE, ETC, #####################

# Mise à jour 
apt update
apt upgrade -y

# Installation des paquest utiles
apt install accountsservice unclutter matchbox thunderbird thunderbird-l10n-fr -y

# Suppression des paquets inutiles
apt remove geany geany-common -y

# Installation de anydesk
if ! dpkg -s anydesk >/dev/null 2>&1; then
    apt install libpango1.0-0 libegl1-mesa -y
    wget https://download.anydesk.com/rpi/anydesk_5.1.1-1_armhf.deb
    dpkg -i anydesk_5.1.1-1_armhf.deb
    rm anydesk_5.1.1-1_armhf.deb
fi


########## SCRIPTS ET MODIFICATION SYSTEM (LOOK, ETC...)

# Installation des scripts utilisateurs et système
cp -f ./alluserscripts/* /usr/local/sbin

# Copie des fichier partagés par ts les utilisateurs
cp -Rf ./usersshare/* /usr/share


########## CRÉATION ET CONFIGURATION DES UTILISATEURS ###########

# Créations des utilisateurs
if ! id edkuser > /dev/null 2>&1; then
  echo "création de l'utilisateur edkuser"
  useradd -d /home/edkuser -G $GRPSREST -m -p $(echo $EDKPW | openssl passwd -1 -stdin) edkuser
fi
if ! id edkstf > /dev/null 2>&1; then
  echo "création de l'utilisateur edkstf"
  useradd -d /home/edkstf -G $GRPSADMIN -m -p $(echo $EDKSPW | openssl passwd -1 -stdin) edkstf
fi

# Modifier les droits sudoer
echo "edkstf ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/020_edkstf-nopasswd
echo "edkuser ALL=(ALL) NOPASSWD: /sbin/reboot,/sbin/shutdown,/usr/sbin/service" > /etc/sudoers.d/02_edkuser-nopasswd

# Changer l'utilisateur "par defaut"
sudo sed -i "s/autologin-user=pi/autologin-user=edkuser/g" /etc/lightdm/lightdm.conf

# Copier les fichiers/dossiers home par defaut des utilisateurs
for luser in pi edkuser edkstf
do 
	cp -Rf ./alluserhome -T /home/$luser
	chown -R $luser:$luser /home/$luser
	#chmod +x /home/$luser/.script/*
done


##################### CHROMIUM #######################

#installtion de libwidevine pour lecture des drm
cp ./chromium/libwidevinecdm.so /usr/lib/chromium-browser

# Installation des plugins Chromium
for f in ./chromium/policies/*.json; do
    # do some stuff here with "$f"
    echo 'Installation des plugins ' $f
    cp $f  /etc/chromium-browser/policies/managed
done

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
cp -Rf flaskinterface /opt
chown -R $KUSER:$KUSER /opt/flaskinterface


### à faire: changer framboise ###########################

# Copier les fichiers de boot et de splash
#cp -Rfv ./boot /
#cp -fv ./divers/splash.png /usr/share/plymouth/themes/pix/splash.png


# Nettoyer le cache apt
apt autoremove -y
apt autoclean

# Fermeture et nettoyage des fichiers de déploiement
cd ~/

# Reboot