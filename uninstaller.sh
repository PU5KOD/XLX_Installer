#!/bin/bash
# Desinstalador para o servidor XLX Reflector
# Remove arquivos, serviços e configurações criadas pelo script xlxdinstaller.sh
# Criado para reverter a instalação do XLX Multiprotocol Ham Radio Reflector

# Redirect all output to the log and keep it in the terminal
LOGFILE="$PWD/xlx_uninstall_$(date +%F_%H-%M-%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

# Root user check
if [ "$(whoami)" != "root" ]; then
    echo "You must be root to run this script!"
    exit 1
fi

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

# Functions to display text with adjusted line breaks and colors
print_wrapped() {
    echo "$1" | fold -s -w "$width"
}
print_red() { echo -e "\033[0;31m$(echo "$1" | fold -s -w "$width")\033[0m"; }
print_redb() { echo -e "\033[1;31m$(echo "$1" | fold -s -w "$width")\033[0m"; }
print_green() { echo -e "\033[0;32m$(echo "$1" | fold -s -w "$width")\033[0m"; }
print_greenb() { echo -e "\033[1;32m$(echo "$1" | fold -s -w "$width")\033[0m"; }
print_blue() { echo -e "\033[0;34m$(echo "$1" | fold -s -w "$width")\033[0m"; }
print_blueb() { echo -e "\033[1;34m$(echo "$1" | fold -s -w "$width")\033[0m"; }
print_yellow() { echo -e "\033[1;33m$(echo "$1" | fold -s -w "$width")\033[0m"; }
center_wrap_color() {
    local color="$1"
    local text="$2"
    local wrapped_lines
    IFS=$'\n' read -rd '' -a wrapped_lines <<<"$(echo "$text" | fold -s -w "$width")"
    for line in "${wrapped_lines[@]}"; do
        local line_length=${#line}
        local padding=$(( (width - line_length) / 2 ))
        printf "%b%*s%s%b\n" "$color" "$padding" "" "$line" "\033[0m"
    done
}

# Start of uninstallation process
clear
line_type1
echo ""
center_wrap_color "\033[1;34m" "XLX Reflector Uninstaller"
center_wrap_color "\033[1;34m" "This script will remove the XLX Reflector, its dashboard, and related configurations."
echo ""
line_type1

# Ask for the domain to locate Apache configuration
while true; do
    echo ""
    print_redb "Mandatory"
    print_wrapped "Please enter the web address (FQDN) used for the reflector dashboard (e.g., xlx.domain.com):"
    printf "> "
    read -r XLXDOMAIN
    if [ -z "$XLXDOMAIN" ]; then
        print_red "Error: This field is mandatory and cannot be empty. Try again!"
    else
        break
    fi
done
print_yellow "Using: $XLXDOMAIN"
line_type1

# Confirm uninstallation
echo ""
print_blueb "WARNING: This will remove all XLX Reflector files, services, and configurations."
while true; do
    print_yellow "Are you sure you want to proceed with uninstallation? (Y/N)"
    printf "> "
    read -r CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:lower:]' '[:upper:]')
    if [[ "$CONFIRM" == "Y" || "$CONFIRM" == "N" ]]; then
        break
    else
        print_redb "Please enter 'Y' or 'N'."
    fi
done
if [ "$CONFIRM" == "N" ]; then
    print_red "Uninstallation aborted by user."
    exit 1
fi

# Stop and disable services
echo ""
print_blueb "STOPPING AND DISABLING SERVICES..."
print_blue "=================================="
echo ""
if systemctl is-active --quiet xlxd; then
    systemctl stop xlxd
    print_green "✔ Stopped xlxd service."
fi
if systemctl is-enabled --quiet xlxd; then
    systemctl disable xlxd
    print_green "✔ Disabled xlxd service."
fi
if systemctl is-active --quiet xlxecho.service; then
    systemctl stop xlxecho.service
    print_green "✔ Stopped xlxecho service."
fi
if systemctl is-enabled --quiet xlxecho.service; then
    systemctl disable xlxecho.service
    print_green "✔ Disabled xlxecho service."
fi
if systemctl is-active --quiet update_XLX_db.timer; then
    systemctl stop update_XLX_db.timer
    systemctl stop update_XLX_db.service
    print_green "✔ Stopped update_XLX_db timer and service."
fi
if systemctl is-enabled --quiet update_XLX_db.timer; then
    systemctl disable update_XLX_db.timer
    systemctl disable update_XLX_db.service
    print_green "✔ Disabled update_XLX_db timer and service."
fi

# Remove cron job if it exists
if command -v crontab &>/dev/null; then
    if crontab -l 2>/dev/null | grep -q "/xlxd/users_db/create_user_db.php"; then
        crontab -l 2>/dev/null | grep -v "/xlxd/users_db/create_user_db.php" | crontab -
        print_green "✔ Removed cron job for user database update."
    fi
fi

# Remove files and directories
echo ""
print_blueb "REMOVING FILES AND DIRECTORIES..."
print_blue "================================="
echo ""
for dir in "/usr/src/xlxd" "/xlxd" "/var/www/html/xlxd" "/usr/src/XLXEcho" "/usr/src/XLX_Dark_Dashboard"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        print_green "✔ Removed directory: $dir"
    fi
done
for file in "/etc/init.d/xlxd" "/var/log/xlxd.xml" "/etc/systemd/system/xlxecho.service" \
            "/etc/systemd/system/update_XLX_db.service" "/etc/systemd/system/update_XLX_db.timer"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        print_green "✔ Removed file: $file"
    fi
done

# Remove Apache configuration
echo ""
print_blueb "REMOVING APACHE CONFIGURATION..."
print_blue "================================"
echo ""
APACHE_CONF="/etc/apache2/sites-available/$XLXDOMAIN.conf"
if [ -f "$APACHE_CONF" ]; then
    /usr/sbin/a2dissite "$XLXDOMAIN" >/dev/null 2>&1
    rm -f "$APACHE_CONF"
    print_green "✔ Removed Apache configuration: $APACHE_CONF"
fi
if [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
    /usr/sbin/a2ensite 000-default >/dev/null 2>&1
    print_green "✔ Re-enabled default Apache site."
fi
systemctl restart apache2 >/dev/null 2>&1
print_green "✔ Apache service restarted."

# Optional: Remove Certbot and SSL certificates
echo ""
print_blueb "CHECKING FOR CERTBOT AND SSL CERTIFICATES..."
print_blue "==========================================="
echo ""
if command -v certbot &>/dev/null; then
    while true; do
        print_yellow "Certbot is installed. Would you like to remove the SSL certificate for $XLXDOMAIN and Certbot? (Y/N)"
        printf "> "
        read -r CERTBOT_CONFIRM
        CERTBOT_CONFIRM=$(echo "$CERTBOT_CONFIRM" | tr '[:lower:]' '[:upper:]')
        if [[ "$CERTBOT_CONFIRM" == "Y" || "$CERTBOT_CONFIRM" == "N" ]]; then
            break
        else
            print_redb "Please enter 'Y' or 'N'."
        fi
    done
    if [ "$CERTBOT_CONFIRM" == "Y" ]; then
        certbot delete --cert-name "$XLXDOMAIN" >/dev/null 2>&1
        print_green "✔ Removed SSL certificate for $XLXDOMAIN."
    fi
fi

# Reload systemd daemon
systemctl daemon-reload
print_green "✔ Systemd daemon reloaded."

# Final message
echo ""
line_type2
echo ""
center_wrap_color "\033[1;32m" "XLX Reflector Uninstallation Completed Successfully!"
center_wrap_color "\033[1;32m" "All XLX-related files, services, and configurations have been removed."
center_wrap_color "\033[1;32m" "Log file saved at: $LOGFILE"
echo ""
line_type2
