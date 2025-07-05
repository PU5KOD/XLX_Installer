#!/bin/bash
# Script to capture logs from the xlxd service and save them in /var/log/xlx.log
LOG_FILE="/var/log/xlx.log"
SERVICE_NAME="xlxd.service"
TEMP_FILE="/tmp/xlx_log_last.txt"

# Ensures the log file exists and has proper permissions
echo "DEBUG: Creating/Verifying $LOG_FILE" >&2
touch $LOG_FILE || { echo "ERROR: Failed to create $LOG_FILE" >&2; exit 1; }
chown root:www-data $LOG_FILE || { echo "ERROR: Failed to adjust permissions of $LOG_FILE" >&2; exit 1; }
chmod 644 $LOG_FILE || { echo "ERROR: Failed to set permissions for $LOG_FILE" >&2; exit 1; }

# Creates temporary file to track latest messages
echo "DEBUG: Creating/Verifying $TEMP_FILE" >&2
touch $TEMP_FILE || { echo "ERROR: Failed to create $TEMP_FILE" >&2; exit 1; }

# Function to record a complete log
write_log() {
    local log_line="$1"
    if [ -n "$log_line" ]; then
        # Checks for duplicates before saving
        if ! grep -Fx "$log_line" $TEMP_FILE > /dev/null; then
            echo "DEBUG: Writing to $LOG_FILE: $log_line" >&2
            echo "$log_line" >> $LOG_FILE
            echo "$log_line" >> $TEMP_FILE
            tail -n 100 $TEMP_FILE > $TEMP_FILE.tmp && mv $TEMP_FILE.tmp $TEMP_FILE || { echo "ERROR: Failed to update $TEMP_FILE" >&2; }
        else
            echo "DEBUG: Ignoring duplicate: $log_line" >&2
        fi
    else
        echo "DEBUG: Skipping empty log line" >&2
    fi
}

# Trap to ensure clean exit
trap 'echo "DEBUG: Script finished" >&2; exit 0' EXIT SIGINT SIGTERM

# Capture journalctl logs for xlxd service
echo "DEBUG: Starting journalctl for $SERVICE_NAME" >&2
journalctl -u $SERVICE_NAME -f | while IFS= read -r line; do
    echo "DEBUG: Processing line: $line" >&2
    # Check if the line matches the expected log format
    if [[ $line =~ ^([A-Za-z]{3})\ ([0-9]{2})\ ([0-9]{2}:[0-9]{2}:[0-9]{2}).*:[[:space:]]*(.*)$ ]]; then
        MONTH=${BASH_REMATCH[1]}
        DAY=${BASH_REMATCH[2]}
        TIME=${BASH_REMATCH[3]}
        MESSAGE=${BASH_REMATCH[4]}
        # Reformat timestamp to "day month, time"
        TIMESTAMP="$DAY $MONTH, $TIME"
        LOG_LINE="$TIMESTAMP: $MESSAGE"
        echo "DEBUG: Parsed - Timestamp: $TIMESTAMP, Message: $MESSAGE" >&2
        write_log "$LOG_LINE"
    else
        echo "DEBUG: Line ignored (no match): $line" >&2
    fi
done
