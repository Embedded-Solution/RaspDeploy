# Manual

Here is what you need to do for install the latest EasyDK software on your Raspberry Pi 4:

* [SD card preparation](#sd-card-preparation)
* [Enable Pi 4 GPU Video Decode hardware accelerated](docs/CHROMIUM_GPU.md)
* [Rotate the Raspberry Pi Display (Pi 4)](#rotate-the-raspberry-pi-display-pi-4)
* [Rotate the Raspberry Pi Display Output 7 (Pi 3)](#rotate-the-raspberry-pi-display-output-7-pi-3)


Notes:
* As of *[flaskinterface](https://git.ioconstellation.com/iostaff/flaskinterface)* version 2.2, only **Pi 4** is supported.

 
## SD card preparation

### Requirements

Installation requires [Raspbian Buster with desktop](https://www.raspberrypi.org/downloads/raspbian/).

### Installation

#### Master : Stable version

```bash
sudo apt-get update
sudo apt-get upgrade
git clone https://git.ioconstellation.com/iostaff/RaspDeploy.git
cd RaspDeploy && sudo ./deploy.sh
```
 
#### Testing : Work in progress, last updates

```bash
sudo apt-get update
sudo apt-get upgrade
git clone -b testing https://git.ioconstellation.com/iostaff/RaspDeploy.git
cd RaspDeploy && sudo ./deploy.sh -v testing
```

### Git user credentials
Add *git* username:password in *git* URL
```bash
git clone https://username:password@git.ioconstellation.com/iostaff/RaspDeploy.git
```

### Options

#### Delete: -r
To delete the old raspdeploy file in case of error

`sudo rm -r RaspDeploy`

#### Upgrade: -u
Adding -u to the sh deploy.sh command activates package upgrades at installation time.

`cd RaspDeploy/ && sudo sh deploy.sh -u [-v version]`

#### Cleaning: -c
Adding -c to the sh deploy.sh command removes the edkuser and its folder as well as the / opt / flaskinterface folder before deployment.

`cd RaspDeploy/ && sudo sh deploy.sh -c [-v version]`

## Rotate the Raspberry Pi Display (Pi 4)

Proceed as *pi* user in desktop menu **Preferences > Screen Configration** or edit `/usr/share/dispsetup.sh`:

```bash
#!/bin/sh
if ! grep -q 'Raspberry Pi' /proc/device-tree/model || (grep -q okay /proc/device-tree/soc/v3d@7ec00000/status 2> /dev/null || grep -q okay /proc/device-tree/soc/firmwarekms@7e600000/status 2> /dev/null || grep -q okay /proc/device-tree/v3dbus/v3d@7ec04000/status 2> /dev/null) ; then
if xrandr --output HDMI-1 --primary --mode 1920x1080 --rate 60.00 --pos 0x0 --rotate right --dryrun ; then
xrandr --output HDMI-1 --primary --mode 1920x1080 --rate 60.00 --pos 0x0 --rotate right
fi
fi
if [ -e /usr/share/tssetup.sh ] ; then
. /usr/share/tssetup.sh
fi
exit 0

```


## Rotate the Raspberry Pi Display Output 7 (Pi 3)

Step 1 – Edit `/boot/config.txt`

```bash
sudo nano /boot/config.txt

display_rotate=0
display_rotate=1
display_rotate=2
display_rotate=3
0 is the normal configuration. 1 is 90 degrees. 2 is 180 degress. 3 is 270 degrees.
If you are using the Official Raspberry Pi touch screen you can use “lcd_rotate” rather than “display_rotate”.
```


Save the file by using CTRL-X, Y then ENTER.

Step 2 – Reboot

Then reboot using : sudo reboot When the Pi restarts the display should be rotated.
