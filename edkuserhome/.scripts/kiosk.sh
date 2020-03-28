#!/bin/bash

# Modification du fichier autostart
cp .config/lxsession/LXDE-pi/autostart{.defaut,}

# Redémarage de la session graphique
sudo service lightdm restart
