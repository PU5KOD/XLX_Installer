#!/bin/bash
sudo systemctl stop xlxd.service
sudo systemctl disable xlxd.service
sudo rm -r /usr/src/xlxd/ /xlxd/ /var/www/html/xlxd/
sudo rm /etc/init.d/xlxd /var/log/xlxd.* /etc/apache2/sites-available/xlx*.*
sudo systemctl daemon-reload
