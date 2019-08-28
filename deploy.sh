#!/bin/sh

##################################################################
#                                                                #
# Fichier de déploiement d'une interface Kiosk                   #
# à partir d'une image Raspbian 10                               #
#                                                                #
#                                                                #
##################################################################
 

# Mise à jour 
apt upgrade
apt update

# Suppression des paquets inutiles
apt remove geany geany-common

# Installation de paquets 'de base'
apt install supervisor 

# Installation de anydesk
apt install libpango1.0-0
wget https://download.anydesk.com/rpi/anydesk_5.1.1-1_armhf.deb
dpkg -i anydesk_5.1.1-1_armhf.deb

# Installation des jeux
apt install scummvm
apt install steamlink steam-device

