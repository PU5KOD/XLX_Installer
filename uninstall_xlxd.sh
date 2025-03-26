#!/bin/bash
echo "XLX Uninstaller"
echo ""
read -r -p "What is the web address (FQDN) of the reflector dashboard? " XLXDOMAIN
sudo systemctl stop xlxd.service
sudo systemctl disable xlxd.service
/usr/sbin/a2dissite $XLXDOMAIN.conf
/usr/sbin/a2ensite 000-default
sudo rm -r /usr/src/xlxd/ /xlxd/ /var/www/html/xlxd/
sudo rm /etc/init.d/xlxd /var/log/xlxd.* /etc/apache2/sites-available/$XLXDOMAIN
sudo systemctl daemon-reload
