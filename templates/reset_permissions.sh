#!/bin/bash
APACHE_USER=$(ps aux | grep -E '[a]pache|[h]ttpd' | grep -v root | head -1 | awk '{print $1}')
if [ -z "$APACHE_USER" ]; then
    APACHE_USER="www-data"
fi
WEBDIR="/var/www/html/"
chown -R "$APACHE_USER:$APACHE_USER" "$WEBDIR/"
chown -R "$APACHE_USER:$APACHE_USER" /xlxd/
find /xlxd -type d -exec chmod 755 {} \;
find "$WEBDIR" -type d -exec chmod 755 {} \;
find "$WEBDIR" -type f -exec chmod 644 {} \;
chmod 755 /xlxd/users_db/create_user_db.php
chmod 755 /xlxd/users_db/update_db.sh
chmod 644 /xlxd/users_db/user*
chmod 644 /xlxd/xlxd.*
chmod 755 /xlxd/xlxd
chmod 755 /xlxd/xlxecho