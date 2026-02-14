#!/bin/bash
# A tool to install XLXD, your own D-Star Reflector.
# For more information, please visit https://xlxbbs.epf.lu/
# Customized by Daniel K., PU5KOD
# Lets begin!!!

# Redirect all output to the log and keep it in the terminal
LOGFILE="$PWD/log/log_xlx_install_$(date +%F_%H-%M-%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

#  INITIAL CHECKS
# 1. root user check with automatic relaunch.
if [ "$(id -u)" -ne 0 ]; then
    echo "This script is not being run as root."
    read -r -p "Do you want to relaunch with sudo? (y/n)" answer

    case "$answer" in
        y|Y|yes|YES)
            echo "Relaunching with sudo..."
            exec sudo "$0" "$@"
            ;;
        *)
            echo "Operation cancelled."
            exit 1
            ;;
    esac
fi

# 2. Internet check.
if ! ping -c 1 google.com &>/dev/null; then
    echo "Unable to proceed, no internet connection detected. Please check your network."
    exit 1
fi

# 3. Distro check.
if [ ! -e "/etc/debian_version" ]; then
    echo "This script has only been tested on Debian-based distributions."
    read -p "Do you want to continue anyway? (Y/N) " answer
    [[ "$answer" =~ ^[yY](es)?$ ]] || { echo "Execution cancelled."; exit 1; }
fi

# 4. Set the fixed character limit
MAX_WIDTH=100
cols=$(tput cols 2>/dev/null || echo "$MAX_WIDTH")
width=$(( cols < MAX_WIDTH ? cols : MAX_WIDTH ))

# 5. Function to create different types of lines adjusted to length
line_type1() {
    printf "%${width}s\n" | tr ' ' '_'
}
line_type2() {
    printf "%${width}s\n" | tr ' ' '='
}
line_type3() {
    printf "%${width}s\n" | tr ' ' ':'
}

# 6. Function to display text with adjusted line breaks
print_wrapped() {
    echo "$1" | fold -s -w "$width"
}
SEPQUE="_-_-_-_-_-_-_-_-_-_-_"
# 7. Parameter definition
DIRDIR=$(pwd)
LOCAL_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl v4.ident.me)
NETACT=$(ip -o addr show up | awk '{print $2}' | grep -v lo | head -n1)
INFREF="https://xlxbbs.epf.lu/"
PHPVER=$(php -v | head -n1 | awk '{print $2}' | cut -d. -f1,2)
XLXDREPO="https://github.com/PU5KOD/xlxd.git"
XLXECHO="https://github.com/PU5KOD/XLXEcho.git"
XLXDASH="https://github.com/PU5KOD/XLX_Dark_Dashboard.git"
DMRIDURL="http://xlxapi.rlx.lu/api/exportdmr.php"
WEBDIR="/var/www/html/xlxd"
XLXINSTDIR="/usr/src"
XLXDIR="/xlxd"
ACCEPT="| [ENTER] to accept..."
APPS="git git-core make gcc g++ pv sqlite3 apache2 php libapache2-mod-php php-cli php-xml php-mbstring php-curl php-sqlite3 build-essential vnstat certbot python3-certbot-apache"

# 8. Color palette
# msg_info - BLUE 38;5;39 - Information
# msg_success - GREEN 38;5;46 - Success
# msg_warn - YELLOW 38;5;226 - Warning
# msg_caution - ORANGE 38;5;208 - Caution
# msg_error - RED_BRIGHT 38;5;196 - Error
# msg_note - GRAY_250 38;5;250 - Technical note
# msg_fatal - RED_DARK 38;5;124 - Fatal message!!!

NC='\033[0m'
BLUE='\033[38;5;39m'
BLUE_BRIGHT='\033[1;34m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
ORANGE='\033[38;5;208m'
RED='\033[38;5;196m'
RED_DARK='\033[38;5;124m'
GRAY='\033[38;5;250m'

# 9. Unicode icons
ICON_OK="✔"
ICON_ERR="✖"
ICON_WARN="⚠"
ICON_INFO="ℹ"
ICON_FATAL="‼"
ICON_NOTE="🛈"
ICON_ROCKET="🚀"
ICON_GEAR="⚙"
ICON_DOWNLOAD="⬇"
ICON_COMPILE="🔨"
ICON_SSL="🔒"

# 10. Functions to display text with adjusted line breaks and colors
print_blue() { echo -e "${BLUE}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_blueb() { echo -e "${BLUE_BRIGHT}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_green() { echo -e "${GREEN}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_yellow() { echo -e "${YELLOW}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_orange() { echo -e "${ORANGE}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_red() { echo -e "${RED}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_redd() { echo -e "${RED_DARK}$(echo "$1" | fold -s -w "$width")${NC}"; }
print_gray() { echo -e "${GRAY}$(echo "$1" | fold -s -w "$width")${NC}"; }
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

# 11. Check for existing installs
if [ -e "$XLXDIR/xlxd" ]; then
    echo ""
    line_type2
    echo ""
    center_wrap_color $RED "XLXD ALREADY INSTALLED!!! Run the 'uninstaller.sh'."
    echo ""
    line_type2
    echo ""
    exit 1
else

# 12. Start of data collection.
clear
line_type3
echo ""
center_wrap_color $GREEN "XLX MULTIPROTOCOL AMATEUR RADIO REFLECTOR INSTALLER PROGRAM"
echo ""
center_wrap_color $GREEN "Next, you will be asked some questions. Answer with the requested information or, if applicable, to accept the suggested value, press [ENTER]"
echo ""
line_type3
echo ""
center_wrap_color $BLUE_BRIGHT "REFLECTOR DATA INPUT"
center_wrap_color $BLUE "===================="
echo ""

# Teste de impresao de cores, descomente e execute para verificar
#print_blue "Azul ==============="
#print_blueb "Azul Brilhante ===="
#print_green "Verde ============="
#print_yellow "Amarelo =========="
#print_orange "Laranja =========="
#print_red "Vermelho ============"
#print_redd "Vermelho Dask ======"
#print_gray "Cinza =============="
echo ""

while true; do
    print_red "Mandatory"
    print_wrapped "01. XLX Reflector ID, 3 alphanumeric characters. (e.g., 300, US1, BRA)"
    printf "> "
    read -r XRFDIGIT
    XRFDIGIT=$(echo "$XRFDIGIT" | tr '[:lower:]' '[:upper:]')
    if [[ "$XRFDIGIT" =~ ^[A-Z0-9]{3}$ ]]; then
        break
    fi
    print_orange "Invalid ID. Must be exactly 3 characters (A–Z and/or 0–9). Try again!"
done

XRFNUM="XLX$XRFDIGIT"
print_yellow "Using: $XRFNUM"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "02. Dashboard FQDN (fully qualified domain name), (e.g., xlxbra.net)"
    printf "> "
    read -r XLXDOMAIN
    XLXDOMAIN=$(echo "$XLXDOMAIN" | tr '[:upper:]' '[:lower:]')
    if [[ "$XLXDOMAIN" =~ ^([a-z0-9-]+\.)+[a-z]{2,}$ ]]; then
        break
    fi
        print_orange "Invalid domain. Must be a valid FQDN (e.g., xlx.example.com)."
done
print_yellow "Using: $XLXDOMAIN"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "03. Sysop e-mail address"
    printf "> "
    read -r EMAIL
    EMAIL=$(echo "$EMAIL" | tr '[:upper:]' '[:lower:]')
    if [[ "$EMAIL" =~ ^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$ ]]; then
        break
    fi
    print_orange "Invalid email format. (e.g., user@doamain.com)."
done
print_yellow "Using: $EMAIL"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "04. Sysop callsign. Only letters and numbers allowed, max 8 characters."
    printf "> "
    read -r CALLSIGN
    CALLSIGN=$(echo "$CALLSIGN" | tr '[:lower:]' '[:upper:]')
    if [[ "$CALLSIGN" =~ ^[A-Z0-9]{3,8}$ ]]; then
        break
    fi
    print_orange "Invalid callsign. Use only letters and numbers, 3 - 8 characters."
done
print_yellow "Using: $CALLSIGN"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "05. Reflector country name."
    printf "> "
    read -r COUNTRY
    if [ -z "$COUNTRY" ]; then
        print_orange "Error: This field is mandatory and cannot be empty. Try again!"
    else
        break
    fi
done
print_yellow "Using: $COUNTRY"


echo ""
echo "$SEPQUE"
# Resolve timezone from user input, checking only real system timezones
resolve_timezone() {
    local input="$1"
    local input_upper input_lower match

    input_upper=$(echo "$input" | tr '[:lower:]' '[:upper:]')
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    # 1) Case-insensitive match against the official system list
    match=$(timedatectl list-timezones | grep -iFx "$input" 2>/dev/null || true)
    [[ -n "$match" ]] && { echo "$match"; return 0; }

    match=$(timedatectl list-timezones | grep -iFx "$input_upper" 2>/dev/null || true)
    [[ -n "$match" ]] && { echo "$match"; return 0; }

    match=$(timedatectl list-timezones | grep -iFx "$input_lower" 2>/dev/null || true)
    [[ -n "$match" ]] && { echo "$match"; return 0; }

    # 2) GMT±X – validate only if it exists in tzdata
    if [[ "$input_upper" =~ ^GMT([+-]?)([0-9]{1,2})$ ]]; then
        local sign="${BASH_REMATCH[1]}"
        local num="${BASH_REMATCH[2]}"
        local candidate

        # POSIX inverted GMT logic — do NOT modify
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

# Detect current server timezone
AUTO_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null)

OFFSET=$(date +%z)
SIGN=${OFFSET:0:1}
HH=${OFFSET:1:2}
MM=${OFFSET:3:2}
FRIENDLY_OFFSET="UTC${SIGN}${HH}:${MM}"
    echo ""
    print_red "Mandatory"
if [[ -n "$AUTO_TZ" ]]; then
    print_wrapped "06. Local timezone. Detected: $AUTO_TZ ($FRIENDLY_OFFSET)"
    print_gray "Press ENTER to keep it or type another timezone."
else
    print_wrapped "06. What is the local timezone? (e.g., America/Sao_Paulo, UTC, GMT-3)"
fi

# Interactive timezone selection
while true; do
    printf "> "
    read -r USER_TZ

    # CASE 1 — USER PRESSED ENTER (KEEP DETECTED TIMEZONE)
    if [[ -z "$USER_TZ" && -n "$AUTO_TZ" ]]; then
        TIMEZONE="$AUTO_TZ"
        TIMEZONE_USE_SYSTEM=1

        # Resolve tzdata link
        ZONEFILE=$(readlink -f "/usr/share/zoneinfo/$TIMEZONE")
        REAL_OFFSET=$(TZ="$ZONEFILE" date +%z)

        # Prepare display offset
        SIGN=${REAL_OFFSET:0:1}
        HH=${REAL_OFFSET:1:2}
        MM=${REAL_OFFSET:3:2}

        # If UTC+00:00 → hide offset
        if [[ "$REAL_OFFSET" == "+0000" ]]; then
            FINAL_DISPLAY="$TIMEZONE"
        else
            FINAL_DISPLAY="$TIMEZONE (UTC${SIGN}${HH}:${MM})"
        fi

        # No confirmation needed
        break
    fi

    # CASE 2 — USER ENTERED A CUSTOM TIMEZONE
    TZ_RESOLVED=$(resolve_timezone "$USER_TZ")

    if [[ -z "$TZ_RESOLVED" ]]; then
        print_orange "Invalid timezone. Please try again."
        continue
    fi

    TIMEZONE="$TZ_RESOLVED"
    TIMEZONE_USE_SYSTEM=0

    # Resolve tzdata link
    ZONEFILE=$(readlink -f "/usr/share/zoneinfo/$TIMEZONE")
    REAL_OFFSET=$(TZ="$ZONEFILE" date +%z)

    # Prepare offset
    SIGN=${REAL_OFFSET:0:1}
    HH=${REAL_OFFSET:1:2}
    MM=${REAL_OFFSET:3:2}
    DISPLAY_OFFSET="UTC${SIGN}${HH}:${MM}"

    # If UTC+00:00 → hide offset
    if [[ "$REAL_OFFSET" == "+0000" ]]; then
        FINAL_DISPLAY="$TIMEZONE"
    else
        FINAL_DISPLAY="$TIMEZONE ($DISPLAY_OFFSET)"
    fi

    # Confirmation prompt (ONLY for custom TZ)
    print_yellow "Selected timezone: $FINAL_DISPLAY"

    # Inverted GMT warning
    if [[ "$TIMEZONE" =~ ^Etc/GMT ]]; then
        print_orange "IMPORTANT: Linux POSIX GMT zones use inverted sign notation."
        print_orange "In your case, $TIMEZONE (inverted) corresponds to $DISPLAY_OFFSET (real)."
    fi

    print_yellow "Confirm this timezone? (Y/N, ENTER = Y)"
    printf "> "
    read -r CONFIRM_TZ
    CONFIRM_TZ=$(echo "$CONFIRM_TZ" | tr '[:lower:]' '[:upper:]')

    # Default = Y
    if [[ -z "$CONFIRM_TZ" || "$CONFIRM_TZ" == "Y" ]]; then
        break
    fi

    print_yellow "Please inform your timezone or press ENTER to accept detected."
done

# Final output
print_yellow "Using: $FINAL_DISPLAY"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    COMMENT_DEFAULT="$XRFNUM Multiprotocol Reflector by $CALLSIGN, info: $EMAIL"
    print_wrapped "07. Comment to XLX Reflectors list."
    print_gray "Suggested: \"$COMMENT_DEFAULT\" $ACCEPT"
    printf "> "
    read -r COMMENT
    COMMENT=${COMMENT:-"$COMMENT_DEFAULT"}
    if [ ${#COMMENT} -le 100 ]; then
        break
    else
        print_orange "Error: Comment must be max 100 characters. Please try again!"
    fi
done
print_yellow "Using: $COMMENT"

echo ""
echo "$SEPQUE"
echo ""
    HEADER_DEFAULT="$XRFNUM by $CALLSIGN"
    print_wrapped "08. Custom text for the dashboard tab, preferably very short."
    print_gray "Suggested: \"$HEADER_DEFAULT\" $ACCEPT"
    printf "> "
    read -r HEADER
    HEADER=${HEADER:-"$HEADER_DEFAULT"}
print_yellow "Using: $HEADER"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    FOOTER_DEFAULT="Provided by $CALLSIGN, info: $EMAIL"
    print_wrapped "09. Custom text on footer of the dashboard webpage."
    print_gray "Suggested: \"$FOOTER_DEFAULT\" $ACCEPT"
    printf "> "
    read -r FOOTER
    FOOTER=${FOOTER:-"$FOOTER_DEFAULT"}
    if [ ${#FOOTER} -le 100 ]; then
        break
    else
        print_orange "Error: Comment must be max 100 characters. Please try again!"
    fi
done
print_yellow "Using: $FOOTER"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "10. Create an SSL certificate (https) for the dashboard webpage? (Y/N)"
    print_gray "Suggested: Y $ACCEPT"
    printf "> "
    read -r INSTALL_SSL
    INSTALL_SSL=$(echo "${INSTALL_SSL:-Y}" | tr '[:lower:]' '[:upper:]')
    if [[ "$INSTALL_SSL" == "Y" || "$INSTALL_SSL" == "N" ]]; then
        break
    else
        print_orange "Please enter 'Y' or 'N'."
    fi
done

print_yellow "Using: $INSTALL_SSL"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "11. Install Echo Test on module E? (Y/N)"
    print_gray "Suggested: Y $ACCEPT"
    printf "> "
    read -r INSTALL_ECHO
    INSTALL_ECHO=$(echo "${INSTALL_ECHO:-Y}" | tr '[:lower:]' '[:upper:]')
    if [[ "$INSTALL_ECHO" == "Y" || "$INSTALL_ECHO" == "N" ]]; then
        break
    else
        print_orange "Please enter 'Y' or 'N'."
    fi
done
print_yellow "Using: $INSTALL_ECHO"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    MIN_MODULES=1
    if [ "$INSTALL_ECHO" == "Y" ]; then
        MIN_MODULES=5
    fi
    print_wrapped "12. Number of active modules for the DStar Reflector. ($MIN_MODULES - 26)"
    print_gray "Suggested: 5 $ACCEPT"
    printf "> "
    read -r MODQTD
    MODQTD=${MODQTD:-5}
    if [[ "$MODQTD" =~ ^[0-9]+$ && "$MODQTD" -ge "$MIN_MODULES" && "$MODQTD" -le 26 ]]; then
        break
    else
        print_orange "Error: Must be a number between $MIN_MODULES and 26. Try again!"
    fi
done
print_yellow "Using: $MODQTD"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "13. YSF Reflector UDP port number. (1-65535)"
    print_gray "Suggested: 42000 $ACCEPT"
    printf "> "
    read -r YSFPORT
    YSFPORT=${YSFPORT:-42000}
    if [[ "$YSFPORT" =~ ^[0-9]+$ && "$YSFPORT" -ge 1 && "$YSFPORT" -le 65535 ]]; then
        break
    else
        print_orange "Error: Must be a number between 1 and 65535. Try again!"
    fi
done
print_yellow "Using: $YSFPORT"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "14. YSF Wires-X frequency. In Hertz, 9 digits."
    print_gray "Suggested: 433125000 $ACCEPT"
    printf "> "
    read -r YSFFREQ
    YSFFREQ=${YSFFREQ:-433125000}
    if [[ "$YSFFREQ" =~ ^[0-9]{9}$ ]]; then
        break
    else
        print_orange "Error: Must be exactly 9 numeric digits (e.g., 433125000). Try again!"
    fi
done
print_yellow "Using: $YSFFREQ"


while true; do
echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "15. Auto-link YSF to a module? (Y/N)"
    print_gray "Suggested: Y $ACCEPT"
    printf "> "
    read -r AUTOLINK_USER
    AUTOLINK_USER=$(echo "${AUTOLINK_USER:-Y}" | tr '[:lower:]' '[:upper:]')

    if [[ "$AUTOLINK_USER" == "Y" || "$AUTOLINK_USER" == "N" ]]; then
        break
    else
        print_orange "Please enter 'Y' or 'N'."
    fi
done

# Conversion (Y/N → 1/0)
if [ "$AUTOLINK_USER" == "Y" ]; then
    AUTOLINK=1
else
    AUTOLINK=0
fi

print_yellow "Using: $AUTOLINK_USER"


echo ""
echo "$SEPQUE"
echo ""
if [[ "$AUTOLINK" -eq 1 ]]; then

    # Determine available modules based on MODQTD
    LAST_INDEX=$((MODQTD - 1))
    LAST_LETTER=$(printf "\\$(printf '%03o' $((65 + LAST_INDEX)))")

    # Build array of valid modules
    VALID_MODULES=()
    for ((i=0; i<MODQTD; i++)); do
        VALID_MODULES+=("$(printf "\\$(printf '%03o' $((65 + i)))")")
    done
    MODLIST=$(echo {A..Z} | tr -d ' ' | head -c "$MODQTD")

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
        # Full listing, since it's short
        print_wrapped "16. Module to Auto-link YSF. (One of ${VALID_MODULES[*]})"
    else
        # Smart compact range
        print_wrapped "16. Module to Auto-link YSF. (Choose from A to $LAST_LETTER)"
    fi

    print_gray "Suggested: $SUGGESTED $ACCEPT"
    printf "> "
    read -r MODAUTO

    # Apply default if empty
    MODAUTO=${MODAUTO:-$SUGGESTED}
    MODAUTO=$(echo "$MODAUTO" | tr '[:lower:]' '[:upper:]')

    # Validation: must be inside VALID_MODULES
    if [[ ! " ${VALID_MODULES[@]} " =~ " $MODAUTO " ]]; then
    # Smart display of available modules
        if (( MODQTD <= 3 )); then
        # Full listing, since it's short
        print_wrapped "Invalid module! Valid modules are: ${VALID_MODULES[*]}"
        else
        # Smart compact range
        print_wrapped "Invalid module! Valid modules from A to $LAST_LETTER"
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

            print_orange "Invalid entry. Choose from: ${VALID_MODULES[*]}"
        done
    fi

    print_yellow "Using: $MODAUTO"
fi
echo ""

# Data verification
line_type1
echo ""
center_wrap_color $ORANGE "PLEASE REVIEW YOUR SETTINGS:"
center_wrap_color $YELLOW "============================"
echo ""
print_wrapped "01. Reflector ID:	$XRFNUM"
print_wrapped "02. FQDN:		$XLXDOMAIN"
print_wrapped "03. E-mail:		$EMAIL"
print_wrapped "04. Callsign:		$CALLSIGN"
print_wrapped "05. Country:		$COUNTRY"
print_wrapped "06. Time Zome:		$TIMEZONE"
print_wrapped "07. XLX list comment:	$COMMENT"
print_wrapped "08. Tab page text:	$HEADER"
print_wrapped "09. Dashboard footnote:	$FOOTER"
print_wrapped "10. SSL certification:	$INSTALL_SSL (Y/N)"
print_wrapped "11. Echo Test:		$INSTALL_ECHO (Y/N)"
print_wrapped "12. Modules:		$MODQTD"
print_wrapped "13. YSF UDP Port:	$YSFPORT"
print_wrapped "14. YSF frequency:	$YSFFREQ"
print_wrapped "15. YSF Auto-link:	$AUTOLINK_USER (Y/N)"
if [ "$AUTOLINK" -eq 1 ]; then
print_wrapped "16. YSF module:		$MODAUTO"
fi
echo ""
while true; do
    print_yellow "Are these settings correct? (YES/NO)"
    printf "> "
    read -r CONFIRM

    CONFIRM=${CONFIRM:-YES}
    CONFIRM=$(echo "$CONFIRM" | tr '[:lower:]' '[:upper:]')
    if [[ "$CONFIRM" == "YES" || "$CONFIRM" == "NO" ]]; then
        break
    else
        print_orange "Please enter 'YES' or 'NO'."
    fi
done
echo ""
if [ "$CONFIRM" == "YES" ]; then
    print_green "✔ Information verified, installation starting!"
    else
    print_redd "Installation aborted by user."
    exit 1
fi
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "UPDATING OS..."
center_wrap_color $BLUE "=============="
echo ""
apt update
apt full-upgrade -y
if [ $? -ne 0 ]; then
    center_wrap_color $RED "Error: Failed to update package lists. Check your internet connection or package manager configuration."
    exit 1
fi
#  Apply timezone only if it's NOT the system timezone.
if [[ "$TIMEZONE_USE_SYSTEM" -eq 0 ]]; then
    print_yellow "Applying new timezone: $TIMEZONE"
    timedatectl set-timezone "$TIMEZONE"
else
    print_wrapped "Detected system timezone preserved: $TIMEZONE"
fi
echo ""
print_green "✔ System updated successfully!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "INSTALLING DEPENDENCIES..."
center_wrap_color $BLUE "=========================="
echo ""
mkdir -p "$XLXINSTDIR"
apt -y install $APPS
echo ""
print_green "✔ Operation completed successfully!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "DOWNLOADING THE XLX APP..."
center_wrap_color $BLUE "=========================="
echo ""
cd "$XLXINSTDIR"
echo "Cloning repository..."
git clone "$XLXDREPO"
cd "$XLXINSTDIR/xlxd/src"
make clean
echo "Seeding customizations..."
MAINCONFIG="$XLXINSTDIR/xlxd/src/main.h"
    sed -i "s|\(NB_OF_MODULES\s*\)\([0-9]*\)|\1$MODQTD|g" "$MAINCONFIG"
    sed -i "s|\(YSF_PORT\s*\)\([0-9]*\)|\1$YSFPORT|g" "$MAINCONFIG"
    sed -i "s|\(YSF_DEFAULT_NODE_TX_FREQ\s*\)\([0-9]*\)|\1$YSFFREQ|g" "$MAINCONFIG"
    sed -i "s|\(YSF_DEFAULT_NODE_RX_FREQ\s*\)\([0-9]*\)|\1$YSFFREQ|g" "$MAINCONFIG"
    sed -i "s|\(YSF_AUTOLINK_ENABLE\s*\)\([0-9]*\)|\1$AUTOLINK|g" "$MAINCONFIG"
    if [ "$AUTOLINK" -eq 1 ]; then
        sed -i "s|\(YSF_AUTOLINK_MODULE\s*\)'\([A-Z]*\)'|\1'$MODAUTO'|g" "$MAINCONFIG"
    fi
echo ""
print_green "✔ Repository cloned and customizations applied!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "COMPILING..."
center_wrap_color $BLUE "============"
echo ""
make
make install
fi
if [ -e "$XLXINSTDIR/xlxd/src/xlxd" ]; then
    echo ""
    echo ""
    center_wrap_color $GREEN "==============================="
    center_wrap_color $GREEN "|  COMPILATION SUCCESSFUL!!!  |"
    center_wrap_color $GREEN "==============================="
    echo ""
else
    echo ""
    echo ""
    center_wrap_color $RED "======================================================"
    center_wrap_color $RED "|  Compilation FAILED. Check the output for errors.  |"
    center_wrap_color $RED "======================================================"
    echo ""
    exit 1
fi
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "COPYING COMPONENTS..."
center_wrap_color $BLUE "====================="
echo ""
mkdir -p "$XLXDIR"
mkdir -p "$WEBDIR"
touch /var/log/xlxd.xml
echo "Downloading DMR ID file..."
FILE_SIZE=$(wget --spider --server-response "$DMRIDURL" 2>&1 | grep -i Content-Length | awk '{print $2}')
if [ -z "$FILE_SIZE" ]; then
    echo "Downloading..."
    wget -q -O - "$DMRIDURL" | pv --force -p -t -r -b > /xlxd/dmrid.dat
else
    echo "File size: $FILE_SIZE bytes"
    wget -q -O - "$DMRIDURL" | pv --force -p -t -r -b -s "$FILE_SIZE" > /xlxd/dmrid.dat
fi
if [ $? -ne 0 ] || [ ! -s /xlxd/dmrid.dat ]; then
    print_redd "Error: Failed to download or empty DMR ID file."
fi
echo "Creating custom XLX log..."
cp "$DIRDIR/templates/xlx_log.service" /etc/systemd/system/
cp "$DIRDIR/templates/xlx_log.sh" /usr/local/bin/
cp "$DIRDIR/templates/xlx_logrotate.conf" /etc/logrotate.d/
chmod 755 /etc/systemd/system/xlx_log.service
chmod 755 /usr/local/bin/xlx_log.sh
chmod 644 /etc/logrotate.d/xlx_logrotate.conf
echo "Seeding customizations..."
TERMXLX="/xlxd/xlxd.terminal"
sed -i "s|#address|address $PUBLIC_IP|g" "$TERMXLX"
sed -i "s|#modules|modules $MODLIST|g" "$TERMXLX"
cp "$XLXINSTDIR/xlxd/scripts/xlxd.service" /etc/systemd/system/
chmod 755 /etc/systemd/system/xlxd.service
sed -i "s|XLXXXX 172.23.127.100 127.0.0.1|$XRFNUM $LOCAL_IP 127.0.0.1|g" /etc/systemd/system/xlxd.service
# Comment out the line "ECHO 127.0.0.1 E" in /xlxd/xlxd.interlink if Echo Test is not installed
if [ "$INSTALL_ECHO" == "N" ]; then
    sed -i 's|^ECHO 127.0.0.1 E|#ECHO 127.0.0.1 E|' /xlxd/xlxd.interlink
fi
# Creates daily update of users.db, checks if crontab is installed otherwise use systemd
if command -v crontab &>/dev/null; then
    echo "crontab found, adding entry..."
    (crontab -l 2>/dev/null; echo "0 3 * * * wget -O /xlxd/users_db/user.csv https://radioid.net/static/user.csv && php /xlxd/users_db/create_user_db.php") | crontab -
    echo "Entry added successfully!"
else
    echo "crontab is not installed, using systemd..."
    cp "$DIRDIR/templates/update_XLX_db.service" /etc/systemd/system/
    cp "$DIRDIR/templates/update_XLX_db.timer" /etc/systemd/system/
    chmod 755 /etc/systemd/system/update_XLX_db.*
    systemctl daemon-reload
    systemctl enable --now update_XLX_db.timer
fi
echo ""
print_green "✔ Operation completed successfully!"
echo ""
# Echo Test installation conditional on answering question 08
if [ "$INSTALL_ECHO" == "Y" ]; then
    line_type1
    echo ""
    center_wrap_color $BLUE_BRIGHT "INSTALLING ECHO TEST SERVER..."
    center_wrap_color $BLUE "=============================="
    echo ""
    cd "$XLXINSTDIR"
    echo "Cloning repository..."
    git clone "$XLXECHO"
    cd XLXEcho/
    gcc -o xlxecho xlxecho.c
    cp xlxecho /xlxd/
    cp "$XLXINSTDIR/xlxd/scripts/xlxecho.service" /etc/systemd/system/
    chmod 755 /etc/systemd/system/xlxecho.service
    echo ""
    print_green "✔ Echo Test server successfully installed!"
    echo ""
fi
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "INSTALLING DASHBOARD..."
center_wrap_color $BLUE "======================="
echo ""
cd "$XLXINSTDIR"
echo "Cloning repository..."
git clone "$XLXDASH"
cp -R "$XLXINSTDIR/XLX_Dark_Dashboard/"* "$WEBDIR/"
echo "Seeding customizations..."
XLXCONFIG="$WEBDIR/pgs/config.inc.php"
sed -i "s|your_email|$EMAIL|g" "$XLXCONFIG"
sed -i "s|LX1IQ|$CALLSIGN|g" "$XLXCONFIG"
sed -i "s|MODQTD|$MODQTD|g" "$XLXCONFIG"
sed -i "s|custom_header|$HEADER|g" "$XLXCONFIG"
sed -i "s|custom_footnote|$FOOTER|g" "$XLXCONFIG"
sed -i "s#http://your_dashboard#http://$XLXDOMAIN#g" "$XLXCONFIG"
sed -i "s|your_country|$COUNTRY|g" "$XLXCONFIG"
sed -i "s|your_comment|$COMMENT|g" "$XLXCONFIG"
sed -i "s|netact|$NETACT|g" "$XLXCONFIG"
cp "$DIRDIR/templates/apache.tbd.conf" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s|apache.tbd|$XLXDOMAIN|g" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s#ysf-xlxd#html/xlxd#g" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s|^;\?date\.timezone\s*=.*|date.timezone = \"$TIMEZONE\"|" /etc/php/"$PHPVER"/apache2/php.ini
APACHE_USER=$(ps aux | grep -E '[a]pache|[h]ttpd' | grep -v root | head -1 | awk '{print $1}')
if [ -z "$APACHE_USER" ]; then
    APACHE_USER="www-data"
fi
mv "$WEBDIR/users_db/" /xlxd/
echo "Updating permissions..."
chown -R "$APACHE_USER:$APACHE_USER" /var/log/xlxd.xml
chown -R "$APACHE_USER:$APACHE_USER" "$WEBDIR/"
chown -R "$APACHE_USER:$APACHE_USER" /xlxd/
find /xlxd -type d -exec chmod 755 {} \;
find /xlxd -type f -exec chmod 755 {} \;
find "$WEBDIR" -type d -exec chmod 755 {} \;
find "$WEBDIR" -type f -exec chmod 755 {} \;
/bin/bash /xlxd/users_db/update_db.sh
/usr/sbin/a2ensite "$XLXDOMAIN".conf 2>/dev/null | head -n1
/usr/sbin/a2dissite 000-default 2>/dev/null | head -n1
systemctl stop apache2 >/dev/null 2>&1
systemctl start apache2 >/dev/null 2>&1
systemctl daemon-reload
echo ""
print_green "✔ Dashboard successfully installed!"
echo ""
# SSL certification install
if [ "$INSTALL_SSL" == "Y" ]; then
    line_type1
    echo ""
    center_wrap_color $BLUE_BRIGHT "CONFIGURING SSL CERTIFICATE..."
    center_wrap_color $BLUE "=============================="
    echo ""
    certbot --apache -d "$XLXDOMAIN" -n --agree-tos -m "$EMAIL"
fi
echo ""
print_green "✔ Operation completed!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "STARTING $XRFNUM REFLECTOR..."
center_wrap_color $BLUE "============================="
echo ""
systemctl enable --now xlxd.service >/dev/null 2>&1 &
pid=$!
for ((i=10; i>0; i--)); do
    printf "\r${YELLOW}Initializing $XRFNUM %2d seconds${NC}" "$i"
    sleep 1
done
wait $pid
echo ""
systemctl enable --now xlx_log.service >/dev/null 2>&1 &
pid=$!
for ((i=5; i>0; i--)); do
    printf "\r${YELLOW}Initializing log %2d seconds${NC}" "$i"
    sleep 1
done
wait $pid
# Enable and start xlxecho.service only if Echo Test is installed
echo ""
if [ "$INSTALL_ECHO" == "Y" ]; then
    systemctl enable --now xlxecho.service >/dev/null 2>&1 &
    pid=$!
    for ((i=5; i>0; i--)); do
        printf "\r${YELLOW}Initializing Echo Test %2d seconds${NC}" "$i"
        sleep 1
    done
    wait $pid
fi
echo ""
echo -e "\n${GREEN}✔ Initialization completed!${NC}"
echo ""
line_type2
echo ""
echo ""
center_wrap_color $GREEN "========================================="
center_wrap_color $GREEN "|  REFLECTOR INSTALLED SUCCESSFULLY!!!  |"
center_wrap_color $GREEN "========================================="
echo ""
echo ""
line_type2
echo ""
center_wrap_color $GREEN "Your Reflector $XRFNUM is now installed and running!"
echo ""
center_wrap_color $GREEN "For Public Reflectors:"
echo ""
center_wrap_color $GREEN "• If your XLX number is available it's expected to be listed on the public list shortly, typically within an hour. If you don't want the reflector to be published just set callinghome to [false] in the main file in $XLXCONFIG."
center_wrap_color $GREEN "• Many other settings can be changed in this file."
center_wrap_color $GREEN "• More Information about XLX Reflectors check $INFREF"
center_wrap_color $GREEN "• Your $XRFNUM dashboard should now be accessible at http://$XLXDOMAIN"
echo ""
line_type2
