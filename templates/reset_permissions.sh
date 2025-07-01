#!/bin/bash
# Script to reset permissions for XLX Reflector directories and files with error checking

# Set the fixed character limit
MAX_WIDTH=100
cols=$(tput cols 2>/dev/null || echo "$MAX_WIDTH")
width=$(( cols < MAX_WIDTH ? cols : MAX_WIDTH ))

# Function to create different types of lines adjusted to length
line_type1() {
    printf "%${width}s\n" | tr ' ' '_'
}
line_type2() {
    printf "%${width}s\n" | tr ' ' '='
}

# Function to display text with adjusted line breaks
print_wrapped() {
    echo "$1" | fold -s -w "$width"
}

# Color definitions
RED='\033[0;31m'
RED_BRIGHT='\033[1;31m'
GREEN='\033[0;32m'
GREEN_BRIGHT='\033[1;32m'
BLUE='\033[0;34m'
BLUE_BRIGHT='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions to display text with adjusted line breaks and colors
print_red() { echo -e "${RED}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_redb() { echo -e "${RED_BRIGHT}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_green() { echo -e "${GREEN}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_greenb() { echo -e "${GREEN_BRIGHT}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_blue() { echo -e "${BLUE}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_blueb() { echo -e "${BLUE_BRIGHT}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_yellow() { echo -e "${YELLOW}$(echo "$1" | fold -s -w "$width")${NC}"; }
center_wrap_color() {
    local color="$1"
    local text="$2"
    local wrapped_lines
    IFS=$'\n' read -rd '' -a wrapped_lines <<<"$(echo "$text" | fold -s -w "$width")"
    for line in "${wrapped_lines[@]}"; do
        local line_length=${#line}
        local padding=$(( (width - line_length) / 2 ))
        printf "%b%*s%s%b\n" "$color" "$padding" "" "$line" "$NC"
    done
}

# Start script
clear
line_type1
echo ""
center_wrap_color $GREEN_BRIGHT "Resetting Permissions for XLX Reflector"
line_type1
echo ""

# Detecting Apache user
print_blueb "DETECTING APACHE USER..."
print_blue "========================"
echo ""
APACHE_USER=$(ps aux | grep -E '[a]pache|[h]ttpd' | grep -v root | head -1 | awk '{print $1}')
if [ -z "$APACHE_USER" ]; then
    print_yellow "Apache user not detected automatically. Using default 'www-data'."
    APACHE_USER="www-data"
else
    print_green "Apache user detected: $APACHE_USER"
fi
WEBDIR="/var/www/html"
echo ""

# Setting ownership for web directory
print_blueb "ADJUSTING OWNERSHIP..."
print_blue "======================"
echo ""
print_blue "Setting ownership for web directory ($WEBDIR)..."
chown -R "$APACHE_USER:$APACHE_USER" "$WEBDIR/"
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set ownership for $WEBDIR."
    exit 1
else
    print_green "✔ Ownership set for web directory"
fi
echo ""

# Setting ownership for XLX directory
print_blue "Setting ownership for XLX directory (/xlxd)..."
chown -R "$APACHE_USER:$APACHE_USER" /xlxd/
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set ownership for /xlxd."
    exit 1
else
    print_green "✔ Ownership set for XLX root file system"
fi
echo ""

# Setting permissions
print_blueb "SETTING PERMISSIONS..."
print_blue "======================"
echo ""
print_blue "Setting directory permissions for /xlxd (755)..."
find /xlxd -type d -exec chmod 755 {} \;
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set directory permissions for /xlxd."
    exit 1
else
    print_green "✔ Root directory permissions successfully set"
fi
echo ""

print_blue "Setting directory permissions for $WEBDIR (755)..."
find "$WEBDIR" -type d -exec chmod 755 {} \;
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set directory permissions for $WEBDIR."
    exit 1
else
    print_green "✔ Web directory permissions successfully set"
fi
echo ""

print_blue "Setting file permissions for web directory (644)..."
find "$WEBDIR" -type f -exec chmod 644 {} \;
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set file permissions for $WEBDIR."
    exit 1
else
    print_green "✔ Web file permissions successfully set"
fi
echo ""

print_blue "Setting permissions for xlx_log.service (755)..."
chmod 755 /etc/systemd/system/xlx_log.service
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for xlx_log.service."
    exit 1
else
    print_green "✔ Permissions for xlx_log.service successfully set"
fi
echo ""

print_blue "Setting permissions for xlxecho.service (755)..."
chmod 755 /etc/systemd/system/xlxecho.service
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for xlxecho.service."
else
    print_green "✔ Permissions for xlxecho.service successfully set"
    exit 1
fi
echo ""

print_blue "Setting permissions for users DB, update_XLX_db (755)..."
chmod 755 /etc/systemd/system/update_XLX_db.service*
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for users DB, update_XLX_db."
else
    print_green "✔ Permissions for users DB, update_XLX_db successfully set"
fi
echo ""

print_blue "Setting permissions for /xlxd/users_db/create_user_db.php (755)..."
chmod 755 /xlxd/users_db/create_user_db.php
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /xlxd/users_db/create_user_db.php."
    exit 1
else
    print_green "✔ Permissions for /xlxd/users_db/create_user_db.php successfully set"
fi
echo ""

print_blue "Setting permissions for /xlxd/users_db/update_db.sh (755)..."
chmod 755 /xlxd/users_db/update_db.sh
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /xlxd/users_db/update_db.sh."
    exit 1
else
    print_green "✔ Permissions for /xlxd/users_db/update_db.sh successfully set"
fi
echo ""

print_blue "Setting permissions for /xlxd/users_db/user* files (644)..."
chmod 644 /xlxd/users_db/user*
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /xlxd/users_db/user* files."
    exit 1
else
    print_green "✔ Permissions for /xlxd/users_db/user* files successfully set"
fi
echo ""

print_blue "Setting permissions for /xlxd/xlxd.* files (644)..."
chmod 644 /xlxd/xlxd.*
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /xlxd/xlxd.* files."
    exit 1
else
    print_green "✔ Permissions for /xlxd/xlxd.* files successfully set"
fi
echo ""

print_blue "Setting permissions for /var/log/xlx.log file (644)..."
chmod 644 /var/log/xlx.log
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /var/log/xlx.log file."
    exit 1
else
    print_green "✔ Permissions for /var/log/xlx.log file successfully set"
fi
echo ""

print_blue "Setting permissions for /xlxd/xlxd (755)..."
chmod 755 /xlxd/xlxd
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /xlxd/xlxd."
    exit 1
else
    print_green "✔ Permissions for /xlxd/xlxd successfully set"
fi
echo ""

print_blue "Setting permissions for /xlxd/xlxecho (755)..."
chmod 755 /xlxd/xlxecho
if [ $? -ne 0 ]; then
    print_redb "Error: Failed to set permissions for /xlxd/xlxecho."
    exit 1
else
    print_green "✔ Permissions for /xlxd/xlxecho successfully set"
fi
echo ""

line_type2
echo ""
center_wrap_color $GREEN_BRIGHT "All permissions reset successfully!"
echo ""
line_type2
