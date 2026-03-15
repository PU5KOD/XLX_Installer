#!/bin/bash
# Desinstalador para o servidor XLX Reflector
# Remove arquivos, serviços e configurações criadas pelo script xlxdinstaller.sh
# Criado para reverter a instalação do XLX Multiprotocol Ham Radio Reflector

# Redirect all output to the log and keep it in the terminal
LOGFILE="$PWD/log/log_xlx_uninstall_$(date +%F_%H-%M-%S).log"
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
    printf '%*s\n' "$width" '' | tr ' ' '_'
}
line_type2() {
    printf '%*s\n' "$width" '' | tr ' ' '='
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
    IFS=$'\n' read -rd '' -a wrapped_lines <<<"$(echo "$text" | fold -s -w "$width")" || true
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

# List available Apache sites and ask user to pick the reflector domain
while true; do
    echo ""
    print_blueb "AVAILABLE SITES IN /etc/apache2/sites-available:"
    print_blue "=================================================="
    echo ""
    mapfile -t SITE_FILES < <(find /etc/apache2/sites-available/ -maxdepth 1 -name "*.conf" ! -name "000-default.conf" ! -name "default-ssl.conf" | sort)
    if [ ${#SITE_FILES[@]} -eq 0 ]; then
        print_red "No custom sites found in /etc/apache2/sites-available/. Nothing to remove."
        exit 1
    fi
    for i in "${!SITE_FILES[@]}"; do
        SITE_NAME=$(basename "${SITE_FILES[$i]}" .conf)
        printf "  %2d) %s\n" "$((i+1))" "$SITE_NAME"
    done
    echo ""
    print_yellow "Enter the number corresponding to the reflector domain to remove:"
    printf "> "
    read -r SITE_CHOICE
    if [[ "$SITE_CHOICE" =~ ^[0-9]+$ ]] && (( SITE_CHOICE >= 1 && SITE_CHOICE <= ${#SITE_FILES[@]} )); then
        XLXDOMAIN=$(basename "${SITE_FILES[$((SITE_CHOICE-1))]}" .conf)
        break
    else
        print_red "Invalid selection. Please enter a number from the list."
    fi
done
print_yellow "Using: $XLXDOMAIN"
line_type1

# Confirm uninstallation
echo ""
print_blueb "WARNING: This will remove all XLX Reflector files, services, and configurations."
while true; do
    print_yellow "Are you sure you want to proceed with uninstallation? (YES/NO)"
    printf "> "
    read -r CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:lower:]' '[:upper:]')
    if [[ "$CONFIRM" == "YES" || "$CONFIRM" == "NO" ]]; then
        break
    else
        print_redb "Please enter 'YES' or 'NO'."
    fi
done
if [ "$CONFIRM" == "NO" ]; then
    print_red "Uninstallation aborted by user."
    exit 1
fi

# Stop and disable services
echo ""
print_blueb "STOPPING AND DISABLING SERVICES..."
print_blue "==================================="
echo ""
for SVC in xlxd.service xlxecho.service xlx_log.service; do
    if systemctl is-active --quiet "$SVC" 2>/dev/null; then
        systemctl stop "$SVC"
        print_green "✔ Stopped $SVC."
    fi
    if systemctl is-enabled --quiet "$SVC" 2>/dev/null; then
        systemctl disable "$SVC"
        print_green "✔ Disabled $SVC."
    fi
done

# Stop and disable the user database update timer
echo ""
print_blueb "STOPPING AND DISABLING USER DATABASE TIMER..."
print_blue "=============================================="
echo ""
for UNIT in update_XLX_db.timer update_XLX_db.service; do
    if systemctl is-active --quiet "$UNIT" 2>/dev/null; then
        systemctl stop "$UNIT"
        print_green "✔ Stopped $UNIT."
    fi
    if systemctl is-enabled --quiet "$UNIT" 2>/dev/null; then
        systemctl disable "$UNIT"
        print_green "✔ Disabled $UNIT."
    fi
done

# Remove files and folders
echo ""
print_blueb "REMOVING FILES AND FOLDERS..."
print_blue "============================="
echo ""
for dir in "/xlxd" "/var/www/html/xlxd" "/usr/src/xlxd" "/usr/src/XLXEcho" "/usr/src/XLX_Dark_Dashboard"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        print_green "✔ Removed directory: $dir"
    fi
done
for file in \
    "/etc/systemd/system/xlxd.service" \
    "/etc/systemd/system/xlxecho.service" \
    "/etc/systemd/system/xlx_log.service" \
    "/etc/systemd/system/update_XLX_db.service" \
    "/etc/systemd/system/update_XLX_db.timer" \
    "/usr/local/bin/xlx_log.sh" \
    "/etc/logrotate.d/xlx_logrotate.conf" \
    "/var/log/xlxd.xml" \
    "/var/log/xlxd.pid" \
    "/var/log/xlx.log" \
    "/var/log/xlxecho.log"; do
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
    mapfile -t SSL_FILES < <(find /etc/apache2/sites-available/ -maxdepth 1 -name "${XLXDOMAIN}*.conf" ! -name "${XLXDOMAIN}.conf" 2>/dev/null)
    if [ ${#SSL_FILES[@]} -gt 0 ]; then
        print_yellow "SSL configuration files found for $XLXDOMAIN:"
        for f in "${SSL_FILES[@]}"; do
            print_wrapped "  • $(basename "$f")"
        done
        echo ""
        while true; do
            print_yellow "Would you like to remove the SSL certificate for $XLXDOMAIN? (YES/NO)"
            printf "> "
            read -r CERTBOT_CONFIRM
            CERTBOT_CONFIRM=$(echo "$CERTBOT_CONFIRM" | tr '[:lower:]' '[:upper:]')
            if [[ "$CERTBOT_CONFIRM" == "YES" || "$CERTBOT_CONFIRM" == "NO" ]]; then
                break
            else
                print_redb "Please enter 'YES' or 'NO'."
            fi
        done
        if [ "$CERTBOT_CONFIRM" == "YES" ]; then
            certbot delete --cert-name "$XLXDOMAIN" >/dev/null 2>&1
            for f in "${SSL_FILES[@]}"; do
                rm -f "$f"
                print_green "✔ Removed SSL file: $(basename "$f")"
            done
        fi
    else
        print_yellow "No SSL configuration files found for $XLXDOMAIN. Skipping."
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
