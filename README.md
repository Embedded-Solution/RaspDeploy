# Manual

Here is a quick overview what you need to do for downloaded the latest EasyDK img for your rpi

- A + (Bêta) 
- B + (Bêta) You can activate Open GL
- B 4 (Alpha) You can activate Open GL

# [Tutorial videos ](https://easydigitalkey.com/gb/content/36-discover-easy-dkon-video)
 
## SD card preparation
**Installation need [Raspbian Buster with desktop](https://www.raspberrypi.org/downloads/raspbian/)


### Bêta Versions 

**For All versions    user : edkuser / pass :edkuser**

**V1 - Master : Stable version**

`git clone https://git.ioconstellation.com/iostaff/raspdeploy.git`

`cd raspdeploy && sudo ./deploy.sh`

 
**V2 - Testing : Work in progress, last updates**

`git clone -b testing https://git.ioconstellation.com/iostaff/raspdeploy.git`

`cd raspdeploy && sudo ./deploy.sh -v testing`


**V3 - Debug version (-d) : Version to test local development**

`git clone -b testing https://git.ioconstellation.com/iostaff/raspdeploy.git`

`cd raspdeploy/ && sudo sh deploy.sh -v testing -d`

    Commandes to start serveur in debug mode :
    su edkuser
    pass :edkuser
    /opt $ cd flaskinterface/
    /opt/flaskinterface $ python3 server.py



### Options

#### Delete: -r
To delete the old raspdeploy file in case of error

`sudo rm -r raspdeploy`

#### Upgrade: -u
Adding -u to the sh deploy.sh command activates package upgrades at installation time.

`cd raspdeploy/ && sudo sh deploy.sh -u [-v version]`

#### Cleaning: -c
Adding -c to the sh deploy.sh command removes the edkuser and its folder as well as the / opt / flaskinterface folder before deployment.

`cd raspdeploy/ && sudo sh deploy.sh -c [-v version]`



LICENSE
AGPL V3 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
You will find a copy of the GNU Affero General Public License along with this program.
You can also have a look at reference website http://www.gnu.org/licenses/. Limits. In any case, if you re-distribute this product you must :

distribute it under AGLP V3 license (or above) and so have to include source code
reference original product (Easydigitalkey)
not let any ambiguity about origin of product, which could lead to think that you are the author of the product 
Distribution also includes delivery even to one only customer and providing of service (hosting or SaaS mode). 