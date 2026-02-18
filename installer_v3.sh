#!/bin/bash
# A tool to install XLXD, your own D-Star Reflector.
# For more information, please visit https://xlxbbs.epf.lu/
# Customized by Daniel K., PU5KOD
# Lets begin!!!

# Enable strict error handling
set -o pipefail

#  INITIAL CHECKS
#  1. Check if running as root, with automatic relaunch
if [ "$(id -u)" -ne 0 ]; then
    echo "This script is not being run as root."
    read -r -p "Do you want to relaunch with sudo? (y/n) " answer

    answer=${answer:-y}
    case "$answer" in
        y|Y|yes|YES)
            echo "Relaunching with sudo..."
            exec sudo bash "$0" "$@"
            ;;
        *)
            echo "Operation cancelled by user."
            exit 1
            ;;
    esac
fi

#  2. Redirect all output to the log and keep it in the terminal
if ! mkdir -p "$PWD/log"; then
    echo "ERROR: Failed to create log directory at $PWD/log"
    exit 1
fi
LOGFILE="$PWD/log/log_xlx_install_$(date +%F_%H-%M-%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

#  3. Internet check (retry up to 3 times for reliability)
PING_SUCCESS=0
for i in {1..3}; do
    if ping -c 1 -W 2 google.com &>/dev/null; then
        PING_SUCCESS=1
        break
    fi
    sleep 1
done

if [ "$PING_SUCCESS" -eq 0 ]; then
    echo "Unable to proceed, no internet connection detected. Please check your network."
    exit 1
fi

#  4. Distro check
if [ ! -e "/etc/debian_version" ]; then
    echo "This script has only been tested on Debian-based distributions."
    read -p "Do you want to continue anyway? (Y/N) " answer
    [[ "$answer" =~ ^[yY](es)?$ ]] || { echo "Execution cancelled."; exit 1; }
fi

#  5. Set the fixed character limit
MAX_WIDTH=100
cols=$(tput cols 2>/dev/null || echo "$MAX_WIDTH")
width=$(( cols < MAX_WIDTH ? cols : MAX_WIDTH ))

#  6. Function to create different types of lines adjusted to length
line_type1() {
    printf "%${width}s\n" | tr ' ' '_'
}
line_type2() {
    printf "%${width}s\n" | tr ' ' '='
}
line_type3() {
    printf "%${width}s\n" | tr ' ' ':'
}

#  7. Function to display text with adjusted line breaks
print_wrapped() {
    echo "$1" | fold -s -w "$width"
}

SEPQUE="_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_"

#  8. Parameter definition
XLXINS=$(pwd)
USRSRC="/usr/src"
HOMEIP=$(hostname -I | awk '{print $1}')
PUBLIP=$(curl -m 5 -s https://v4.ident.me)
if [ -z "$PUBLIP" ]; then
    echo "Warning: Could not determine public IP address"
    PUBLIP="0.0.0.0"
fi
NETACT=$(ip -o addr show up | awk '{print $2}' | grep -v lo | head -n1)
INFREF="https://xlxbbs.epf.lu/"
XLXREP="https://github.com/PU5KOD/xlxd.git"
XLXECO="https://github.com/PU5KOD/XLXEcho.git"
XLXDSH="https://github.com/PU5KOD/XLX_Dark_Dashboard.git"
DMRURL="http://xlxapi.rlx.lu/api/exportdmr.php"
WEBDIR="/var/www/html/xlxd"
XLXDIR="/xlxd"
ACCEPT="| [ENTER] to accept..."
DEPAPP="git git-core make gcc g++ pv sqlite3 apache2 php libapache2-mod-php php-cli php-xml php-mbstring php-curl php-sqlite3 build-essential vnstat certbot python3-certbot-apache"

#  9. Color palette
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

#  10. Unicode icons
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

#  11. Functions to display text with adjusted line breaks and colors
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

#  12. Helper functions for error handling and sed escaping
error_exit() {
    print_redd "ERROR: $1"
    exit 1
}

success_msg() {
    print_green "✔ $1"
}

# Escape special characters for use in sed replacement strings
escape_sed() {
    printf '%s\n' "$1" | sed 's/[&/\]/\\&/g'
}

#  13. Check for existing installs
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

#  13. Start of data collection
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


    print_red "Mandatory"
    print_wrapped "01. XLX Reflector ID, 3 alphanumeric characters. (e.g., 300, US1, BRA)"
    while true; do
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


echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "02. Dashboard FQDN (fully qualified domain name), (e.g., xlxbra.net)"
    while true; do
    printf "> "
    read -r XLXDOMAIN
    XLXDOMAIN=$(echo "$XLXDOMAIN" | tr '[:upper:]' '[:lower:]')
    if [[ "$XLXDOMAIN" =~ ^([a-z0-9-]+\.)+[a-z]{2,}$ ]]; then
        break
    fi
        print_orange "Invalid domain. Must be a valid FQDN (e.g., xlx.example.com)."
done
print_yellow "Using: $XLXDOMAIN"


echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "03. Sysop e-mail address"
    while true; do
    printf "> "
    read -r EMAIL
    EMAIL=$(echo "$EMAIL" | tr '[:upper:]' '[:lower:]')
    if [[ "$EMAIL" =~ ^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$ ]]; then
        break
    fi
    print_orange "Invalid email format. (e.g., user@domain.com)."
done
print_yellow "Using: $EMAIL"


echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "04. Sysop callsign. Only letters and numbers allowed, max 8 characters."
    while true; do
    printf "> "
    read -r CALLSIGN
    CALLSIGN=$(echo "$CALLSIGN" | tr '[:lower:]' '[:upper:]')
    if [[ "$CALLSIGN" =~ ^[A-Z0-9]{3,8}$ ]]; then
        break
    fi
    print_orange "Invalid callsign. Use only letters and numbers, 3 - 8 characters."
done
print_yellow "Using: $CALLSIGN"


echo ""
echo "$SEPQUE"
echo ""
    print_red "Mandatory"
    print_wrapped "05. Reflector country name."
    while true; do
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
    ZONEFILE=$(readlink -f "/usr/share/zoneinfo/$TIMEZONE" 2>/dev/null)
    if [ -z "$ZONEFILE" ] || [ ! -f "$ZONEFILE" ]; then
        print_orange "Warning: Timezone file not found. Using system default."
        TIMEZONE="$AUTO_TZ"
        ZONEFILE=$(readlink -f "/usr/share/zoneinfo/$TIMEZONE")
    fi
    
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


echo ""
echo "$SEPQUE"
echo ""
    COMMENT_DEFAULT="$XRFNUM Multiprotocol Reflector by $CALLSIGN, info: $EMAIL"
    print_wrapped "07. Comment to XLX Reflectors list."
    print_gray "Suggested: \"$COMMENT_DEFAULT\" $ACCEPT"
    while true; do
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
    while true; do
    printf "> "
    read -r HEADER
    HEADER=${HEADER:-"$HEADER_DEFAULT"}
    if [ ${#HEADER} -le 50 ]; then
        break
    else
        print_orange "Error: Comment must be max 50 characters. Please try again!"
    fi
done
print_yellow "Using: $HEADER"


echo ""
echo "$SEPQUE"
echo ""
    FOOTER_DEFAULT="Provided by $CALLSIGN, info: $EMAIL"
    print_wrapped "09. Custom text on footer of the dashboard webpage."
    print_gray "Suggested: \"$FOOTER_DEFAULT\" $ACCEPT"
    while true; do
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


echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "10. Create an SSL certificate (https) for the dashboard webpage? (Y/N)"
    print_gray "Suggested: Y $ACCEPT"
    while true; do
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


echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "11. Install Echo Test on module E? (Y/N)"
    print_gray "Suggested: Y $ACCEPT"
    while true; do
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


echo ""
echo "$SEPQUE"
echo ""
    MIN_MODULES=1
    if [ "$INSTALL_ECHO" == "Y" ]; then
        MIN_MODULES=5
    fi
    print_wrapped "12. Number of active modules for the DStar Reflector. ($MIN_MODULES - 26)"
    print_gray "Suggested: 5 $ACCEPT"
    while true; do
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


echo ""
echo "$SEPQUE"
echo ""
print_wrapped "13. YSF Reflector UDP port number. (1-65535)"
print_gray "Suggested: 42000 $ACCEPT"
while true; do
    printf "> "
    read -r YSFPORT
    YSFPORT=${YSFPORT:-42000}

    # Validação numérica
    if [[ ! "$YSFPORT" =~ ^[0-9]+$ || "$YSFPORT" -lt 1 || "$YSFPORT" -gt 65535 ]]; then
        print_orange "Error: Must be a number between 1 and 65535. Try again!"
        continue
    fi

    # Checagem se porta está em uso
    if ss -tuln 2>/dev/null | grep -q ":$YSFPORT "; then
        print_orange "Warning: Port $YSFPORT appears to be in use."

        while true; do
            read -p "Do you want to continue anyway? (Y/N) " PORT_ANSWER
            PORT_ANSWER=$(echo "${PORT_ANSWER:-N}" | tr '[:lower:]' '[:upper:]')

            case "$PORT_ANSWER" in
                Y)
                    break 2   # sai dos dois loops
                    ;;
                N)
                    print_gray "Please enter a different port."
                    break     # sai só do loop interno
                    ;;
                *)
                    print_orange "Please answer Y or N."
                    ;;
            esac
        done

        continue
    fi

    break
done

print_yellow "Using: $YSFPORT"


echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "14. YSF Wires-X frequency. In Hertz, 9 digits."
    print_gray "Suggested: 433125000 $ACCEPT"
    while true; do
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


echo ""
echo "$SEPQUE"
echo ""
    print_wrapped "15. Auto-link YSF to a module? (Y/N)"
    print_gray "Suggested: Y $ACCEPT"
    while true; do
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

# Data input verification
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
print_wrapped "06. Time Zone:		$TIMEZONE"
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
    print_yellow "Are these settings correct? (YES/NO)"
    while true; do
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
echo ""
print_wrapped "Timezone adjustment"
if [[ "$TIMEZONE_USE_SYSTEM" -eq 0 ]]; then
    print_yellow "Applying new timezone: $TIMEZONE"
    timedatectl set-timezone "$TIMEZONE"
else
    print_gray "Detected system timezone preserved: $TIMEZONE"
fi
echo ""
print_green "✔ System updated successfully!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "INSTALLING DEPENDENCIES..."
center_wrap_color $BLUE "=========================="
echo ""

# Check available disk space (require at least 1GB)
AVAIL_SPACE=$(df /usr/src | tail -1 | awk '{print $4}')
if [ "$AVAIL_SPACE" -lt 1048576 ]; then
    error_exit "Insufficient disk space. At least 1GB required in /usr/src"
fi

apt -y install $DEPAPP
if [ $? -ne 0 ]; then
    error_exit "Failed to install dependencies. Check package manager configuration."
fi

PHPVER=$(php -v | head -n1 | awk '{print $2}' | cut -d. -f1,2)
if [ -z "$PHPVER" ]; then
    error_exit "PHP installation failed or version could not be determined"
fi

echo ""
success_msg "Dependencies installed! PHP version: $PHPVER"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "DOWNLOADING THE XLX APP..."
center_wrap_color $BLUE "=========================="
echo ""
echo ""
cd "$USRSRC" || error_exit "Failed to change to $USRSRC directory"
echo "Cloning repository..."
git clone --depth 1 "$XLXREP" || error_exit "Failed to clone XLX repository"
cd "$USRSRC/xlxd/src" || error_exit "Failed to change to xlxd/src directory"
make clean
echo "Seeding customizations..."
MAINCONFIG="$USRSRC/xlxd/src/main.h"
if [ ! -f "$MAINCONFIG" ]; then
    error_exit "Configuration file $MAINCONFIG not found"
fi

# Use safer sed with proper escaping and combined operations
sed -i \
    -e "s|\(NB_OF_MODULES\s*\)[0-9]*|\1$MODQTD|g" \
    -e "s|\(YSF_PORT\s*\)[0-9]*|\1$YSFPORT|g" \
    -e "s|\(YSF_DEFAULT_NODE_TX_FREQ\s*\)[0-9]*|\1$YSFFREQ|g" \
    -e "s|\(YSF_DEFAULT_NODE_RX_FREQ\s*\)[0-9]*|\1$YSFFREQ|g" \
    -e "s|\(YSF_AUTOLINK_ENABLE\s*\)[0-9]*|\1$AUTOLINK|g" \
    "$MAINCONFIG"

if [ "$AUTOLINK" -eq 1 ]; then
    sed -i "s|\(YSF_AUTOLINK_MODULE\s*\)'[A-Z]*'|\1'$MODAUTO'|g" "$MAINCONFIG"
fi
echo ""
success_msg "Repository cloned and customizations applied!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "COMPILING..."
center_wrap_color $BLUE "============"
echo ""
echo ""
make || error_exit "Compilation failed. Check build dependencies and logs."
make install || error_exit "Installation of compiled binaries failed"
fi
if [ -e "$USRSRC/xlxd/src/xlxd" ]; then
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
echo ""
mkdir -p "$XLXDIR" || error_exit "Failed to create $XLXDIR directory"
mkdir -p "$WEBDIR" || error_exit "Failed to create $WEBDIR directory"
touch /var/log/xlxd.xml
echo "Downloading DMR ID file..."
FILE_SIZE=$(wget --spider --server-response "$DMRURL" 2>&1 | grep -i Content-Length | awk '{print $2}')
if [ -z "$FILE_SIZE" ]; then
    echo "Downloading..."
    wget -q -O - "$DMRURL" | pv --force -p -t -r -b > /xlxd/dmrid.dat
else
    echo "File size: $FILE_SIZE bytes"
    wget -q -O - "$DMRURL" | pv --force -p -t -r -b -s "$FILE_SIZE" > /xlxd/dmrid.dat
fi
if [ $? -ne 0 ] || [ ! -s /xlxd/dmrid.dat ]; then
    error_exit "Failed to download DMR ID file or file is empty"
fi
echo "Creating custom XLX log..."
cp "$XLXINS/templates/xlx_log.service" /etc/systemd/system/ || error_exit "Failed to copy xlx_log.service"
cp "$XLXINS/templates/xlx_log.sh" /usr/local/bin/ || error_exit "Failed to copy xlx_log.sh"
cp "$XLXINS/templates/xlx_logrotate.conf" /etc/logrotate.d/ || error_exit "Failed to copy xlx_logrotate.conf"
chmod 755 /etc/systemd/system/xlx_log.service
chmod 755 /usr/local/bin/xlx_log.sh
chmod 644 /etc/logrotate.d/xlx_logrotate.conf
echo "Seeding customizations..."
TERMXLX="/xlxd/xlxd.terminal"
# Safely escape variables for sed
PUBLIP_ESC=$(escape_sed "$PUBLIP")
# Create module list - MODQTD already validated during user input (line 538: 1-26 range)
# Defensive assertion in case validation is bypassed
if [ "$MODQTD" -lt 1 ] || [ "$MODQTD" -gt 26 ]; then
    error_exit "MODQTD out of valid range (1-26): $MODQTD"
fi
# printf "%${MODQTD}s" creates MODQTD spaces, tr converts to newlines, awk generates A-Z letters
MODLIST=$(printf "%${MODQTD}s" | tr ' ' '\n' | awk '{printf "%c", 65+NR-1}' | tr -d '\n')
MODLIST_ESC=$(escape_sed "$MODLIST")

sed -i "s|#address|address $PUBLIP_ESC|g" "$TERMXLX"
sed -i "s|#modules|modules $MODLIST_ESC|g" "$TERMXLX"
cp "$USRSRC/xlxd/scripts/xlxd.service" /etc/systemd/system/ || error_exit "Failed to copy xlxd.service"
chmod 755 /etc/systemd/system/xlxd.service
# Escape variables for sed and combine operations
XRFNUM_ESC=$(escape_sed "$XRFNUM")
HOMEIP_ESC=$(escape_sed "$HOMEIP")
sed -i \
    -e "s|XLXXXX 172.23.127.100 127.0.0.1|$XRFNUM_ESC $HOMEIP_ESC 127.0.0.1|g" \
    /etc/systemd/system/xlxd.service
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
    cp "$XLXINS/templates/update_XLX_db.service" /etc/systemd/system/
    cp "$XLXINS/templates/update_XLX_db.timer" /etc/systemd/system/
    chmod 755 /etc/systemd/system/update_XLX_db.*
    systemctl daemon-reload
    systemctl enable --now update_XLX_db.timer
fi
echo ""
success_msg "Components copied and configured!"
echo ""
# Echo Test installation conditional (question 11 in user input sequence)
if [ "$INSTALL_ECHO" == "Y" ]; then
    line_type1
    echo ""
    center_wrap_color $BLUE_BRIGHT "INSTALLING ECHO TEST SERVER..."
    center_wrap_color $BLUE "=============================="
    echo ""
    echo ""
    cd "$USRSRC" || error_exit "Failed to change to $USRSRC directory"
    echo "Cloning repository..."
    git clone --depth 1 "$XLXECO" || error_exit "Failed to clone Echo Test repository"
    cd XLXEcho/ || error_exit "Failed to change to XLXEcho directory"
    gcc -o xlxecho xlxecho.c || error_exit "Failed to compile Echo Test"
    cp xlxecho /xlxd/ || error_exit "Failed to copy Echo Test binary"
    cp "$USRSRC/xlxd/scripts/xlxecho.service" /etc/systemd/system/ || error_exit "Failed to copy xlxecho.service"
    chmod 755 /etc/systemd/system/xlxecho.service
    echo ""
    success_msg "Echo Test server successfully installed!"
    echo ""
fi
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "INSTALLING DASHBOARD..."
center_wrap_color $BLUE "======================="
echo ""
echo ""
cd "$USRSRC" || error_exit "Failed to change to $USRSRC directory"
echo "Cloning repository..."
git clone --depth 1 "$XLXDSH" || error_exit "Failed to clone Dashboard repository"
cp -R "$USRSRC/XLX_Dark_Dashboard/"* "$WEBDIR/" || error_exit "Failed to copy dashboard files"
echo "Seeding customizations..."
XLXCONFIG="$WEBDIR/pgs/config.inc.php"
if [ ! -f "$XLXCONFIG" ]; then
    error_exit "Configuration file $XLXCONFIG not found"
fi

# Escape variables for sed
EMAIL_ESC=$(escape_sed "$EMAIL")
CALLSIGN_ESC=$(escape_sed "$CALLSIGN")
HEADER_ESC=$(escape_sed "$HEADER")
FOOTER_ESC=$(escape_sed "$FOOTER")
XLXDOMAIN_ESC=$(escape_sed "$XLXDOMAIN")
COUNTRY_ESC=$(escape_sed "$COUNTRY")
COMMENT_ESC=$(escape_sed "$COMMENT")
NETACT_ESC=$(escape_sed "$NETACT")

# Apply all customizations with escaped variables
sed -i \
    -e "s|your_email|$EMAIL_ESC|g" \
    -e "s|LX1IQ|$CALLSIGN_ESC|g" \
    -e "s|MODQTD|$MODQTD|g" \
    -e "s|custom_header|$HEADER_ESC|g" \
    -e "s|custom_footnote|$FOOTER_ESC|g" \
    -e "s|your_country|$COUNTRY_ESC|g" \
    -e "s|your_comment|$COMMENT_ESC|g" \
    -e "s|netact|$NETACT_ESC|g" \
    "$XLXCONFIG"

# Handle URL separately due to # character
sed -i "s#http://your_dashboard#http://$XLXDOMAIN_ESC#g" "$XLXCONFIG"

cp "$XLXINS/templates/apache.tbd.conf" /etc/apache2/sites-available/"$XLXDOMAIN".conf || error_exit "Failed to copy Apache config"
sed -i \
    -e "s|apache.tbd|$XLXDOMAIN_ESC|g" \
    -e "s#ysf-xlxd#html/xlxd#g" \
    /etc/apache2/sites-available/"$XLXDOMAIN".conf

# Set PHP timezone - escape timezone value
TIMEZONE_ESC=$(escape_sed "$TIMEZONE")
sed -i "s|^;\\?date\\.timezone\\s*=.*|date.timezone = \"$TIMEZONE_ESC\"|" /etc/php/"$PHPVER"/apache2/php.ini

# Detect Apache user
APACHE_USER=$(ps aux | grep -E '[a]pache|[h]ttpd' | grep -v root | head -1 | awk '{print $1}')
if [ -z "$APACHE_USER" ]; then
    APACHE_USER="www-data"
fi
mv "$WEBDIR/users_db/" /xlxd/ || error_exit "Failed to move users_db directory"
echo "Updating permissions..."
chown -R "$APACHE_USER:$APACHE_USER" /var/log/xlxd.xml
chown -R "$APACHE_USER:$APACHE_USER" "$WEBDIR/"
chown -R "$APACHE_USER:$APACHE_USER" /xlxd/
# Set proper permissions: 755 for directories, 644 for regular files, 755 for executables
find /xlxd -type d -exec chmod 755 {} \;
find "$WEBDIR" -type d -exec chmod 755 {} \;
# Set files to 644 by default
find /xlxd -type f -exec chmod 644 {} \;
find "$WEBDIR" -type f -exec chmod 644 {} \;
# Make scripts executable (only if they exist)
if [ -f /xlxd/xlxd ]; then
    chmod 755 /xlxd/xlxd
fi
if [ -f /xlxd/xlxecho ]; then
    chmod 755 /xlxd/xlxecho
fi
# Use find for safe handling of .sh files in users_db directory
if [ -d /xlxd/users_db ]; then
    find /xlxd/users_db -type f -name '*.sh' -exec chmod 755 {} \;
fi

/bin/bash /xlxd/users_db/update_db.sh || print_orange "Warning: Failed to update user database"
/usr/sbin/a2ensite "$XLXDOMAIN".conf 2>/dev/null | head -n1
/usr/sbin/a2dissite 000-default 2>/dev/null | head -n1
systemctl stop apache2 >/dev/null 2>&1
systemctl start apache2 >/dev/null 2>&1 || error_exit "Failed to start Apache"
systemctl daemon-reload
echo ""
success_msg "Dashboard successfully installed!"
echo ""
# SSL certification install
if [ "$INSTALL_SSL" == "Y" ]; then
    line_type1
    echo ""
    center_wrap_color $BLUE_BRIGHT "CONFIGURING SSL CERTIFICATE..."
    center_wrap_color $BLUE "=============================="
    echo ""
    echo ""
    if certbot --apache -d "$XLXDOMAIN" -n --agree-tos -m "$EMAIL"; then
        success_msg "SSL certificate installed successfully!"
    else
        print_orange "Warning: SSL certificate installation failed. You can configure it manually later."
    fi
fi
echo ""
success_msg "Configuration completed!"
echo ""
line_type1
echo ""
center_wrap_color $BLUE_BRIGHT "STARTING $XRFNUM REFLECTOR..."
center_wrap_color $BLUE "============================="
echo ""
echo ""
systemctl enable --now xlxd.service >/dev/null 2>&1 &
pid=$!
for ((i=10; i>0; i--)); do
    printf "\r${YELLOW}Initializing $XRFNUM %2d seconds${NC}" "$i"
    sleep 1
done
wait $pid

# Verify service started successfully
if ! systemctl is-active --quiet xlxd.service; then
    print_orange "Warning: xlxd service may not have started correctly. Check with: systemctl status xlxd"
fi

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
    
    # Verify echo service started
    if ! systemctl is-active --quiet xlxecho.service; then
        print_orange "Warning: xlxecho service may not have started correctly"
    fi
fi
echo ""
echo -e "\n${GREEN}✔ Initialization completed!${NC}"
echo ""

# Post-installation validation
echo "Running post-installation validation..."
VALIDATION_FAILED=0

# Check if xlxd binary exists
if [ ! -f "/xlxd/xlxd" ]; then
    print_redd "✖ XLXD binary not found at /xlxd/xlxd"
    VALIDATION_FAILED=1
else
    print_green "✔ XLXD binary found"
fi

# Check if xlxd service is running
if systemctl is-active --quiet xlxd.service; then
    print_green "✔ XLXD service is running"
else
    print_redd "✖ XLXD service is not running"
    VALIDATION_FAILED=1
fi

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    print_green "✔ Apache service is running"
else
    print_orange "⚠ Apache service is not running"
fi

# Check if dashboard files exist
if [ -f "$WEBDIR/index.php" ]; then
    print_green "✔ Dashboard files found"
else
    print_orange "⚠ Dashboard files not found at expected location"
fi

# Check if echo service is running (if installed)
if [ "$INSTALL_ECHO" == "Y" ]; then
    if systemctl is-active --quiet xlxecho.service; then
        print_green "✔ Echo Test service is running"
    else
        print_orange "⚠ Echo Test service is not running"
    fi
fi

if [ "$VALIDATION_FAILED" -eq 1 ]; then
    echo ""
    print_orange "⚠ Some validation checks failed. Please review the installation logs."
    print_orange "You can check service status with: systemctl status xlxd.service"
fi

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
