#!/bin/bash

##################################################################
#                                                                #
# Fichier de déploiement d'une interface Kiosk                   #
# à partir d'une image Raspbian 10                               #
#                                                                #
##################################################################


VERSION="master"
# parser les arguments
while getopts v:ckud option; do
	case "${option}"
		in
		v) VERSION=${OPTARG};;
		c) CLEAN=1;;
	    u) UPGRADE=1;;
	    d) DEV=1;;
	esac
done

# Variables
CURENTDIR=$PWD
KUSER="edkuser"
PIPWD="edkuser"
EDKPW="edkuser"

# deployType 1 to use systemd, 2 to use dhcpcd (flaskinterface sedttings supports type 2)
deployType="2"
APSSID="EASYDK_SIGNAGE"
APPWD="EASYDK_SIGNAGE"

NEWHOSTNAME=easydigitalkey
GRPSADMIN="adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio,bluetooth"
GRPSREST="dialout,cdrom,audio,video,games,users,input,netdev,gpio,bluetooth"

GITURL=$(git config --get remote.origin.url)
GITURL="${GITURL%/*}"
#eval "$INFOS"

echo "Version = " "$VERSION"

# Vérification du modèle
TESTMODEL=$( cat /proc/device-tree/model | cut -c-22 )
echo "$TESTMODEL"

if test "$TESTMODEL" = "Raspberry Pi 3 Model A"; then
    MODEL="aplus"
elif test "$TESTMODEL" = "Raspberry Pi 4 Model B"; then
    MODEL="4modelB"
else
    MODEL="autre"
fi




# Nettoyage de edkuser et flaskinterface si option -c
if [ $CLEAN ]; then
	echo "Suppression de l'utilisateur 'edkuser' et du dossier 'flaskinterface'"
  userdel -r -f edkuser
  rm -R /home/edkuser
  rm -r /opt/flaskinterface
fi

############## PAQUETS, BIBLIOTEQUE, ETC, #####################

# Mise à jour si option -u
apt update
if [ $UPGRADE ]; then 
  apt upgrade -y
fi

# Installation des paquest utiles
apt install  accountsservice unclutter matchbox feh ecryptfs-utils libreoffice libreoffice-l10n-fr supervisor -y

# Suppression des paquets inutiles
apt remove geany geany-common -y
 
# ######### SCRIPTS ET MODIFICATION SYSTEM (LOOK, ETC...)

# Changer le hostname
/bin/sed -i "s/raspberrypi/easydigitalkey/g" /etc/hostname
sudo sed -i "s/raspberrypi/easydigitalkey/g" /etc/hosts

# Installation des scripts utilisateurs et système
cp -f ./alluserscripts/* /usr/local/sbin
sudo chmod a+x /usr/local/sbin/hostapd_cli_daemon.py
sudo mkdir /var/log/hotspot

# Copie des fichier partagés par ts les utilisateurs
cp -Rf ./usersshare/* /usr/share

# Annuler la demande de confirmation des launchers bureau
/bin/sed -i '/\[config\]/a quick_exec=1' /etc/xdg/libfm/libfm.conf

# Passer la mémoire swap à 500M
/bin/sed -i 's/SWAPSIZE=100/SWAPSIZE=500/g' /etc/dphys-swapfile


########## CRÉATION ET CONFIGURATION DES UTILISATEURS ###########

# Créations des utilisateurs
if ! id edkuser > /dev/null 2>&1; then
  echo "création de l'utilisateur edkuser"
  useradd -d /home/edkuser -G $GRPSREST -m -p "$(echo "$EDKPW" | openssl passwd -1 -stdin)" edkuser
fi
if ! id edkstf > /dev/null 2>&1; then
  echo "création de l'utilisateur edkstf"
  useradd -d /home/edkstf -G $GRPSADMIN -m -p "$(echo "$EDKSPW" | openssl passwd -1 -stdin)" edkstf
fi

# Modifier les droits sudoer
echo "edkstf ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/020_edkstf-nopasswd
echo "edkuser ALL=(ALL) NOPASSWD:  /home/pi/network-setup/bin/*,/usr/bin/supervisorctl,/bin/cp,/bin/sed,/bin/systemctl,/sbin/reboot,/sbin/shutdown,/usr/sbin/service,/sbin/ifconfig,/usr/sbin/rfkill,/usr/bin/anydesk" > /etc/sudoers.d/020_edkuser-nopasswd

# Changer l'utilisateur "par defaut"
/bin/sed -i "s/autologin-user=pi/autologin-user=edkuser/g" /etc/lightdm/lightdm.conf

# Copier les fichiers/dossiers home par defaut des utilisateurs
for luser in pi edkuser edkstf
do 
	cp -Rf ./"$luser"home -T /home/$luser
	chown -R $luser:$luser /home/$luser
done

# Modification des droits sur clé ssh
chmod 600 /home/"$KUSER"/.ssh/rs_rsa

############  web server ######################
apt install nginx -y

rsync -av ./reseau/nginx/ /etc/nginx/sites-available/

##################### CHROMIUM #######################

#installtion de libwidevine pour lecture des drm
cp ./chromium/libwidevinecdm.so /usr/lib/chromium-browser

# Installation des plugins Chromium
rsync -a ./chromium/policies/ /etc/chromium-browser/policies/managed/

# Installation du plugin 'totemhome'
rm -r /home/"$KUSER"/.config/chromium/Extensionsio/totemhome
git clone -b $VERSION "$GITURL"/totemhome.git /home/"$KUSER"/.config/chromium/Extensionsio/totemhome

 
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

 
##################### Flaskinterface #######################

rm -r /opt/flaskinterface
git clone -b "$VERSION" "$GITURL"/flaskinterface.git /opt/flaskinterface
chown -R edkuser:pi flaskinterface
chmod -R g+w flaskinterface
sed -i 's/127.0.0.1/8.8.8.8/' /etc/resolv.conf
/bin/sh /opt/flaskinterface/run.sh

 
##################### Boot #######################

cp ./boot/$MODEL/* /boot/
cp -fv ./divers/splash.png /usr/share/plymouth/themes/pix/splash.png


# configuration pour le développement
if [ $DEV ]; then
  /bin/sh ./devconf.sh
  ln -sf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/debug
else
  rm -R /opt/flaskinterface/.git
  rm -R /home/"$KUSER"/.config/chromium/Extensionsio/totemhome/.git
  ln -sf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
  cp -f ./supervisor/interface.conf /etc/supervisor/conf.d/ 
fi

# Nettoyer le cache apt
apt autoremove -y
apt autoclean

# Redémarage des services liés
service nginx restart
/usr/bin/supervisorctl reload

####################### Network #######################
# Install Access Point Manager
echo "========================================="
echo "      Network manager installation"
echo "========================================="

# 2 models 

if [[ "$deployType" == "1" ]]; then
   #--> First with systemd only <--
   chmod ug+x deployAP.sh
 
   ./deployAP.sh --ap-ssid="$APSSID" --ap-password="$APPWD"
else
   #--> Second with dhcpcd <--
   chmod ug+x setup-network.sh

   ./setup-network.sh --install --ap-ssid="$APSSID" --ap-password="$APPWD" --ap-password-encrypt
fi
################### END Network #######################
#######################################################

# Fermeture et nettoyage des fichiers de déploiement
cd "$CURENTDIR"/..

# Google nameserver
sed -i 's/127.0.0.1/8.8.8.8/' /etc/resolv.conf

# Reboot
