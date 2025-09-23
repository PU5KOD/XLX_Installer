#!/bin/bash
# Script para monitoramento do serviço xlxd e envio de mensagens ao Telegram
# Monitora eventos de bloqueio (Gatekeeper), conexão e desconexão de repetidoras específicas

# Verifica se o curl está instalado
if ! command -v curl >/dev/null 2>&1; then
    echo "Erro: curl não está instalado. Instale-o para continuar."
    exit 1
fi

# Configurações do Telegram
TELEGRAM_API="https://api.telegram.org/bot7799817359:AAH30CNwb9yEo8AHR0UWwL57KNx_S09o3U0/sendMessage"
CHAT_ID="1074921232"

# Arquivo temporário para armazenar os últimos eventos e evitar mensagens repetidas
TEMP_FILE="/tmp/xlxd_last_events"
touch "$TEMP_FILE"

# Lista de repetidoras a monitorar para eventos de conexão e desconexão
REPEATER_LIST="PA7LIM|F4WCP|PU2UOL|PU2VLO|PP5CPI|PY2KES|PY2KGV|PY2KPE|PY4ALV|PY4DIG|PY4KBH|PY4KDA|PY4KID|PY4RDI|PY4RFM|PY4RPF|PY4RPV"

# Variável para ativar/desativar debug (0 = desativado, 1 = ativado)
DEBUG=0

# Regexes para parsing de logs
REGEX_GATEKEEPER="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*Gatekeeper blocking (linking|transmitting) of ([A-Za-z0-9]{3,8})([[:space:]]*/?[[:space:]]*[A-Za-z0-9/ ]{0,4})?[[:space:]]+@ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) using protocol (-?[0-9]+)"
REGEX_CONNECT="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*New client ($REPEATER_LIST)([[:space:]]*[A-Za-z0-9]{0,4})? at ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) added with protocol ([A-Za-z]+)( on module ([A-Za-z]))?"
REGEX_DISCONNECT="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*Client ($REPEATER_LIST)([[:space:]]*[A-Za-z0-9]{0,4})? at ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) removed with protocol ([A-Za-z]+)( on module ([A-Za-z]))?"

# Função para debug
debug() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo "DEBUG: $@"
    fi
}

# Função para converter data/hora do formato "Feb 22 20:30:07" para "22/02/2025 20:30:07"
format_timestamp() {
    local TIMESTAMP_ORIGINAL="$1"
    MONTH=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f1)
    DAY=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f2)
    TIME=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f3)
    YEAR=$(date +%Y)
    case "$MONTH" in
        Jan) MONTH_NUMBER="01" ;;
        Feb) MONTH_NUMBER="02" ;;
        Mar) MONTH_NUMBER="03" ;;
        Apr) MONTH_NUMBER="04" ;;
        May) MONTH_NUMBER="05" ;;
        Jun) MONTH_NUMBER="06" ;;
        Jul) MONTH_NUMBER="07" ;;
        Aug) MONTH_NUMBER="08" ;;
        Sep) MONTH_NUMBER="09" ;;
        Oct) MONTH_NUMBER="10" ;;
        Nov) MONTH_NUMBER="11" ;;
        Dec) MONTH_NUMBER="12" ;;
    esac
    echo "$DAY/$MONTH_NUMBER/$YEAR $TIME"
}

# Função para mapear número do protocolo para nome
get_protocol_name() {
    local PROTOCOLO="$1"
    case "$PROTOCOLO" in
        "1") echo "DExtra" ;;
        "2") echo "DPlus" ;;
        "3") echo "DCS" ;;
        "4") echo "XLX Interlink" ;;
        "5") echo "DMR+" ;;
        "6") echo "DMR MMDVM" ;;
        "7") echo "YSF" ;;
        "8") echo "ICom G3" ;;
        "9") echo "IMRS" ;;
        *) echo "Desconhecido" ;;
    esac
}

# Função para formatar mensagem com hyperlink
format_message() {
    local TIMESTAMP="$1" INDICATIVO="$2" SUFIXO="$3" IP="$4" PROTOCOLO="$5" ACTION="$6" MODULO="$7"
    SUFIXO=$(echo "$SUFIXO" | sed 's/^\s*\/\s*//;s/^\s*//;s/\s*$//')
    if [ -z "$SUFIXO" ]; then
        echo "$TIMESTAMP - A Estação <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>, IP $IP ($PROTOCOLO) - $ACTION${MODULO:+-}$MODULO"
    else
        echo "$TIMESTAMP - A Estação <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>-$SUFIXO, IP $IP ($PROTOCOLO) - $ACTION${MODULO:+-}$MODULO"
    fi
}

# Função para enviar mensagem ao Telegram
send_telegram_message() {
    local MESSAGE="$1"
    curl -s -X POST "$TELEGRAM_API" \
        -d chat_id="$CHAT_ID" \
        -d text="$MESSAGE" \
        -d parse_mode=HTML
}

# Lê continuamente as linhas do journalctl para o serviço xlxd
sudo journalctl -u xlxd.service -f | while read -r LINE; do
    debug "Linha capturada: $LINE"

    # Verifica eventos de bloqueio do Gatekeeper
    if [[ "$LINE" =~ $REGEX_GATEKEEPER ]]; then
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}"
        ACAO="${BASH_REMATCH[2]}"
        INDICATIVO="${BASH_REMATCH[3]}"
        SUFIXO="${BASH_REMATCH[4]}"
        IP="${BASH_REMATCH[5]}"
        PROTOCOLO="${BASH_REMATCH[6]}"

        debug "Gatekeeper: Timestamp: $TIMESTAMP_ORIGINAL, Ação: $ACAO, Indicativo: $INDICATIVO, Sufixo: '$SUFIXO', IP: $IP, Protocolo: $PROTOCOLO"

        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")
        PROTOCOLO_NAME=$(get_protocol_name "$PROTOCOLO")
        ACAO_FORMATADA=$([[ "$ACAO" == "linking" ]] && echo "Tentativa de conexão no XLX300" || echo "Tentativa de transmissão no XLX300")
        MESSAGE=$(format_message "$TIMESTAMP_FORMATTED" "$INDICATIVO" "$SUFIXO" "$IP" "$PROTOCOLO_NAME" "$ACAO_FORMATADA" "")

        CURRENT_TIME=$(date +%s)
        BLOCK_EVENT=false

        if [[ "$ACAO" == "transmitting" ]]; then
            LAST_EVENT=$(grep "^$INDICATIVO transmitting " "$TEMP_FILE" | awk '{print $3}' | tail -n1)
            if [[ -n "$LAST_EVENT" && $((CURRENT_TIME - LAST_EVENT)) -lt 30 ]]; then
                debug "Ignorando mensagem repetida de transmissão para $INDICATIVO, tempo inferior a 30 segundos."
                BLOCK_EVENT=true
            else
                echo "$INDICATIVO transmitting $CURRENT_TIME" >> "$TEMP_FILE"
            fi
        fi

        if [[ "$ACAO" == "linking" ]]; then
            LAST_EVENT=$(grep "^$INDICATIVO linking $PROTOCOLO_NAME" "$TEMP_FILE" | awk '{print $4}' | tail -n1)
            if [[ -n "$LAST_EVENT" && $((CURRENT_TIME - LAST_EVENT)) -lt 15 ]]; then
                debug "Ignorando mensagem repetida de conexão para $INDICATIVO ($PROTOCOLO_NAME), tempo inferior a 15 segundos."
                BLOCK_EVENT=true
            else
                echo "$INDICATIVO linking $PROTOCOLO_NAME $CURRENT_TIME" >> "$TEMP_FILE"
            fi
        fi

        if [[ "$INDICATIVO" == "PP0AA" ]]; then
            debug "Ignorando evento para PP0AA."
            continue
        fi

        if [[ "$BLOCK_EVENT" == false ]]; then
            send_telegram_message "$MESSAGE"
        fi

        tail -n 100 "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"

    # Verifica conexão de repetidoras
    elif [[ "$LINE" =~ $REGEX_CONNECT ]]; then
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}"
        INDICATIVO="${BASH_REMATCH[2]}"
        SUFIXO="${BASH_REMATCH[3]}"
        IP="${BASH_REMATCH[4]}"
        PROTOCOLO="${BASH_REMATCH[5]}"
        MODULO="${BASH_REMATCH[7]:-}"

        debug "Conexão: Timestamp: $TIMESTAMP_ORIGINAL, Indicativo: $INDICATIVO, Sufixo: '$SUFIXO', IP: $IP, Protocolo: $PROTOCOLO, Módulo: '$MODULO'"

        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")
        MESSAGE=$(format_message "$TIMESTAMP_FORMATTED" "$INDICATIVO" "$SUFIXO" "$IP" "$PROTOCOLO" "Conectou-se no XLX300" "$MODULO")
        send_telegram_message "$MESSAGE"

    # Verifica desconexão de repetidoras
    elif [[ "$LINE" =~ $REGEX_DISCONNECT ]]; then
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}"
        INDICATIVO="${BASH_REMATCH[2]}"
        SUFIXO="${BASH_REMATCH[3]}"
        IP="${BASH_REMATCH[4]}"
        PROTOCOLO="${BASH_REMATCH[5]}"
        MODULO="${BASH_REMATCH[7]:-}"

        debug "Desconexão: Timestamp: $TIMESTAMP_ORIGINAL, Indicativo: $INDICATIVO, Sufixo: '$SUFIXO', IP: $IP, Protocolo: $PROTOCOLO, Módulo: '$MODULO'"

        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")
        MESSAGE=$(format_message "$TIMESTAMP_FORMATTED" "$INDICATIVO" "$SUFIXO" "$IP" "$PROTOCOLO" "Desconectou-se do XLX300" "$MODULO")
        send_telegram_message "$MESSAGE"

    else
        debug "Linha não corresponde à regex."
    fi
done
