### Installation

Dans une console:

`git clone http://deploy.ioconstellation.com/iostaff/raspdeploy.git`

`cd raspdeploy/ && sudo sh deploy.sh`


Pour supprimer l'ancier fichier raspdeploy en cas d'érreur

`sudo rm -r raspdeploy`

### Version de test
`git clone -b testing http://deploy.ioconstellation.com/iostaff/raspdeploy.git`

`cd raspdeploy/ && sudo sh deploy.sh -v testing`

### Options
#### Nettoyage: -c
L'ajout de -c à la commande sh deploy.sh permet de supprimer l'utilistateur edkuser et son dossier ainsi que le dossier /opt/flaskinterface avant le déploiement.

`cd raspdeploy/ && sudo sh deploy.sh -c [-v version]`
