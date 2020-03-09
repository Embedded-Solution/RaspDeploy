# coding: utf-8
import requests
import json
import os
import sys
import shutil
import zipfile
import tarfile
from logmanage import logger
from pwd import getpwnam
from time import sleep
import subprocess
from os.path import join as opj

VERSION = '1.1.1'

token = '82a5aa8bfc86bd7f1a9328d94b4ad4b9289670e3'
server = 'ioconstellation.com'
head = {'Authorization': 'token {}'.format(token)}
runfile = '/var/local/iomanage.run'
user = 'edkuser'
home = '/home/{}'.format(user)
kioskdir = '{}/.kioskfiles'.format(home)
totemdir = '{}/.totemfiles'.format(home)
masterdir = '{}/.masterfiles'.format(home)
edkuid = getpwnam('edkuser').pw_uid
piguid = getpwnam('pi').pw_gid
debug = False


def running(text):
    with open(runfile, 'w') as f:
        f.write(text)


def getrunning():
    with open(runfile, 'r') as f:
        return f.readline()


def runcmd(cmd, fin=None):
    try:
        subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        print("Erreur de commande %s", e)
    finally:
        fin
        pass


def getmac():
    """ Récupère l'adresse mac de l'appareil """
    rootnet = '/sys/class/net/'
    for i in ['eth0', 'wlan0', 'enp2s0']:
        if os.path.isdir(os.path.join(rootnet, i)):
            try:
                mac = open(rootnet + i + '/address').readline()
                return mac[0:17]
            except Exception as e:
                logger.info(
                    "Impossible de lire l'adresse mac \
                     de l'interface: %s", i)
                logger.warning('Code Erreur : %s', e)
    return False


def reqserver(posturl, method='get', datas={}, succes=200):
    """ Envoi de la requète au serveur """
    url = 'https://' + server + posturl
    try:
        if method == 'get':
            response = requests.get(url, headers=head, params=datas)
        if method == 'post':
            response = requests.post(url, headers=head, params=datas)
        if method == 'put':
            response = requests.put(url, headers=head, json=datas)
        if response.status_code == succes:
            return json.loads(response.text)
    except requests.exceptions.RequestException as e:
        logger.info("Erreur serveur: %s", e)
        exit()
    return False


def getfile(posturl, filename):
    token = '82a5aa8bfc86bd7f1a9328d94b4ad4b9289670e3'
    head = {'Authorization': 'token {}'.format(token)}
    url = 'https://' + server + '/devmanage/download/' + \
        os.path.basename(posturl)
    try:
        response = requests.get(url, headers=head, stream=True)
        handle = open('/tmp/' + filename, 'wb')
        for chunk in response.iter_content(chunk_size=1024):
            if chunk:  # filter out keep-alive new chunks
                handle.write(chunk)
        handle.close()
        return '/tmp/' + filename

    except Exception as e:
        logger.warning('Erreur du chargement du fichier: %s', url)
        logger.warning('Code Erreur : %s', e)
        exit()


# def enrdevice(name, macadress):
#     url = 'https://' + server + "/device/record/"
#     datas = {'shortName': name, 'macadress': macadress}
#     response = requests.post(url, headers=head, data=datas, verify=False)


def getdevice(macadress):
    datas = {'macadress': macadress, 'version': VERSION}
    rep = reqserver('/device/record/', datas=datas, succes=201)
    if rep:
        return rep
    else:
        return {}


def getlistupdate(device_id):
    rep = reqserver('/devmanage/api/deviceaction/' + str(device_id) + '/')
    return rep


def getupdate(device_id):
    rep = reqserver('/devmanage/api/action/' + str(device_id) + '/')
    return rep


def getmedia(media_id):
    rep = reqserver('/devmanage/mediaapi/' + str(media_id))
    return rep


def updatestatus(id, action, status):
    url = '/devmanage/api/deviceaction/' + str(id) + '/' + str(action) + '/'
    status = {'status': status, 'action': action}
    reqserver(url, 'put', status, 201)


def procces_update(update):

    # Récupération des variables
    action = update['preact']
    user = update['user']
    chemin = update['chemin']
    postact = update['postact']
    media_id = update['media']
    if media_id:
        media = getmedia(media_id)
        if media:
            media_url = media['file']
            media_name = media['realname']
            media_file = getfile(media_url, media_name)
        else:
            msg = "{}: Erreur de chargement du media: id={}".format(
                action, media_id)
            return (2, msg)

    # Évaluation de l'uid et guid de l'utilisateur cible
    uid = getpwnam(user).pw_uid
    guid = getpwnam(user).pw_gid

    # Si l'utilisateur n'est pas root ajouter '/home/user' au chemin
    userpath = os.path.join('/home', user)
    if user == 'root':
        userpath = '/'
    targetdir = os.path.join(userpath, chemin)
    if debug:
        msg = "{}: Debug: {}".format(
            action, targetdir)
        return (2, msg)

    if action in ('ADDFILE', 'EXTRACT'):
        try:
            # Si le dossier n'existe pas, le créer
            if not os.path.isdir(targetdir):
                os.makedirs(targetdir)

            # Modifier le propriétaire des dossiers créés
            path = targetdir
            while os.stat(path).st_uid != uid:
                os.chown(path, uid, guid)
                path = os.path.dirname(path)
        except Exception:
            msg = "{}: Erreur de création du chemin: {}".format(
                action, targetdir)
            return (2, msg)

    if action == 'ADDFILE':

        try:
            # Copier le média à son emplacement et modifier son propriétaire
            shutil.copy(media_file, os.path.join(targetdir, media_name))
            os.chown(os.path.join(targetdir, media_name), uid, guid)

        except Exception:
            msg = "{}: Erreur d'execution': {}".format(
                action, targetdir)
            return (2, msg)

    if action == 'EXTRACT':
        try:
            if zipfile.is_zipfile(media_file):
                zip = zipfile.ZipFile(media_file)
                zip.extractall(targetdir)
                zip.close()
                updatestatus(update['id'], 1)
            elif media_file[-7:] == '.tar.gz':
                arch = tarfile.open(media_file, 'r')
                arch.extractall(targetdir)
                arch.close()
            else:
                msg = "{}: Le fichier {} n'est pas une archive".format(
                    action, media_file)
                return (2, msg)

        except Exception:
            msg = "{}: Erreur d'extraction de {}".format(
                action, media_file)
            return (2, msg)

    if postact == 'EXECUTE':
        try:
            if action == 'ADDFILE':
                cmd = os.path.join(targetdir, media_name)
                os.chmod(cmd, 35309)
            elif action == 'EXTRACT':
                dirname = os.path.basename(media_name).split('-')[0]
                cmd = os.path.join(targetdir, os.path.join(dirname, 'run.sh'))
            os.system(cmd)

        except Exception:
            msg = "{}: Erreur d'exécution".format(
                postact, cmd)
            return (2, msg)

    if postact == 'REBOOT':
        sudoer = ('', 'sudo ')[user == 'root']
        try:
            os.system('{}shutdown -r -t 1'.format(sudoer))
        except Exception:
            return (2, "{}: Erreur d\'exécution".format(action))

    if postact == 'RELOADFLASK':
        sudoer = ('', 'sudo ')[user == 'root']
        try:
            os.system('{}supervisorctl reload interface'.format(sudoer))
        except Exception:
            return (2, "{}: Erreur d\'exécution".format(action))

    if postact == 'RELOADIOMANAGE':
        sudoer = ('', 'sudo ')[user == 'root']
        try:
            os.system('{}supervisorctl reload iomanage'.format(sudoer))
        except Exception:
            return (2, "{}: Erreur d\'exécution".format(action))

    if postact == 'RELOADCHROME':
        sudoer = ('', 'sudo ')[user == 'root']
        try:
            os.system('{}service lightdm restart'.format(sudoer))
        except Exception:
            return (2, "{}: Erreur d\'exécution".format(action))

    if postact == 'REFRESH':
        img = os.path.join(targetdir, media_name)
        try:
            cmd = 'export DISPLAY=:0 && export XAUTHORITY=/home/{}/.Xauthority \
            && export XDG_RUNTIME_DIR=/run/user/1000 && pcmanfm \
             -w {} && export DISPLAY='.format(user, img)
            os.system(cmd)
        except Exception:
            return (2, "{}: Erreur d\'exécution".format(action))

    msg = "{}:{} action réalisée ({}, {}, {})".format(
        action, postact, user, chemin, media_name)
    return (1, msg)


def synchronise(totem, directory):
    running('run')
    options = ('-urLog --delete-after --exclude=result.db '
               '--delete-excluded --usermap=*:edkuser --groupmap=*:pi')
    commande = "/usr/bin/rsync {} debian@54.38.42.84::totems/{}/ \
                 {}/".format(options, totem, directory)
    print(commande)
    runcmd(commande, running('pause'))


def createlink(dirtolink):
    listd = [d for d in os.listdir(dirtolink)]
    for d in listd:
        verifdirexist(opj(kioskdir, d))
        listf = [opj(d, f)
                 for f in os.listdir(
            opj(dirtolink, d))]
        for f in listf:
            if not os.path.exists(opj(kioskdir, f)):
                os.symlink(opj(dirtolink, f),
                           opj(kioskdir, f))
                os.chown(opj(kioskdir, f), edkuid, piguid)


def getlistdir(dir):
    if os.path.isdir(dir):
        return [d for d in os.listdir(dir)].sort()
    return []


def verifdirexist(path):
    if not os.path.exists(path):
        os.makedirs(path)
        while 1:
            if os.path.basename(os.path.dirname(path)) == 'home':
                break
            os.chown(path, edkuid, piguid)
            path = os.path.dirname(path)


def main(macadress):
    device = getdevice(macadress)
    device_id = device.get('id', None)
    totem = device.get('totem', None)
    master = device.get('master', None)
    logger.info("device_id: %s", str(device_id))
    if device_id:
        updates = getlistupdate(device_id)
        if device.get('shortName') == 'Fauxpourtest':
            print(updates)
        elif updates:
            for upd in updates:
                update = getupdate(upd['action'])
                u, msg = procces_update(update)
                if u == 2:
                    logger.error(msg)
                else:
                    logger.info(msg)
                updatestatus(device_id, upd['action'], u)
        else:
            logger.info("Pas de mise à jour pour le device")
        listplugs = getlistdir(opj(kioskdir, 'ukplugs'))
        os.listdir
        if totem and getrunning() != 'run':
            synchronise(totem, totemdir)
            createlink(totemdir)
        if master and getrunning() != 'run':
            synchronise(master, masterdir)
            createlink(masterdir)
        runcmd("/usr/bin/find {} -xtype l -delete".format(kioskdir))
        if listplugs != getlistdir(opj(kioskdir, 'ukplugs')):
            runcmd("supervisorctl restart interface")

    else:
        logger.info("Le device avec l'adresse mac %s inconu", macadress)


# mise a jour des anciens iomanage
if not os.path.exists(totemdir) and os.path.exists(kioskdir):
    os.rename(kioskdir, totemdir)
verifdirexist(kioskdir)
verifdirexist(totemdir)
verifdirexist(masterdir)
running('pause')


if __name__ == "__main__":
    if 'debug' in sys.argv:
        debug = True
        print("Mode debug")
    if 'test' in sys.argv:
        print("Lancement des tests")
        debug = True
        macadress = '00:00:00:00:00:00'
        device = getdevice(macadress)
        if device['shortName'] != 'Fauxpourtest':
            print('Erreur Shortname')
        if device['id'] != 98:
            print('Erreur id')
        kioskdir = '{}/.kioskfiles'.format('/tmp')
        totemdir = '{}/.totemfiles'.format('/tmp')
        masterdir = '{}/.masterfiles'.format('/tmp')
        main(macadress)
        exit()
    else:
        macadress = getmac()
        x = 0
        while True:
            main(macadress)
            sleep(60)
