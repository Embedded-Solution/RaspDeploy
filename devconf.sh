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


# Installation des scripts iomanage
cp -f ./iomanagescripts/* /usr/local/sbin
cp -f ./supervisor/iomanage.conf /etc/supervisor/conf.d/