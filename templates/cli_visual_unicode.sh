#!/usr/bin/env bash

######################################################################
#  CORE COLOR PALETTE
######################################################################

NC='\033[0m'
BLUE='\033[38;5;39m'
BLUE_SOFT='\033[38;5;110m'
GREEN='\033[38;5;46m'
GREEN_SOFT='\033[38;5;113m'
YELLOW='\033[1;33m'
AMBER='\033[38;5;214m'
ORANGE='\033[38;5;208m'
ORANGE_LIGHT='\033[38;5;215m'
RED='\033[38;5;203m'
RED_BRIGHT='\033[1;31m'
RED_DARK='\033[38;5;124m'
PURPLE='\033[38;5;141m'
MAGENTA='\033[38;5;199m'
GRAY_LIGHT='\033[38;5;250m'
GRAY_MEDIUM='\033[38;5;245m'
GRAY_DARK='\033[38;5;240m'
WHITE_BRIGHT='\033[1;97m'

######################################################################
#  UNICODE ICONS
######################################################################

ICON_OK="✔"
ICON_ERR="✖"
ICON_WARN="⚠"
ICON_INFO="ℹ"
ICON_FATAL="‼"
ICON_NOTE="🛈"

######################################################################
#  SEMANTIC MESSAGE FUNCTIONS
######################################################################

msg_info()    { echo -e "${BLUE}${ICON_INFO} $1${NC}"; }
msg_success() { echo -e "${GREEN}${ICON_OK} $1${NC}"; }
msg_warn()    { echo -e "${AMBER}${ICON_WARN} $1${NC}"; }
msg_caution() { echo -e "${ORANGE}${ICON_WARN} $1${NC}"; }
msg_error()   { echo -e "${RED}${ICON_ERR} $1${NC}"; }
msg_note()    { echo -e "${PURPLE}${ICON_NOTE} $1${NC}"; }

msg_fatal()   {
    echo -e "${RED_DARK}${ICON_FATAL} $1${NC}"
    exit 1
}

######################################################################
#  DYNAMIC SEPARATORS (ASCII-safe)
######################################################################

sep_line()  { printf "%${width}s\n" | tr ' ' '_'; }
sep_block() { printf "%${width}s\n" | tr ' ' '='; }
sep_star()  { printf "%${width}s\n" | tr ' ' '*'; }

######################################################################
#  DYNAMIC SECTION (perfect centering)
######################################################################

section() {
    local text="-----[ $1 ]-----"
    local len=${#text}

    if (( len >= width )); then
        echo -e "${BLUE_SOFT}${text}${NC}"
        return
    fi

    local left=$(( (width - len) / 2 ))
    local right=$(( width - len - left ))
    printf "%*s" "$left" ""
    echo -en "${BLUE_SOFT}${text}${NC}"
    printf "%*s\n" "$right" ""
}

######################################################################
#  DYNAMIC BANNER (perfect centering)
######################################################################

banner() {
    local core="[ $1 ]"
    local len=${#core}
    local left=$(( (width - len) / 2 ))
    local right=$(( width - len - left ))

    printf "%*s" "$left" "" | tr ' ' '='
    echo -en "${WHITE_BRIGHT}${core}${NC}"
    printf "%*s" "$right" "" | tr ' ' '='
    echo ""
}

######################################################################
#  SPINNER (Unicode-safe)
######################################################################

spinner() {
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do

        printf "\r${BLUE}${frames[$i]}${NC} %s" "$1"
        sleep 0.1
        ((i=(i+1)%10))
    done
}
