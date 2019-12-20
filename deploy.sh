#!/bin/sh

##################################################################
#                                                                #
# Fichier de déploiement d'une interface Kiosk                   #
# à partir d'une image Raspbian 10                               #
#                                                                #
##################################################################


VERSION="master"
# parser les arguments
while getopts v:ckm: option; do
	case "${option}"
		in
		v) VERSION=${OPTARG};;
		c) CLEAN=1;;
    k) KRYPT=1;;
	esac
done

KUSER="edkuser"
GRPSADMIN="adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio,bluetooth"
GRPSREST="dialout,cdrom,audio,video,games,users,input,netdev,gpio,bluetooth"
INFOS=$(curl http://deploy.ioconstellation.com/infos/infos.txt)
eval $INFOS

echo "Version = " $VERSION

TESTMODEL=$( cat /proc/device-tree/model | cut -c-22 )
echo $TESTMODEL

if test "$TESTMODEL" = "Raspberry Pi 3 Model A"; then
    MODEL="aplus"
else
    MODEL="autres"
fi

if [ $CLEAN ]; then
	echo "Suppression de l'utilisateur 'edkuser' et du dossier 'flaskinterface'"
  userdel -r -f edkuser
  rm -R /home/edkuser
  rm -r /opt/flaskinterface
fi

############## PAQUETS, BIBLIOTEQUE, ETC, #####################

# Mise à jour 
apt update 
apt upgrade -y

# Installation des paquest utiles /supprimer thunderbird
apt install  accountsservice unclutter matchbox feh ecryptfs-utils -y
apt install libreoffice libreoffice-l10n-fr -y

# Suppression des paquets inutiles
apt remove geany geany-common -y

 
# Installation de anydesk
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
 

# ######### SCRIPTS ET MODIFICATION SYSTEM (LOOK, ETC...)

# Changer le hostname
sudo sed -i "s/raspberrypi/easydigitalkey/g" /etc/hostname

# Installation des scripts utilisateurs et système
cp -f ./alluserscripts/* /usr/local/sbin

# Copie des fichier partagés par ts les utilisateurs
cp -Rf ./usersshare/* /usr/share

# Annuler la demande de confirmation des launchers bureau
sudo sed -i '/\[config\]/a quick_exec=1' /etc/xdg/libfm/libfm.conf

# Passer la mémoire swap à 500M
sudo sed -i 's/SWAPSIZE=100/SWAPSIZE=500/g' /etc/dphys-swapfile


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
echo "edkuser ALL=(ALL) NOPASSWD: /sbin/reboot,/sbin/shutdown,/usr/sbin/service,/sbin/ifconfig,/usr/sbin/rfkill,/usr/bin/anydesk" > /etc/sudoers.d/020_edkuser-nopasswd

# Changer l'utilisateur "par defaut"
sudo sed -i "s/autologin-user=pi/autologin-user=edkuser/g" /etc/lightdm/lightdm.conf

# Installation du plugin 'totemhome'
git clone -b $VERSION http://deploy.ioconstellation.com/iostaff/totemhome.git
rm -R totemhome/.git
mkdir -p ./alluserhome/.config/chromium/Extensionsio
cp -Rf totemhome ./alluserhome/.config/chromium/Extensionsio

# Installation du plugin virtualkeyboard modifié
cp -Rf ./chromium/vkio ./alluserhome/.config/chromium/Extensionsio

# Copier les fichiers/dossiers home par defaut des utilisateurs
for luser in pi edkuser edkstf
do 
	cp -Rf ./alluserhome -T /home/$luser
	chown -R $luser:$luser /home/$luser
done


##################### CHROMIUM #######################

#installtion de libwidevine pour lecture des drm
cp ./chromium/libwidevinecdm.so /usr/lib/chromium-browser

# Installation des plugins Chromium
for f in ./chromium/policies/*.json; do
    echo 'Installation des plugins ' $f
    cp $f  /etc/chromium-browser/policies/managed
done

# Installation et configuration de supervisor
apt install supervisor -y
for f in ./supervisor/*.conf; do
    echo 'Copie de ' $f ' dans /etc/supervisor/conf.d'
    cp $f  /etc/supervisor/conf.d/
done

##################### FLASKINTERFACE #######################

apt install python3-flask python3-flask-sqlalchemy gunicorn3 python3-bluez python3-alsaaudio python3-pexpect python3-pymediainfo python3-evdev -y
pip3 install timeloop
git clone -b $VERSION http://deploy.ioconstellation.com/iostaff/flaskinterface.git
rm -R flaskinterface/.git
cp -Rf flaskinterface /opt
chown -R $KUSER:$KUSER /opt/flaskinterface
sudo sed -i '/^ExecStart/ s/$/ plugin=a2dp/' /lib/systemd/system/bluetooth.service


# Copier les fichiers de boot et de splash

cp /boot/$MODEL/* /boot/
cp -fv ./divers/splash.png /usr/share/plymouth/themes/pix/splash.png

# Nettoyer le cache apt
apt autoremove -y
apt autoclean

if [ $KRYPT ]; then
# Création du service d'encryption de kioskfile
  cp -Rf ./services/* /etc/systemd/system
  sudo systemctl enable ioconst.service
  sudo systemctl start ioconst.service
  sudo /usr/local/sbin/mountedk.sh.x
fi

# Redémarage des services liés
/usr/bin/supervisorctl restart interface
/usr/bin/supervisorctl restart iomanage


# Fermeture et nettoyage des fichiers de déploiement
cd ~/

# Reboot
