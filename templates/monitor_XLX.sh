#!/bin/bash
# Script para monitoramento do serviço xlxd e envio de mensagens ao Telegram
# Monitora eventos de bloqueio (Gatekeeper), conexão e desconexão de repetidoras específicas
# Necessario verificar se o curl esta instalado

# Arquivo temporário para armazenar os últimos eventos e evitar mensagens repetidas
TEMP_FILE="/tmp/xlxd_last_events"

# Cria o arquivo temporário caso ele ainda não exista
touch "$TEMP_FILE"

# Lista de repetidoras a monitorar para eventos de conexão e desconexão
# Edite esta variável para adicionar ou remover indicativos (separados por |)
REPEATER_LIST="PU5KOD|PU1JRE|M7ESN|PU2UOL|PU2VYD|PY1IBM|PY4ARR|PP5CPI|PY2KES|PY2KPE|PY4KBH|PY4KDA|PY4RDI"

# Variável para ativar/desativar debug (0 = desativado, 1 = ativado)
DEBUG=0

# Define as regexes como variáveis para evitar problemas de parsing
REGEX_GATEKEEPER="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*Gatekeeper blocking (linking|transmitting) of ([A-Za-z0-9]{3,8})([[:space:]]*/?[[:space:]]*[A-Za-z0-9/ ]{0,4})?[[:space:]]+@ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) using protocol ([0-9]+)"
REGEX_CONNECT="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*New client ($REPEATER_LIST)([[:space:]]*[A-Za-z0-9]{0,4})? at ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) added with protocol ([A-Za-z]+)( on module ([A-Za-z]))?"
REGEX_DISCONNECT="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*Client ($REPEATER_LIST)([[:space:]]*[A-Za-z0-9]{0,4})? at ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) removed with protocol ([A-Za-z]+)( on module ([A-Za-z]))?"

# Função para converter data/hora do formato "Feb 22 20:30:07" para "22/02/2025 20:30:07"
format_timestamp() {
    local TIMESTAMP_ORIGINAL="$1"
    MONTH=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f1) # Extrai o mês (ex.: Feb)
    DAY=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f2)   # Extrai o dia (ex.: 22)
    TIME=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f3)  # Extrai a hora (ex.: 20:30:07)
    YEAR=$(date +%Y)                                    # Obtém o ano atual do sistema
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

# Lê continuamente as linhas do journalctl para o serviço xlxd
sudo journalctl -u xlxd.service -f | while read -r LINE; do
    echo "Linha capturada: $LINE"

    # Verifica eventos de bloqueio do Gatekeeper
    if [[ "$LINE" =~ $REGEX_GATEKEEPER ]]; then
        # Extrai informações da linha usando grupos da regex
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}" # Data e hora no formato original
        ACAO="${BASH_REMATCH[2]}"               # Ação bloqueada: "linking" ou "transmitting"
        INDICATIVO="${BASH_REMATCH[3]}"         # Indicativo do usuário
        SUFIXO="${BASH_REMATCH[4]}"             # Sufixo opcional
        IP="${BASH_REMATCH[5]}"                 # Endereço IP
        PROTOCOLO="${BASH_REMATCH[6]}"          # Número do protocolo

        # Debug opcional (ativado se DEBUG=1)
        if [[ "$DEBUG" -eq 1 ]]; then
            echo "DEBUG Gatekeeper: Timestamp: $TIMESTAMP_ORIGINAL"
            echo "DEBUG Gatekeeper: Ação: $ACAO"
            echo "DEBUG Gatekeeper: Indicativo: $INDICATIVO"
            echo "DEBUG Gatekeeper: Sufixo: '$SUFIXO'"
            echo "DEBUG Gatekeeper: IP: $IP"
            echo "DEBUG Gatekeeper: Protocolo: $PROTOCOLO"
        fi

        # Remove espaços e barras desnecessários do sufixo
        SUFIXO=$(echo "$SUFIXO" | sed 's/^\s*\/\s*//;s/^\s*//;s/\s*$//')

        # Converte o timestamp usando a função
        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")

        # Mapeia o número do protocolo para o nome correspondente
        case "$PROTOCOLO" in
            "1") PROTOCOLO_NAME="DExtra" ;;
            "2") PROTOCOLO_NAME="DPlus" ;;
            "3") PROTOCOLO_NAME="DCS" ;;
            "4") PROTOCOLO_NAME="XLX Interlink" ;;
            "5") PROTOCOLO_NAME="DMR+" ;;
            "6") PROTOCOLO_NAME="DMR MMDVM" ;;
            "7") PROTOCOLO_NAME="YSF" ;;
            "8") PROTOCOLO_NAME="ICom G3" ;;
            "9") PROTOCOLO_NAME="IMRS" ;;
            *) PROTOCOLO_NAME="Desconhecido" ;;
        esac

        # Define a mensagem da ação bloqueada
        if [[ "$ACAO" == "linking" ]]; then
            ACAO_FORMATADA="Tentativa de conexão no XLX300"
        else
            ACAO_FORMATADA="Tentativa de transmissão no XLX300"
        fi

        # Formata a mensagem final com hyperlink apenas no indicativo
        if [ -z "$SUFIXO" ]; then
            MESSAGE="$TIMESTAMP_FORMATTED - <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>, IP $IP ($PROTOCOLO_NAME) - $ACAO_FORMATADA"
        else
            MESSAGE="$TIMESTAMP_FORMATTED - <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>/$SUFIXO, IP $IP ($PROTOCOLO_NAME) - $ACAO_FORMATADA"
        fi

        # Obtém o timestamp atual em segundos para controle de repetição
        CURRENT_TIME=$(date +%s)

        # Variável para controlar se o evento deve ser bloqueado (repetição)
        BLOCK_EVENT=false

        # Regra para evitar mensagens repetidas de "transmitting" (limite de 30 segundos)
        if [[ "$ACAO" == "transmitting" ]]; then
            LAST_EVENT=$(grep "^$INDICATIVO transmitting " "$TEMP_FILE" | awk '{print $3}' | tail -n1)
            if [[ -n "$LAST_EVENT" && $((CURRENT_TIME - LAST_EVENT)) -lt 30 ]]; then
                echo "Ignorando mensagem repetida de transmissão para $INDICATIVO, tempo inferior a 30 segundos."
                BLOCK_EVENT=true
            else
                echo "$INDICATIVO transmitting $CURRENT_TIME" >> "$TEMP_FILE"
            fi
        fi

        # Regra para evitar mensagens repetidas de "linking" (limite de 15 segundos)
        if [[ "$ACAO" == "linking" ]]; then
            LAST_EVENT=$(grep "^$INDICATIVO linking $PROTOCOLO_NAME" "$TEMP_FILE" | awk '{print $4}' | tail -n1)
            if [[ -n "$LAST_EVENT" && $((CURRENT_TIME - LAST_EVENT)) -lt 15 ]]; then
                echo "Ignorando mensagem repetida de conexão para $INDICATIVO ($PROTOCOLO_NAME), tempo inferior a 15 segundos."
                BLOCK_EVENT=true
            else
                echo "$INDICATIVO linking $PROTOCOLO_NAME $CURRENT_TIME" >> "$TEMP_FILE"
            fi
        fi

        # Ignora eventos do indicativo "TE5TE" (exceção específica)
        if [[ "$INDICATIVO" == "TE5TE" ]]; then
            echo "Ignorando evento para TE5TE."
            continue
        fi

        # Envia a mensagem ao Telegram se não for bloqueada, com parse_mode=HTML
        if [[ "$BLOCK_EVENT" == false ]]; then
            curl -s -X POST "https://api.telegram.org/bot-INSERT_YOUR_API_HERE-/sendMessage" \
                -d chat_id=-INSERT_YOUR_CHATID_HERE- \
                -d text="$MESSAGE" \
                -d parse_mode=HTML
        fi

        # Limita o arquivo temporário a 100 linhas
        tail -n 100 "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"

    # Verifica conexão de repetidoras listadas em REPEATER_LIST
    elif [[ "$LINE" =~ $REGEX_CONNECT ]]; then
        # Extrai informações da linha de conexão
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}" # Data e hora original
        INDICATIVO="${BASH_REMATCH[2]}"         # Indicativo da repetidora
        SUFIXO="${BASH_REMATCH[3]}"             # Sufixo opcional
        IP="${BASH_REMATCH[4]}"                 # IP da repetidora
        PROTOCOLO="${BASH_REMATCH[5]}"          # Nome do protocolo
        MODULO="${BASH_REMATCH[7]}"             # Módulo conectado (se presente, grupo 7 devido ao aninhamento)

        # Define módulo como vazio se não estiver presente
        [ -z "$MODULO" ] && MODULO=""

        # Debug opcional (ativado se DEBUG=1)
        if [[ "$DEBUG" -eq 1 ]]; then
            echo "DEBUG Conexão: Timestamp: $TIMESTAMP_ORIGINAL"
            echo "DEBUG Conexão: Indicativo: $INDICATIVO"
            echo "DEBUG Conexão: Sufixo: '$SUFIXO'"
            echo "DEBUG Conexão: IP: $IP"
            echo "DEBUG Conexão: Protocolo: $PROTOCOLO"
            echo "DEBUG Conexão: Módulo: '$MODULO'"
        fi

        # Remove espaços desnecessários do sufixo
        SUFIXO=$(echo "$SUFIXO" | sed 's/^\s*//;s/\s*$//')

        # Converte o timestamp usando a função
        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")

        # Formata a mensagem de conexão com hyperlink apenas no indicativo
        if [ -z "$SUFIXO" ]; then
            MESSAGE="$TIMESTAMP_FORMATTED - A Estação <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>, IP $IP ($PROTOCOLO) - Conectou-se no XLX300${MODULO:+-}$MODULO"
        else
            MESSAGE="$TIMESTAMP_FORMATTED - A Estação <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>-$SUFIXO, IP $IP ($PROTOCOLO) - Conectou-se no XLX300${MODULO:+-}$MODULO"
        fi

        # Envia a mensagem de conexão ao Telegram, com parse_mode=HTML
        curl -s -X POST "https://api.telegram.org/bot-INSERT_YOUR_API_HERE-/sendMessage" \
            -d chat_id=-INSERT_YOUR_CHATID_HERE- \
            -d text="$MESSAGE" \
            -d parse_mode=HTML

    # Verifica desconexão de repetidoras listadas em REPEATER_LIST
    elif [[ "$LINE" =~ $REGEX_DISCONNECT ]]; then
        # Extrai informações da linha de desconexão
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}" # Data e hora original
        INDICATIVO="${BASH_REMATCH[2]}"         # Indicativo da repetidora
        SUFIXO="${BASH_REMATCH[3]}"             # Sufixo opcional
        IP="${BASH_REMATCH[4]}"                 # IP da repetidora
        PROTOCOLO="${BASH_REMATCH[5]}"          # Nome do protocolo
        MODULO="${BASH_REMATCH[7]}"             # Módulo conectado (se presente, grupo 7 devido ao aninhamento)

        # Define módulo como vazio se não estiver presente
        [ -z "$MODULO" ] && MODULO=""

        # Debug opcional (ativado se DEBUG=1)
        if [[ "$DEBUG" -eq 1 ]]; then
            echo "DEBUG Desconexão: Timestamp: $TIMESTAMP_ORIGINAL"
            echo "DEBUG Desconexão: Indicativo: $INDICATIVO"
            echo "DEBUG Desconexão: Sufixo: '$SUFIXO'"
            echo "DEBUG Desconexão: IP: $IP"
            echo "DEBUG Desconexão: Protocolo: $PROTOCOLO"
            echo "DEBUG Desconexão: Módulo: '$MODULO'"
        fi

        # Remove espaços desnecessários do sufixo
        SUFIXO=$(echo "$SUFIXO" | sed 's/^\s*//;s/\s*$//')

        # Converte o timestamp usando a função
        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")

        # Formata a mensagem de desconexão com hyperlink apenas no indicativo
        if [ -z "$SUFIXO" ]; then
            MESSAGE="$TIMESTAMP_FORMATTED - A Estação <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>, IP $IP ($PROTOCOLO) - Desconectou-se do XLX300${MODULO:+-}$MODULO"
        else
            MESSAGE="$TIMESTAMP_FORMATTED - A Estação <a href=\"https://www.qrz.com/db/$INDICATIVO\">$INDICATIVO</a>-$SUFIXO, IP $IP ($PROTOCOLO) - Desconectou-se do XLX300${MODULO:+-}$MODULO"
        fi

        # Envia a mensagem de desconexão ao Telegram, com parse_mode=HTML
        curl -s -X POST "https://api.telegram.org/bot-INSERT_YOUR_API_HERE-/sendMessage" \
            -d chat_id=-INSERT_YOUR_CHATID_HERE- \
            -d text="$MESSAGE" \
            -d parse_mode=HTML
    else
        echo "Linha não corresponde à regex."
    fi
done
