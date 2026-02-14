#!/bin/bash
################################################################################
# XLX Multiprotocol Amateur Radio Reflector Installer
# A tool to install XLXD, your own D-Star Reflector
# For more information, please visit https://xlxbbs.epf.lu/
#
# Customized by Daniel K., PU5KOD
# Based on original work by N5AMD
#
# This script installs:
# - XLX Reflector (from PU5KOD/xlxd.git)
# - XLX Dark Dashboard (from PU5KOD/XLX_Dark_Dashboard.git)
# - Optional: Echo Test Server (from PU5KOD/XLXEcho.git)
################################################################################

set -o pipefail

################################################################################
# CONFIGURATION AND CONSTANTS
################################################################################

# Script directories and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGDIR="$SCRIPT_DIR/log"
LOGFILE="$LOGDIR/log_xlx_install_$(date +%F_%H-%M-%S).log"

# Ensure log directory exists
mkdir -p "$LOGDIR"

# Redirect all output to log file and terminal
exec > >(tee -a "$LOGFILE") 2>&1

# Terminal width configuration
MAX_WIDTH=100
cols=$(tput cols 2>/dev/null || echo "$MAX_WIDTH")
width=$(( cols < MAX_WIDTH ? cols : MAX_WIDTH ))

# Source visual functions library
if [ -f "$SCRIPT_DIR/templates/cli_visual_unicode.sh" ]; then
    source "$SCRIPT_DIR/templates/cli_visual_unicode.sh"
else
    echo "ERROR: cli_visual_unicode.sh not found in templates/"
    exit 1
fi

# Installation directories
XLXINSTDIR="/usr/src"
XLXDIR="/xlxd"
WEBDIR="/var/www/html/xlxd"

# Repository URLs (customized versions by PU5KOD)
XLXDREPO="https://github.com/PU5KOD/xlxd.git"
XLXECHO="https://github.com/PU5KOD/XLXEcho.git"
XLXDASH="https://github.com/PU5KOD/XLX_Dark_Dashboard.git"

# External resources
DMRIDURL="http://xlxapi.rlx.lu/api/exportdmr.php"
INFREF="https://xlxbbs.epf.lu/"

# System detection
LOCAL_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s v4.ident.me)
NETACT=$(ip -o addr show up | awk '{print $2}' | grep -v lo | head -n1)
PHPVER=$(php -v 2>/dev/null | head -n1 | awk '{print $2}' | cut -d. -f1,2)

# Required packages
APPS="git git-core make gcc g++ pv sqlite3 apache2 php libapache2-mod-php php-cli php-xml php-mbstring php-curl php-sqlite3 build-essential vnstat certbot python3-certbot-apache"

################################################################################
# LOGGING FUNCTIONS
################################################################################

log_info() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $message" >&2
    msg_info "$message"
}

log_success() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $message" >&2
    msg_success "$message"
}

log_warn() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $message" >&2
    msg_warn "$message"
}

log_error() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $message" >&2
    msg_error "$message"
}

log_fatal() {
    local message="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FATAL] $message" >&2
    msg_fatal "$message"
    exit 1
}

log_command() {
    local command="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [COMMAND] $command" >> "$LOGFILE"
}

log_output() {
    local output="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [OUTPUT] $output" >> "$LOGFILE"
}

################################################################################
# PERMISSION MANAGEMENT FUNCTIONS
################################################################################

set_executable_permissions() {
    local path="$1"
    log_info "Setting executable permissions (755) on: $path"
    chmod 755 "$path" || log_error "Failed to set permissions on $path"
}

set_config_permissions() {
    local path="$1"
    log_info "Setting config file permissions (644) on: $path"
    chmod 644 "$path" || log_error "Failed to set permissions on $path"
}

set_directory_permissions() {
    local path="$1"
    local owner="${2:-root}"
    log_info "Setting directory permissions on: $path (owner: $owner)"
    
    if [ -d "$path" ]; then
        # Set directory permissions to 755
        find "$path" -type d -exec chmod 755 {} \;
        
        # Set executable files (binaries and scripts) to 755
        find "$path" -type f -executable -exec chmod 755 {} \;
        
        # Set shell scripts to 755 (even if not currently executable)
        find "$path" -type f -name "*.sh" -exec chmod 755 {} \;
        
        # Set service files to 644
        find "$path" -type f -name "*.service" -exec chmod 644 {} \;
        find "$path" -type f -name "*.timer" -exec chmod 644 {} \;
        
        # Set non-executable, non-script, non-service files to 644
        find "$path" -type f ! -executable ! -name "*.sh" ! -name "*.service" ! -name "*.timer" -exec chmod 644 {} \;
        
        # Set ownership
        chown -R "$owner:$owner" "$path"
        log_success "Permissions set for $path"
    else
        log_error "Directory not found: $path"
    fi
}

################################################################################
# INITIAL CHECKS
################################################################################

check_root() {
    log_info "Checking root privileges..."
    
    if [ "$(id -u)" -ne 0 ]; then
        msg_warn "This script is not being run as root."
        read -r -p "Do you want to relaunch with sudo? (y/n) " answer
        
        case "$answer" in
            y|Y|yes|YES)
                log_info "Relaunching with sudo..."
                exec sudo "$0" "$@"
                ;;
            *)
                log_fatal "Operation cancelled by user."
                ;;
        esac
    fi
    
    log_success "Running with root privileges"
}

check_internet() {
    log_info "Checking internet connection..."
    
    if ! ping -c 1 google.com &>/dev/null; then
        log_fatal "Unable to proceed, no internet connection detected. Please check your network."
    fi
    
    log_success "Internet connection verified"
}

check_distro() {
    log_info "Checking distribution compatibility..."
    
    if [ ! -e "/etc/debian_version" ]; then
        msg_warn "This script has only been tested on Debian-based distributions."
        read -p "Do you want to continue anyway? (Y/N) " answer
        [[ "$answer" =~ ^[yY](es)?$ ]] || log_fatal "Execution cancelled."
        log_warn "Continuing on non-Debian system"
    else
        log_success "Debian-based distribution detected"
    fi
}

check_existing_install() {
    log_info "Checking for existing XLX installation..."
    
    if [ -e "$XLXDIR/xlxd" ]; then
        sep_block
        echo ""
        msg_fatal "XLXD ALREADY INSTALLED! Run the 'uninstaller.sh' first."
    fi
    
    log_success "No existing installation found"
}

################################################################################
# TIMEZONE RESOLUTION
################################################################################

resolve_timezone() {
    local input="$1"
    local input_upper input_lower match
    
    input_upper=$(echo "$input" | tr '[:lower:]' '[:upper:]')
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    # Case-insensitive match against the official system list
    match=$(timedatectl list-timezones | grep -iFx "$input" 2>/dev/null || true)
    [[ -n "$match" ]] && { echo "$match"; return 0; }
    
    match=$(timedatectl list-timezones | grep -iFx "$input_upper" 2>/dev/null || true)
    [[ -n "$match" ]] && { echo "$match"; return 0; }
    
    match=$(timedatectl list-timezones | grep -iFx "$input_lower" 2>/dev/null || true)
    [[ -n "$match" ]] && { echo "$match"; return 0; }
    
    # GMT±X validation - validate only if it exists in tzdata
    if [[ "$input_upper" =~ ^GMT([+-]?)([0-9]{1,2})$ ]]; then
        local sign="${BASH_REMATCH[1]}"
        local num="${BASH_REMATCH[2]}"
        local candidate
        
        # POSIX inverted GMT logic - do NOT modify
        if [[ "$sign" == "-" ]]; then
            candidate="Etc/GMT+${num}"
        elif [[ "$sign" == "+" ]]; then
            candidate="Etc/GMT-${num}"
        else
            candidate="Etc/GMT"
        fi
        
        if [[ -f "/usr/share/zoneinfo/$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    fi
    
    echo ""
    return 1
}

################################################################################
# INPUT VALIDATION FUNCTIONS
################################################################################

validate_reflector_id() {
    local id="$1"
    [[ "$id" =~ ^[A-Z0-9]{3}$ ]]
}

validate_domain() {
    local domain="$1"
    [[ "$domain" =~ ^([a-z0-9-]+\.)+[a-z]{2,}$ ]]
}

validate_email() {
    local email="$1"
    [[ "$email" =~ ^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$ ]]
}

validate_callsign() {
    local callsign="$1"
    [[ "$callsign" =~ ^[A-Z0-9]{3,8}$ ]]
}

validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

validate_frequency() {
    local freq="$1"
    [[ "$freq" =~ ^[0-9]{9}$ ]]
}

################################################################################
# USER INPUT COLLECTION
################################################################################

collect_user_input() {
    clear
    sep_star
    echo ""
    banner "XLX MULTIPROTOCOL AMATEUR RADIO REFLECTOR INSTALLER"
    echo ""
    msg_info "Next, you will be asked some questions."
    msg_info "Answer with the requested information or press [ENTER] to accept the suggested value."
    echo ""
    sep_star
    echo ""
    section "REFLECTOR DATA INPUT"
    echo ""
    
    # 01. XLX Reflector ID
    log_info "Collecting reflector ID..."
    while true; do
        msg_caution "Mandatory"
        echo "01. XLX Reflector ID, 3 alphanumeric characters (e.g., 300, US1, BRA)"
        printf "> "
        read -r XRFDIGIT
        XRFDIGIT=$(echo "$XRFDIGIT" | tr '[:lower:]' '[:upper:]')
        
        if validate_reflector_id "$XRFDIGIT"; then
            break
        fi
        msg_warn "Invalid ID. Must be exactly 3 characters (A-Z and/or 0-9). Try again!"
    done
    
    XRFNUM="XLX$XRFDIGIT"
    msg_success "Using: $XRFNUM"
    log_output "Reflector ID: $XRFNUM"
    
    # 02. Dashboard FQDN
    log_info "Collecting dashboard domain..."
    echo ""
    sep_line
    echo ""
    while true; do
        msg_caution "Mandatory"
        echo "02. Dashboard FQDN (fully qualified domain name, e.g., xlxbra.net)"
        printf "> "
        read -r XLXDOMAIN
        XLXDOMAIN=$(echo "$XLXDOMAIN" | tr '[:upper:]' '[:lower:]')
        
        if validate_domain "$XLXDOMAIN"; then
            break
        fi
        msg_warn "Invalid domain. Must be a valid FQDN (e.g., xlx.example.com)."
    done
    msg_success "Using: $XLXDOMAIN"
    log_output "Dashboard FQDN: $XLXDOMAIN"
    
    # 03. Sysop Email
    log_info "Collecting sysop email..."
    echo ""
    sep_line
    echo ""
    while true; do
        msg_caution "Mandatory"
        echo "03. Sysop e-mail address"
        printf "> "
        read -r EMAIL
        EMAIL=$(echo "$EMAIL" | tr '[:upper:]' '[:lower:]')
        
        if validate_email "$EMAIL"; then
            break
        fi
        msg_warn "Invalid email format (e.g., user@domain.com)."
    done
    msg_success "Using: $EMAIL"
    log_output "Sysop email: $EMAIL"
    
    # 04. Sysop Callsign
    log_info "Collecting sysop callsign..."
    echo ""
    sep_line
    echo ""
    while true; do
        msg_caution "Mandatory"
        echo "04. Sysop callsign. Only letters and numbers allowed, max 8 characters."
        printf "> "
        read -r CALLSIGN
        CALLSIGN=$(echo "$CALLSIGN" | tr '[:lower:]' '[:upper:]')
        
        if validate_callsign "$CALLSIGN"; then
            break
        fi
        msg_warn "Invalid callsign. Use only letters and numbers, 3-8 characters."
    done
    msg_success "Using: $CALLSIGN"
    log_output "Sysop callsign: $CALLSIGN"
    
    # 05. Reflector Country
    log_info "Collecting reflector country..."
    echo ""
    sep_line
    echo ""
    while true; do
        msg_caution "Mandatory"
        echo "05. Reflector country name."
        printf "> "
        read -r COUNTRY
        
        if [ -n "$COUNTRY" ]; then
            break
        fi
        msg_warn "Error: This field is mandatory and cannot be empty. Try again!"
    done
    msg_success "Using: $COUNTRY"
    log_output "Country: $COUNTRY"
    
    # 06. Timezone
    log_info "Collecting timezone information..."
    echo ""
    sep_line
    echo ""
    
    AUTO_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null)
    OFFSET=$(date +%z)
    SIGN=${OFFSET:0:1}
    HH=${OFFSET:1:2}
    MM=${OFFSET:3:2}
    FRIENDLY_OFFSET="UTC${SIGN}${HH}:${MM}"
    
    msg_caution "Mandatory"
    if [[ -n "$AUTO_TZ" ]]; then
        echo "06. Local timezone. Detected: $AUTO_TZ ($FRIENDLY_OFFSET)"
        msg_note "Press ENTER to keep it or type another timezone."
    else
        echo "06. What is the local timezone? (e.g., America/Sao_Paulo, UTC, GMT-3)"
    fi
    
    while true; do
        printf "> "
        read -r USER_TZ
        
        # User pressed ENTER - keep detected timezone
        if [[ -z "$USER_TZ" && -n "$AUTO_TZ" ]]; then
            TIMEZONE="$AUTO_TZ"
            TIMEZONE_USE_SYSTEM=1
            
            ZONEFILE=$(readlink -f "/usr/share/zoneinfo/$TIMEZONE")
            REAL_OFFSET=$(TZ="$ZONEFILE" date +%z)
            
            SIGN=${REAL_OFFSET:0:1}
            HH=${REAL_OFFSET:1:2}
            MM=${REAL_OFFSET:3:2}
            
            if [[ "$REAL_OFFSET" == "+0000" ]]; then
                FINAL_DISPLAY="$TIMEZONE"
            else
                FINAL_DISPLAY="$TIMEZONE (UTC${SIGN}${HH}:${MM})"
            fi
            
            break
        fi
        
        # User entered a custom timezone
        TZ_RESOLVED=$(resolve_timezone "$USER_TZ")
        
        if [[ -z "$TZ_RESOLVED" ]]; then
            msg_warn "Invalid timezone. Please try again."
            continue
        fi
        
        TIMEZONE="$TZ_RESOLVED"
        TIMEZONE_USE_SYSTEM=0
        
        ZONEFILE=$(readlink -f "/usr/share/zoneinfo/$TIMEZONE")
        REAL_OFFSET=$(TZ="$ZONEFILE" date +%z)
        
        SIGN=${REAL_OFFSET:0:1}
        HH=${REAL_OFFSET:1:2}
        MM=${REAL_OFFSET:3:2}
        DISPLAY_OFFSET="UTC${SIGN}${HH}:${MM}"
        
        if [[ "$REAL_OFFSET" == "+0000" ]]; then
            FINAL_DISPLAY="$TIMEZONE"
        else
            FINAL_DISPLAY="$TIMEZONE ($DISPLAY_OFFSET)"
        fi
        
        msg_success "Selected timezone: $FINAL_DISPLAY"
        
        # Inverted GMT warning
        if [[ "$TIMEZONE" =~ ^Etc/GMT ]]; then
            msg_caution "IMPORTANT: Linux POSIX GMT zones use inverted sign notation."
            msg_caution "In your case, $TIMEZONE (inverted) corresponds to $DISPLAY_OFFSET (real)."
        fi
        
        echo "Confirm this timezone? (Y/N, ENTER = Y)"
        printf "> "
        read -r CONFIRM_TZ
        CONFIRM_TZ=$(echo "$CONFIRM_TZ" | tr '[:lower:]' '[:upper:]')
        
        if [[ -z "$CONFIRM_TZ" || "$CONFIRM_TZ" == "Y" ]]; then
            break
        fi
        
        msg_info "Please inform your timezone or press ENTER to accept detected."
    done
    
    msg_success "Using: $FINAL_DISPLAY"
    log_output "Timezone: $FINAL_DISPLAY"
    
    # 07. Comment for XLX list
    log_info "Collecting XLX list comment..."
    echo ""
    sep_line
    echo ""
    while true; do
        COMMENT_DEFAULT="$XRFNUM Multiprotocol Reflector by $CALLSIGN, info: $EMAIL"
        echo "07. Comment to XLX Reflectors list."
        msg_note "Suggested: \"$COMMENT_DEFAULT\" | [ENTER] to accept"
        printf "> "
        read -r COMMENT
        COMMENT=${COMMENT:-"$COMMENT_DEFAULT"}
        
        if [ ${#COMMENT} -le 100 ]; then
            break
        else
            msg_warn "Error: Comment must be max 100 characters. Please try again!"
        fi
    done
    msg_success "Using: $COMMENT"
    log_output "Comment: $COMMENT"
    
    # 08. Dashboard tab text
    log_info "Collecting dashboard tab text..."
    echo ""
    sep_line
    echo ""
    HEADER_DEFAULT="$XRFNUM by $CALLSIGN"
    echo "08. Custom text for the dashboard tab, preferably very short."
    msg_note "Suggested: \"$HEADER_DEFAULT\" | [ENTER] to accept"
    printf "> "
    read -r HEADER
    HEADER=${HEADER:-"$HEADER_DEFAULT"}
    msg_success "Using: $HEADER"
    log_output "Header: $HEADER"
    
    # 09. Dashboard footer
    log_info "Collecting dashboard footer text..."
    echo ""
    sep_line
    echo ""
    while true; do
        FOOTER_DEFAULT="Provided by $CALLSIGN, info: $EMAIL"
        echo "09. Custom text on footer of the dashboard webpage."
        msg_note "Suggested: \"$FOOTER_DEFAULT\" | [ENTER] to accept"
        printf "> "
        read -r FOOTER
        FOOTER=${FOOTER:-"$FOOTER_DEFAULT"}
        
        if [ ${#FOOTER} -le 100 ]; then
            break
        else
            msg_warn "Error: Footer must be max 100 characters. Please try again!"
        fi
    done
    msg_success "Using: $FOOTER"
    log_output "Footer: $FOOTER"
    
    # 10. SSL Certificate
    log_info "Collecting SSL preference..."
    echo ""
    sep_line
    echo ""
    while true; do
        echo "10. Create an SSL certificate (https) for the dashboard webpage? (Y/N)"
        msg_note "Suggested: Y | [ENTER] to accept"
        printf "> "
        read -r INSTALL_SSL
        INSTALL_SSL=$(echo "${INSTALL_SSL:-Y}" | tr '[:lower:]' '[:upper:]')
        
        if [[ "$INSTALL_SSL" == "Y" || "$INSTALL_SSL" == "N" ]]; then
            break
        else
            msg_warn "Please enter 'Y' or 'N'."
        fi
    done
    msg_success "Using: $INSTALL_SSL"
    log_output "SSL: $INSTALL_SSL"
    
    # 11. Echo Test
    log_info "Collecting Echo Test preference..."
    echo ""
    sep_line
    echo ""
    while true; do
        echo "11. Install Echo Test on module E? (Y/N)"
        msg_note "Suggested: Y | [ENTER] to accept"
        printf "> "
        read -r INSTALL_ECHO
        INSTALL_ECHO=$(echo "${INSTALL_ECHO:-Y}" | tr '[:lower:]' '[:upper:]')
        
        if [[ "$INSTALL_ECHO" == "Y" || "$INSTALL_ECHO" == "N" ]]; then
            break
        else
            msg_warn "Please enter 'Y' or 'N'."
        fi
    done
    msg_success "Using: $INSTALL_ECHO"
    log_output "Echo Test: $INSTALL_ECHO"
    
    # 12. Number of modules
    log_info "Collecting module count..."
    echo ""
    sep_line
    echo ""
    while true; do
        MIN_MODULES=1
        if [ "$INSTALL_ECHO" == "Y" ]; then
            MIN_MODULES=5
        fi
        echo "12. Number of active modules for the DStar Reflector. ($MIN_MODULES - 26)"
        msg_note "Suggested: 5 | [ENTER] to accept"
        printf "> "
        read -r MODQTD
        MODQTD=${MODQTD:-5}
        
        if [[ "$MODQTD" =~ ^[0-9]+$ ]] && [ "$MODQTD" -ge "$MIN_MODULES" ] && [ "$MODQTD" -le 26 ]; then
            break
        else
            msg_warn "Error: Must be a number between $MIN_MODULES and 26. Try again!"
        fi
    done
    msg_success "Using: $MODQTD"
    log_output "Modules: $MODQTD"
    
    # 13. YSF Port
    log_info "Collecting YSF port..."
    echo ""
    sep_line
    echo ""
    while true; do
        echo "13. YSF Reflector UDP port number. (1-65535)"
        msg_note "Suggested: 42000 | [ENTER] to accept"
        printf "> "
        read -r YSFPORT
        YSFPORT=${YSFPORT:-42000}
        
        if validate_port "$YSFPORT"; then
            break
        else
            msg_warn "Error: Must be a number between 1 and 65535. Try again!"
        fi
    done
    msg_success "Using: $YSFPORT"
    log_output "YSF Port: $YSFPORT"
    
    # 14. YSF Frequency
    log_info "Collecting YSF frequency..."
    echo ""
    sep_line
    echo ""
    while true; do
        echo "14. YSF Wires-X frequency. In Hertz, 9 digits."
        msg_note "Suggested: 433125000 | [ENTER] to accept"
        printf "> "
        read -r YSFFREQ
        YSFFREQ=${YSFFREQ:-433125000}
        
        if validate_frequency "$YSFFREQ"; then
            break
        else
            msg_warn "Error: Must be exactly 9 numeric digits (e.g., 433125000). Try again!"
        fi
    done
    msg_success "Using: $YSFFREQ"
    log_output "YSF Frequency: $YSFFREQ"
    
    # 15. YSF Auto-link
    log_info "Collecting YSF auto-link preference..."
    echo ""
    sep_line
    echo ""
    while true; do
        echo "15. Auto-link YSF to a module? (Y/N)"
        msg_note "Suggested: Y | [ENTER] to accept"
        printf "> "
        read -r AUTOLINK_USER
        AUTOLINK_USER=$(echo "${AUTOLINK_USER:-Y}" | tr '[:lower:]' '[:upper:]')
        
        if [[ "$AUTOLINK_USER" == "Y" || "$AUTOLINK_USER" == "N" ]]; then
            break
        else
            msg_warn "Please enter 'Y' or 'N'."
        fi
    done
    
    # Conversion (Y/N → 1/0)
    if [ "$AUTOLINK_USER" == "Y" ]; then
        AUTOLINK=1
    else
        AUTOLINK=0
    fi
    
    msg_success "Using: $AUTOLINK_USER"
    log_output "YSF Auto-link: $AUTOLINK_USER"
    
    # 16. Auto-link module (if enabled)
    if [[ "$AUTOLINK" -eq 1 ]]; then
        log_info "Collecting auto-link module..."
        echo ""
        sep_line
        echo ""
        
        # Determine available modules based on MODQTD
        # Create array of all letters A-Z
        ALL_LETTERS=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
        
        # Get the last letter based on MODQTD
        LAST_INDEX=$((MODQTD - 1))
        LAST_LETTER="${ALL_LETTERS[$LAST_INDEX]}"
        
        # Build array of valid modules
        VALID_MODULES=()
        for ((i=0; i<MODQTD; i++)); do
            VALID_MODULES+=("${ALL_LETTERS[$i]}")
        done
        
        # Build MODLIST string for configuration
        MODLIST=""
        for ((i=0; i<MODQTD; i++)); do
            MODLIST="${MODLIST}${ALL_LETTERS[$i]}"
        done
        
        # Determine smart suggestion
        if (( MODQTD >= 3 )); then
            SUGGESTED="C"
        elif (( MODQTD == 2 )); then
            SUGGESTED="B"
        else
            SUGGESTED="A"
        fi
        
        # Smart display of available modules
        if (( MODQTD <= 3 )); then
            echo "16. Module to Auto-link YSF. (One of ${VALID_MODULES[*]})"
        else
            echo "16. Module to Auto-link YSF. (Choose from A to $LAST_LETTER)"
        fi
        
        msg_note "Suggested: $SUGGESTED | [ENTER] to accept"
        printf "> "
        read -r MODAUTO
        
        # Apply default if empty
        MODAUTO=${MODAUTO:-$SUGGESTED}
        MODAUTO=$(echo "$MODAUTO" | tr '[:lower:]' '[:upper:]')
        
        # Validation: must be inside VALID_MODULES
        if [[ ! " ${VALID_MODULES[@]} " =~ " $MODAUTO " ]]; then
            if (( MODQTD <= 3 )); then
                msg_warn "Invalid module! Valid modules are: ${VALID_MODULES[*]}"
            else
                msg_warn "Invalid module! Valid modules from A to $LAST_LETTER"
            fi
            
            # Repeat until valid
            while true; do
                printf "> "
                read -r MODAUTO
                MODAUTO=${MODAUTO:-$SUGGESTED}
                MODAUTO=$(echo "$MODAUTO" | tr '[:lower:]' '[:upper:]')
                
                if [[ " ${VALID_MODULES[@]} " =~ " $MODAUTO " ]]; then
                    break
                fi
                
                msg_warn "Invalid entry. Choose from: ${VALID_MODULES[*]}"
            done
        fi
        
        msg_success "Using: $MODAUTO"
        log_output "Auto-link Module: $MODAUTO"
    fi
    
    echo ""
}

################################################################################
# CONFIGURATION REVIEW
################################################################################

review_configuration() {
    sep_line
    echo ""
    banner "PLEASE REVIEW YOUR SETTINGS"
    echo ""
    
    echo "01. Reflector ID:       $XRFNUM"
    echo "02. FQDN:               $XLXDOMAIN"
    echo "03. E-mail:             $EMAIL"
    echo "04. Callsign:           $CALLSIGN"
    echo "05. Country:            $COUNTRY"
    echo "06. Time Zone:          $TIMEZONE"
    echo "07. XLX list comment:   $COMMENT"
    echo "08. Tab page text:      $HEADER"
    echo "09. Dashboard footnote: $FOOTER"
    echo "10. SSL certification:  $INSTALL_SSL (Y/N)"
    echo "11. Echo Test:          $INSTALL_ECHO (Y/N)"
    echo "12. Modules:            $MODQTD"
    echo "13. YSF UDP Port:       $YSFPORT"
    echo "14. YSF frequency:      $YSFFREQ"
    echo "15. YSF Auto-link:      $AUTOLINK_USER (Y/N)"
    
    if [ "$AUTOLINK" -eq 1 ]; then
        echo "16. YSF module:         $MODAUTO"
    fi
    
    echo ""
    
    while true; do
        msg_info "Are these settings correct? (YES/NO)"
        printf "> "
        read -r CONFIRM
        
        CONFIRM=${CONFIRM:-YES}
        CONFIRM=$(echo "$CONFIRM" | tr '[:lower:]' '[:upper:]')
        
        if [[ "$CONFIRM" == "YES" || "$CONFIRM" == "NO" ]]; then
            break
        else
            msg_warn "Please enter 'YES' or 'NO'."
        fi
    done
    
    echo ""
    
    if [ "$CONFIRM" == "YES" ]; then
        log_success "Configuration verified by user, starting installation"
        msg_success "Information verified, installation starting!"
    else
        log_fatal "Installation aborted by user."
    fi
    
    echo ""
}

################################################################################
# SYSTEM UPDATE
################################################################################

update_system() {
    sep_line
    echo ""
    section "UPDATING OPERATING SYSTEM"
    echo ""
    
    log_info "Running system update..."
    log_command "apt update"
    
    if ! apt update; then
        log_fatal "Failed to update package lists. Check your internet connection or package manager configuration."
    fi
    
    log_command "apt full-upgrade -y"
    
    if ! apt full-upgrade -y; then
        log_fatal "Failed to upgrade system packages."
    fi
    
    # Apply timezone only if it's NOT the system timezone
    if [[ "$TIMEZONE_USE_SYSTEM" -eq 0 ]]; then
        log_info "Applying new timezone: $TIMEZONE"
        log_command "timedatectl set-timezone $TIMEZONE"
        timedatectl set-timezone "$TIMEZONE"
        msg_success "New timezone applied: $TIMEZONE"
    else
        log_info "Detected system timezone preserved: $TIMEZONE"
        msg_info "Detected system timezone preserved: $TIMEZONE"
    fi
    
    echo ""
    log_success "System updated successfully!"
    echo ""
}

################################################################################
# INSTALL DEPENDENCIES
################################################################################

install_dependencies() {
    sep_line
    echo ""
    section "INSTALLING DEPENDENCIES"
    echo ""
    
    log_info "Creating installation directory: $XLXINSTDIR"
    mkdir -p "$XLXINSTDIR"
    
    log_info "Installing required packages..."
    log_command "apt -y install $APPS"
    
    if ! apt -y install $APPS; then
        log_fatal "Failed to install dependencies."
    fi
    
    echo ""
    log_success "Dependencies installed successfully!"
    echo ""
}

################################################################################
# DOWNLOAD AND CONFIGURE XLX
################################################################################

download_xlx() {
    sep_line
    echo ""
    section "DOWNLOADING XLX APPLICATION"
    echo ""
    
    log_info "Changing to installation directory: $XLXINSTDIR"
    cd "$XLXINSTDIR" || log_fatal "Failed to change to $XLXINSTDIR"
    
    log_info "Cloning XLX repository from: $XLXDREPO"
    log_command "git clone $XLXDREPO"
    
    if ! git clone "$XLXDREPO"; then
        log_fatal "Failed to clone XLX repository"
    fi
    
    log_info "Changing to XLX source directory"
    cd "$XLXINSTDIR/xlxd/src" || log_fatal "Failed to change to xlxd/src"
    
    log_info "Cleaning previous builds..."
    log_command "make clean"
    make clean
    
    log_info "Applying customizations to main.h..."
    MAINCONFIG="$XLXINSTDIR/xlxd/src/main.h"
    
    log_command "sed -i 's|\\(NB_OF_MODULES\\s*\\)\\([0-9]*\\)|\\1$MODQTD|g' $MAINCONFIG"
    sed -i "s|\(NB_OF_MODULES\s*\)\([0-9]*\)|\1$MODQTD|g" "$MAINCONFIG"
    
    log_command "sed -i 's|\\(YSF_PORT\\s*\\)\\([0-9]*\\)|\\1$YSFPORT|g' $MAINCONFIG"
    sed -i "s|\(YSF_PORT\s*\)\([0-9]*\)|\1$YSFPORT|g" "$MAINCONFIG"
    
    log_command "sed -i 's|\\(YSF_DEFAULT_NODE_TX_FREQ\\s*\\)\\([0-9]*\\)|\\1$YSFFREQ|g' $MAINCONFIG"
    sed -i "s|\(YSF_DEFAULT_NODE_TX_FREQ\s*\)\([0-9]*\)|\1$YSFFREQ|g" "$MAINCONFIG"
    
    log_command "sed -i 's|\\(YSF_DEFAULT_NODE_RX_FREQ\\s*\\)\\([0-9]*\\)|\\1$YSFFREQ|g' $MAINCONFIG"
    sed -i "s|\(YSF_DEFAULT_NODE_RX_FREQ\s*\)\([0-9]*\)|\1$YSFFREQ|g" "$MAINCONFIG"
    
    log_command "sed -i 's|\\(YSF_AUTOLINK_ENABLE\\s*\\)\\([0-9]*\\)|\\1$AUTOLINK|g' $MAINCONFIG"
    sed -i "s|\(YSF_AUTOLINK_ENABLE\s*\)\([0-9]*\)|\1$AUTOLINK|g" "$MAINCONFIG"
    
    if [ "$AUTOLINK" -eq 1 ]; then
        log_command "sed -i 's|\\(YSF_AUTOLINK_MODULE\\s*\\)'\\([A-Z]*\\)'|\\1'$MODAUTO'|g' $MAINCONFIG"
        sed -i "s|\(YSF_AUTOLINK_MODULE\s*\)'\([A-Z]*\)'|\1'$MODAUTO'|g" "$MAINCONFIG"
    fi
    
    echo ""
    log_success "Repository cloned and customizations applied!"
    echo ""
}

################################################################################
# COMPILE XLX
################################################################################

compile_xlx() {
    sep_line
    echo ""
    section "COMPILING XLX"
    echo ""
    
    log_info "Starting compilation..."
    log_command "make"
    
    if ! make; then
        log_fatal "Compilation failed. Check the output for errors."
    fi
    
    log_info "Installing compiled binaries..."
    log_command "make install"
    
    if ! make install; then
        log_fatal "Installation of compiled binaries failed."
    fi
    
    # Verify compilation success
    if [ -e "$XLXINSTDIR/xlxd/src/xlxd" ]; then
        echo ""
        sep_block
        echo ""
        banner "COMPILATION SUCCESSFUL"
        echo ""
        sep_block
        echo ""
        log_success "XLX compiled successfully!"
    else
        echo ""
        sep_block
        echo ""
        msg_fatal "Compilation FAILED. Check the output for errors."
        sep_block
        echo ""
        log_fatal "XLX compilation failed"
    fi
}

################################################################################
# COPY COMPONENTS AND CONFIGURE
################################################################################

copy_components() {
    sep_line
    echo ""
    section "COPYING COMPONENTS"
    echo ""
    
    log_info "Creating XLX directory: $XLXDIR"
    mkdir -p "$XLXDIR"
    
    log_info "Creating web directory: $WEBDIR"
    mkdir -p "$WEBDIR"
    
    log_info "Creating XML log file"
    touch /var/log/xlxd.xml
    
    # Download DMR ID file
    log_info "Downloading DMR ID file from: $DMRIDURL"
    FILE_SIZE=$(wget --spider --server-response "$DMRIDURL" 2>&1 | grep -i Content-Length | awk '{print $2}')
    
    DMR_DOWNLOAD_SUCCESS=0
    if [ -z "$FILE_SIZE" ]; then
        log_info "Downloading DMR ID file (unknown size)..."
        if wget -q -O - "$DMRIDURL" | pv --force -p -t -r -b > /xlxd/dmrid.dat; then
            DMR_DOWNLOAD_SUCCESS=1
        fi
    else
        log_info "Downloading DMR ID file (size: $FILE_SIZE bytes)..."
        if wget -q -O - "$DMRIDURL" | pv --force -p -t -r -b -s "$FILE_SIZE" > /xlxd/dmrid.dat; then
            DMR_DOWNLOAD_SUCCESS=1
        fi
    fi
    
    if [ "$DMR_DOWNLOAD_SUCCESS" -eq 1 ] && [ -s /xlxd/dmrid.dat ]; then
        log_success "DMR ID file downloaded successfully"
    else
        log_error "Failed to download or empty DMR ID file."
    fi
    
    # Install XLX log components
    log_info "Installing custom XLX log components..."
    cp "$SCRIPT_DIR/templates/xlx_log.service" /etc/systemd/system/
    set_config_permissions "/etc/systemd/system/xlx_log.service"
    
    cp "$SCRIPT_DIR/templates/xlx_log.sh" /usr/local/bin/
    set_executable_permissions "/usr/local/bin/xlx_log.sh"
    
    cp "$SCRIPT_DIR/templates/xlx_logrotate.conf" /etc/logrotate.d/
    set_config_permissions "/etc/logrotate.d/xlx_logrotate.conf"
    
    log_success "XLX log components installed"
    
    # Configure XLXD terminal file
    log_info "Configuring XLXD terminal file..."
    TERMXLX="/xlxd/xlxd.terminal"
    
    # Build MODLIST string (A-Z based on MODQTD)
    ALL_LETTERS=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
    MODLIST=""
    for ((i=0; i<MODQTD; i++)); do
        MODLIST="${MODLIST}${ALL_LETTERS[$i]}"
    done
    
    log_command "sed -i 's|#address|address $PUBLIC_IP|g' $TERMXLX"
    sed -i "s|#address|address $PUBLIC_IP|g" "$TERMXLX"
    
    log_command "sed -i 's|#modules|modules $MODLIST|g' $TERMXLX"
    sed -i "s|#modules|modules $MODLIST|g" "$TERMXLX"
    
    log_success "XLXD terminal configured"
    
    # Install and configure XLXD service
    log_info "Installing XLXD service..."
    cp "$XLXINSTDIR/xlxd/scripts/xlxd.service" /etc/systemd/system/
    set_config_permissions "/etc/systemd/system/xlxd.service"
    
    log_command "sed -i 's|XLXXXX 172.23.127.100 127.0.0.1|$XRFNUM $LOCAL_IP 127.0.0.1|g' /etc/systemd/system/xlxd.service"
    sed -i "s|XLXXXX 172.23.127.100 127.0.0.1|$XRFNUM $LOCAL_IP 127.0.0.1|g" /etc/systemd/system/xlxd.service
    
    log_success "XLXD service installed"
    
    # Comment out ECHO line if Echo Test is not installed
    if [ "$INSTALL_ECHO" == "N" ]; then
        log_info "Disabling Echo Test in interlink file..."
        sed -i 's|^ECHO 127.0.0.1 E|#ECHO 127.0.0.1 E|' /xlxd/xlxd.interlink
        log_success "Echo Test disabled"
    fi
    
    # Configure daily user database update
    log_info "Configuring daily user database update..."
    if command -v crontab &>/dev/null; then
        log_info "Using crontab for daily updates"
        (crontab -l 2>/dev/null; echo "0 3 * * * wget -O /xlxd/users_db/user.csv https://radioid.net/static/user.csv && php /xlxd/users_db/create_user_db.php") | crontab -
        log_success "Crontab entry added"
    else
        log_info "crontab not found, using systemd timer"
        cp "$SCRIPT_DIR/templates/update_XLX_db.service" /etc/systemd/system/
        cp "$SCRIPT_DIR/templates/update_XLX_db.timer" /etc/systemd/system/
        
        set_config_permissions "/etc/systemd/system/update_XLX_db.service"
        set_config_permissions "/etc/systemd/system/update_XLX_db.timer"
        
        systemctl daemon-reload
        systemctl enable --now update_XLX_db.timer
        log_success "Systemd timer configured"
    fi
    
    echo ""
    log_success "Components copied and configured successfully!"
    echo ""
}

################################################################################
# INSTALL ECHO TEST SERVER
################################################################################

install_echo_test() {
    if [ "$INSTALL_ECHO" == "Y" ]; then
        sep_line
        echo ""
        section "INSTALLING ECHO TEST SERVER"
        echo ""
        
        log_info "Changing to installation directory: $XLXINSTDIR"
        cd "$XLXINSTDIR" || log_fatal "Failed to change to $XLXINSTDIR"
        
        log_info "Cloning Echo Test repository from: $XLXECHO"
        log_command "git clone $XLXECHO"
        
        if ! git clone "$XLXECHO"; then
            log_fatal "Failed to clone Echo Test repository"
        fi
        
        log_info "Compiling Echo Test..."
        cd XLXEcho/ || log_fatal "Failed to change to XLXEcho directory"
        
        log_command "gcc -o xlxecho xlxecho.c"
        if ! gcc -o xlxecho xlxecho.c; then
            log_fatal "Failed to compile Echo Test"
        fi
        
        log_info "Installing Echo Test binary..."
        cp xlxecho /xlxd/
        set_executable_permissions "/xlxd/xlxecho"
        
        log_info "Installing Echo Test service..."
        cp "$XLXINSTDIR/xlxd/scripts/xlxecho.service" /etc/systemd/system/
        set_config_permissions "/etc/systemd/system/xlxecho.service"
        
        echo ""
        log_success "Echo Test server successfully installed!"
        echo ""
    fi
}

################################################################################
# INSTALL DASHBOARD
################################################################################

install_dashboard() {
    sep_line
    echo ""
    section "INSTALLING DASHBOARD"
    echo ""
    
    log_info "Changing to installation directory: $XLXINSTDIR"
    cd "$XLXINSTDIR" || log_fatal "Failed to change to $XLXINSTDIR"
    
    log_info "Cloning Dashboard repository from: $XLXDASH"
    log_command "git clone $XLXDASH"
    
    if ! git clone "$XLXDASH"; then
        log_fatal "Failed to clone Dashboard repository"
    fi
    
    log_info "Copying dashboard files to web directory..."
    cp -R "$XLXINSTDIR/XLX_Dark_Dashboard/"* "$WEBDIR/"
    
    log_info "Applying dashboard customizations..."
    XLXCONFIG="$WEBDIR/pgs/config.inc.php"
    
    log_command "sed -i 's|your_email|$EMAIL|g' $XLXCONFIG"
    sed -i "s|your_email|$EMAIL|g" "$XLXCONFIG"
    
    log_command "sed -i 's|LX1IQ|$CALLSIGN|g' $XLXCONFIG"
    sed -i "s|LX1IQ|$CALLSIGN|g" "$XLXCONFIG"
    
    log_command "sed -i 's|MODQTD|$MODQTD|g' $XLXCONFIG"
    sed -i "s|MODQTD|$MODQTD|g" "$XLXCONFIG"
    
    log_command "sed -i 's|custom_header|$HEADER|g' $XLXCONFIG"
    sed -i "s|custom_header|$HEADER|g" "$XLXCONFIG"
    
    log_command "sed -i 's|custom_footnote|$FOOTER|g' $XLXCONFIG"
    sed -i "s|custom_footnote|$FOOTER|g" "$XLXCONFIG"
    
    log_command "sed -i 's#http://your_dashboard#http://$XLXDOMAIN#g' $XLXCONFIG"
    sed -i "s#http://your_dashboard#http://$XLXDOMAIN#g" "$XLXCONFIG"
    
    log_command "sed -i 's|your_country|$COUNTRY|g' $XLXCONFIG"
    sed -i "s|your_country|$COUNTRY|g" "$XLXCONFIG"
    
    log_command "sed -i 's|your_comment|$COMMENT|g' $XLXCONFIG"
    sed -i "s|your_comment|$COMMENT|g" "$XLXCONFIG"
    
    log_command "sed -i 's|netact|$NETACT|g' $XLXCONFIG"
    sed -i "s|netact|$NETACT|g" "$XLXCONFIG"
    
    log_success "Dashboard customizations applied"
    
    # Configure Apache
    log_info "Configuring Apache..."
    cp "$SCRIPT_DIR/templates/apache.tbd.conf" /etc/apache2/sites-available/"$XLXDOMAIN".conf
    
    log_command "sed -i 's|apache.tbd|$XLXDOMAIN|g' /etc/apache2/sites-available/$XLXDOMAIN.conf"
    sed -i "s|apache.tbd|$XLXDOMAIN|g" /etc/apache2/sites-available/"$XLXDOMAIN".conf
    
    log_command "sed -i 's#ysf-xlxd#html/xlxd#g' /etc/apache2/sites-available/$XLXDOMAIN.conf"
    sed -i "s#ysf-xlxd#html/xlxd#g" /etc/apache2/sites-available/"$XLXDOMAIN".conf
    
    log_success "Apache configuration completed"
    
    # Configure PHP timezone
    log_info "Configuring PHP timezone..."
    if [ -n "$PHPVER" ]; then
        log_command "sed -i 's|^;\\?date\\.timezone\\s*=.*|date.timezone = \"$TIMEZONE\"|' /etc/php/$PHPVER/apache2/php.ini"
        sed -i "s|^;\?date\.timezone\s*=.*|date.timezone = \"$TIMEZONE\"|" /etc/php/"$PHPVER"/apache2/php.ini
        log_success "PHP timezone configured"
    else
        log_warn "PHP version not detected, skipping timezone configuration"
    fi
    
    # Detect Apache user
    log_info "Detecting Apache user..."
    APACHE_USER=$(ps aux | grep -E '[a]pache|[h]ttpd' | grep -v root | head -1 | awk '{print $1}')
    if [ -z "$APACHE_USER" ]; then
        APACHE_USER="www-data"
        log_warn "Apache user not detected, using default: www-data"
    else
        log_success "Apache user detected: $APACHE_USER"
    fi
    
    # Move users_db
    log_info "Moving users database directory..."
    mv "$WEBDIR/users_db/" /xlxd/
    
    # Set permissions with optimization
    log_info "Setting dashboard permissions..."
    chown -R "$APACHE_USER:$APACHE_USER" /var/log/xlxd.xml
    chown -R "$APACHE_USER:$APACHE_USER" "$WEBDIR/"
    chown -R "$APACHE_USER:$APACHE_USER" /xlxd/
    
    # Set directory permissions (755)
    find /xlxd -type d -exec chmod 755 {} \;
    find "$WEBDIR" -type d -exec chmod 755 {} \;
    
    # Set file permissions based on type
    # Executable scripts (755)
    find /xlxd -type f -name "*.sh" -exec chmod 755 {} \;
    find "$WEBDIR" -type f -name "*.sh" -exec chmod 755 {} \;
    
    # Executable binaries (755)
    find /xlxd -type f -executable -exec chmod 755 {} \;
    
    # Configuration and data files (644)
    find /xlxd -type f ! -name "*.sh" ! -executable -exec chmod 644 {} \;
    find "$WEBDIR" -type f ! -name "*.sh" -exec chmod 644 {} \;
    
    # PHP files should be readable by Apache (644)
    find "$WEBDIR" -type f -name "*.php" -exec chmod 644 {} \;
    
    log_success "Permissions set successfully"
    
    # Initialize user database
    log_info "Initializing user database..."
    /bin/bash /xlxd/users_db/update_db.sh
    
    # Enable Apache site
    log_info "Enabling Apache site..."
    /usr/sbin/a2ensite "$XLXDOMAIN".conf 2>/dev/null | head -n1
    /usr/sbin/a2dissite 000-default 2>/dev/null | head -n1
    
    # Restart Apache
    log_info "Restarting Apache..."
    systemctl stop apache2 >/dev/null 2>&1
    systemctl start apache2 >/dev/null 2>&1
    systemctl daemon-reload
    
    echo ""
    log_success "Dashboard successfully installed!"
    echo ""
}

################################################################################
# INSTALL SSL CERTIFICATE
################################################################################

install_ssl() {
    if [ "$INSTALL_SSL" == "Y" ]; then
        sep_line
        echo ""
        section "CONFIGURING SSL CERTIFICATE"
        echo ""
        
        log_info "Running certbot for domain: $XLXDOMAIN"
        log_command "certbot --apache -d $XLXDOMAIN -n --agree-tos -m $EMAIL"
        
        if certbot --apache -d "$XLXDOMAIN" -n --agree-tos -m "$EMAIL"; then
            log_success "SSL certificate installed successfully!"
        else
            log_error "SSL certificate installation failed. You may need to configure it manually."
        fi
        
        echo ""
    fi
}

################################################################################
# START SERVICES
################################################################################

start_services() {
    sep_line
    echo ""
    section "STARTING $XRFNUM REFLECTOR"
    echo ""
    
    # Start XLXD service
    log_info "Enabling and starting XLXD service..."
    if systemctl enable --now xlxd.service >/dev/null 2>&1; then
        # Wait a moment and verify service status
        sleep 3
        if systemctl is-active --quiet xlxd.service; then
            log_success "XLXD service started successfully"
        else
            log_warn "XLXD service may not have started correctly. Check status with: systemctl status xlxd.service"
        fi
    else
        log_error "Failed to enable/start XLXD service"
    fi
    echo ""
    
    # Start XLX log service
    log_info "Enabling and starting XLX log service..."
    if systemctl enable --now xlx_log.service >/dev/null 2>&1; then
        sleep 2
        if systemctl is-active --quiet xlx_log.service; then
            log_success "XLX log service started successfully"
        else
            log_warn "XLX log service may not have started correctly. Check status with: systemctl status xlx_log.service"
        fi
    else
        log_error "Failed to enable/start XLX log service"
    fi
    echo ""
    
    # Start Echo Test service (if installed)
    if [ "$INSTALL_ECHO" == "Y" ]; then
        log_info "Enabling and starting Echo Test service..."
        if systemctl enable --now xlxecho.service >/dev/null 2>&1; then
            sleep 2
            if systemctl is-active --quiet xlxecho.service; then
                log_success "Echo Test service started successfully"
            else
                log_warn "Echo Test service may not have started correctly. Check status with: systemctl status xlxecho.service"
            fi
        else
            log_error "Failed to enable/start Echo Test service"
        fi
        echo ""
    fi
    
    echo ""
    log_success "All services initialized!"
    echo ""
}

################################################################################
# FINAL MESSAGE
################################################################################

show_completion_message() {
    sep_block
    echo ""
    banner "REFLECTOR INSTALLED SUCCESSFULLY"
    echo ""
    sep_block
    echo ""
    
    msg_success "Your Reflector $XRFNUM is now installed and running!"
    echo ""
    
    msg_info "For Public Reflectors:"
    echo ""
    
    echo "• If your XLX number is available, it's expected to be listed on the public"
    echo "  list shortly, typically within an hour. If you don't want the reflector to"
    echo "  be published, just set callinghome to [false] in the config file."
    echo ""
    echo "• Many other settings can be changed in the configuration file at:"
    echo "  $WEBDIR/pgs/config.inc.php"
    echo ""
    echo "• More information about XLX Reflectors: $INFREF"
    echo ""
    
    if [ "$INSTALL_SSL" == "Y" ]; then
        msg_success "Your $XRFNUM dashboard should now be accessible at: https://$XLXDOMAIN"
    else
        msg_success "Your $XRFNUM dashboard should now be accessible at: http://$XLXDOMAIN"
    fi
    
    echo ""
    sep_block
    echo ""
    
    log_info "Installation completed successfully!"
    log_info "Dashboard URL: http://$XLXDOMAIN"
    log_info "Log file location: $LOGFILE"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    log_info "=== XLX Installation Started ==="
    log_info "Log file: $LOGFILE"
    
    # Initial checks
    check_root "$@"
    check_internet
    check_distro
    check_existing_install
    
    # Collect user input
    collect_user_input
    
    # Review and confirm
    review_configuration
    
    # Installation steps
    update_system
    install_dependencies
    download_xlx
    compile_xlx
    copy_components
    install_echo_test
    install_dashboard
    install_ssl
    start_services
    
    # Show completion message
    show_completion_message
    
    log_info "=== XLX Installation Completed Successfully ==="
}

# Run main function
main "$@"
