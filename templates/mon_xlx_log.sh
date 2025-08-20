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

clear
echo ""
line_type2
echo ""
center_wrapped_colored "$GREEN" "OPENING A QUERY TO THE XLX LOG FILE"
echo ""
center_wrapped_colored "$YELLOW" "*** (!) TO FINISH PRESS CTRL+C ***"
echo ""
line_type2
echo ""

tail -f /var/log/xlx.log | awk -v width="$width" -v yellow="$YELLOW" -v nc="$NC" '
{
    # Extrai a data e hora (primeiros 3 campos) e a mensagem (a partir do 4º campo)
    timestamp = $1 " " $2 " " $3
    msg = ""
    if (NF >= 4) {
        for (i=4; i<=NF; i++) {
            msg = msg $i " "
        }
        # Remove espaços extras no final
        sub(/[ \t]+$/, "", msg)
    }

    # Imprime a data e hora em amarelo
    printf "%s%s: %s", yellow, timestamp, nc

    # Se a mensagem for curta o suficiente, imprime diretamente
    if (length(msg) <= width - length(timestamp ": ")) {
        printf "%s\n", msg
    } else {
        # Quebra a mensagem em linhas que respeitam a largura máxima
        while (length(msg) > 0) {
            if (length(msg) <= width - length(timestamp ": ")) {
                printf "%s\n", msg
                break
            } else {
                # Encontra o ponto de quebra
                line = ""
                len = length(timestamp ": ")
                split(msg, words, " ")
                for (i=1; i<=length(words); i++) {
                    if (len + length(words[i]) + 1 <= width) {
                        line = line words[i] " "
                        len += length(words[i]) + 1
                    } else {
                        printf "%s\n", line
                        msg = ""
                        for (j=i; j<=length(words); j++) {
                            msg = msg words[j] " "
                        }
                        sub(/[ \t]+$/, "", msg)
                        break
                    }
                }
                # Se a linha foi preenchida, mas ainda há mensagem, imprime a linha
                if (line != "") {
                    printf "%s\n", line
                }
            }
        }
    }
}' OFS=""
