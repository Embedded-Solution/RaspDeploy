#!/usr/bin/python3
# usage:
#   $ hostapd_cli -a 'hostapd_cli_daemon.py'
# as a daemon
#   $ sudo setsid hostapd_cli -a '/usr/local/sbin/hostapd_cli_daemon.py' >/dev/null 2>&1 < /dev/null &
#
# First create log folder and set hostapd_cli_daemon.py executable:
#   $ sudo mkdir /var/log/hotspot
#   $ sudo chmod a+x

import sys
from datetime import datetime
import logging
from logging.handlers import RotatingFileHandler
import urllib.request


def on_new_client(interface, event, macaddress):
    timestamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
    response = urllib.request.urlopen(F"http://127.0.0.1/hotspot?iface={interface}&ev={event}&mac={macaddress}").read()
    if response == b'OK':
        logger.info(F'{timestamp} {interface} {event} {macaddress} response={response.decode("utf-8")}')
    else:
        logger.warning(F'{timestamp} {interface} {event} {macaddress} response={response.decode("utf-8")[0:40]}...')


if __name__ == "__main__":
    logger = logging.getLogger("Rotating Log")
    logger.setLevel(logging.INFO)

    # add a rotating handler
    handler = RotatingFileHandler('/var/log/hotspot/hostapd_cli.log', maxBytes=500000,
                                  backupCount=20)
    logger.addHandler(handler)
    on_new_client(sys.argv[1], sys.argv[2], sys.argv[3])
