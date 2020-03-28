#!/bin/sh

##################################################################
#                                                                #
# Fichier de déploiement des outils de développement             #
#                                                                #
##################################################################

sudo apt-get install ruby shellcheck

wget -O /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate#!/bin/sh
sudo chmod a+x /usr/local/bin/rmate