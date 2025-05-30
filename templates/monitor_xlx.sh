#!/bin/bash
MAX_WIDTH=150
cols=$(tput cols 2>/dev/null || echo "$MAX_WIDTH")
width=$(( cols < MAX_WIDTH ? cols : MAX_WIDTH ))
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
line_type1() {
    printf "%${width}s\n" | tr ' ' '_'
}
line_type2() {
    printf "%${width}s\n" | tr ' ' '='
}
center_wrapped_colored() {
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
echo ""
line_type2
echo ""
center_wrapped_colored "$GREEN" "Opening a query to the XLX Reflector log"
echo ""
center_wrapped_colored "$YELLOW" "*** (!) TO FINISH PRESS CTRL+C ***"
echo ""
line_type2
echo ""
journalctl -u xlxd.service -f | fold -s -w "$width"
