#!/bin/bash

# Script to reset permissions for XLX reflector directories and files

echo "--------------------------------------"
echo "Starting permissions reset process..."

# Detecting Apache user
echo "Detecting Apache user..."
APACHE_USER=$(ps aux | grep -E '[a]pache|[h]ttpd' | grep -v root | head -1 | awk '{print $1}')
if [ -z "$APACHE_USER" ]; then
    APACHE_USER="www-data"
    echo "Apache user not found, defaulting to www-data."
else
    echo "Apache user detected: $APACHE_USER."
fi
echo "--------------------------------------"

# Setting web directory path
WEBDIR="/var/www/html/"
echo "Using web directory: $WEBDIR"

# Setting ownership for web directory
echo "Configuring ownership for $WEBDIR..."
chown -R "$APACHE_USER:$APACHE_USER" "$WEBDIR/"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set ownership for $WEBDIR."
    exit 1
else
    echo "Ownership for $WEBDIR set successfully."
fi
echo "--------------------------------------"

# Setting ownership for XLX directory
echo "Configuring ownership for /xlxd..."
chown -R "$APACHE_USER:$APACHE_USER" /xlxd/
if [ $? -ne 0 ]; then
    echo "Error: Failed to set ownership for /xlxd."
    exit 1
else
    echo "Ownership for /xlxd set successfully."
fi
echo "--------------------------------------"

# Setting directory permissions for XLX
echo "Configuring directory permissions for /xlxd..."
find /xlxd -type d -exec chmod 755 {} \;
if [ $? -ne 0 ]; then
    echo "Error: Failed to set directory permissions for /xlxd."
    exit 1
else
    echo "Directory permissions for /xlxd set successfully."
fi
echo "--------------------------------------"

# Setting directory permissions for web directory
echo "Configuring directory permissions for $WEBDIR..."
find "$WEBDIR" -type d -exec chmod 755 {} \;
if [ $? -ne 0 ]; then
    echo "Error: Failed to set directory permissions for $WEBDIR."
    exit 1
else
    echo "Directory permissions for $WEBDIR set successfully."
fi
echo "--------------------------------------"

# Setting file permissions for web directory
echo "Configuring file permissions for $WEBDIR..."
find "$WEBDIR" -type f -exec chmod 644 {} \;
if [ $? -ne 0 ]; then
    echo "Error: Failed to set file permissions for $WEBDIR."
    exit 1
else
    echo "File permissions for $WEBDIR set successfully."
fi
echo "--------------------------------------"

# Setting permissions for create_user_db.php
echo "Configuring permissions for /xlxd/users_db/create_user_db.php..."
chmod 755 /xlxd/users_db/create_user_db.php
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for /xlxd/users_db/create_user_db.php."
    exit 1
else
    echo "Permissions for /xlxd/users_db/create_user_db.php set successfully."
fi
echo "--------------------------------------"

# Setting permissions for update_db.sh
echo "Configuring permissions for /xlxd/users_db/update_db.sh..."
chmod 755 /xlxd/users_db/update_db.sh
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for /xlxd/users_db/update_db.sh."
    exit 1
else
    echo "Permissions for /xlxd/users_db/update_db.sh set successfully."
fi
echo "--------------------------------------"

# Setting permissions for user database files
echo "Configuring permissions for /xlxd/users_db/user* files..."
chmod 644 /xlxd/users_db/user*
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for /xlxd/users_db/user* files."
    exit 1
else
    echo "Permissions for /xlxd/users_db/user* files set successfully."
fi
echo "--------------------------------------"

# Setting permissions for xlxd configuration files
echo "Configuring permissions for /xlxd/xlxd.* files..."
chmod 644 /xlxd/xlxd.*
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for /xlxd/xlxd.* files."
    exit 1
else
    echo "Permissions for /xlxd/xlxd.* files set successfully."
fi
echo "--------------------------------------"

# Setting permissions for xlxd executable
echo "Configuring permissions for /xlxd/xlxd..."
chmod 755 /xlxd/xlxd
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for /xlxd/xlxd."
    exit 1
else
    echo "Permissions for /xlxd/xlxd set successfully."
fi
echo "--------------------------------------"

# Setting permissions for xlxecho executable
echo "Configuring permissions for /xlxd/xlxecho..."
chmod 755 /xlxd/xlxecho
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for /xlxd/xlxecho."
    exit 1
else
    echo "Permissions for /xlxd/xlxecho set successfully."
fi
echo "--------------------------------------"

echo "Permissions reset process completed successfully!"
