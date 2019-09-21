#!/bin/bash

# Modification du fichier autostart
cp $HOME/.config/lxsession/LXDE-pi/autostart{.kiosk,}

# Redémarage de la session graphique
sudo service lightdm restart

