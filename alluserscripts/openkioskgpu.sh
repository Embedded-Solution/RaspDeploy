#!/bin/bash

# Modification du fichier autostart
cp $HOME/.config/lxsession/LXDE-pi/autostart{.kioskgpu,}

# Redémarage de la session graphique
sudo service lightdm restart

