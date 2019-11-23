#!/bin/bash

# Lancement de chromium avec les mêmes réglages que le kiosk
/usr/bin/chromium-browser -noerrdialogs --restore-last-session --load-extension=~/.config/chromium/Extensionsio/totemhome,~/.config/chromium/Extensionsio/vkio http://127.0.0.1:8080


