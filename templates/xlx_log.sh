#!/bin/bash
# Script to capture logs from the xlxd program and save them in /var/log/xlx.log with journalctl format

LOG_FILE="/var/log/xlx.log"
SERVICE_NAME="xlxd"
TEMP_FILE="/tmp/xlx_log_last.txt"

# Ensures the log file exists and has proper permissions
echo "DEBUG: Creating/Verifying $LOG_FILE" >&2
touch $LOG_FILE || { echo "ERROR: Failed to create $LOG_FILE" >&2; exit 1; }
chown root:www-data $LOG_FILE || { echo "ERROR: Failed to adjust permissions of $LOG_FILE" >&2; exit 1; }
chmod 644 $LOG_FILE || { echo "ERROR: Failed to set permissions for $LOG_FILE" >&2; exit 1; }

# Creates temporary file to track latest messages
touch $TEMP_FILE || { echo "ERROR: Failed to create $TEMP_FILE" >&2; exit 1; }

# Variables to accumulate timestamp and message
TIMESTAMP=""
MESSAGE=""

# Function to record a complete log
write_log() {
    if [ -n "$TIMESTAMP" ] && [ -n "$MESSAGE" ]; then
        LOG_LINE="$TIMESTAMP: $MESSAGE"
        # Checks for duplicates before saving
        if ! grep -Fx "$LOG_LINE" $TEMP_FILE > /dev/null; then
            echo "DEBUG: Recording log: $LOG_LINE" >&2
            echo "$LOG_LINE" >> $LOG_FILE
            # Keep only the last 100 lines in the temporary file
            echo "$LOG_LINE" >> $TEMP_FILE
            tail -n 100 $TEMP_FILE > $TEMP_FILE.tmp && mv $TEMP_FILE.tmp $TEMP_FILE
        else
            echo "DEBUG: Ignoring duplicate: $LOG_LINE" >&2
        fi
        # Resets only MESSAGE to allow new messages with the same TIMESTAMP
        MESSAGE=""
    fi
}

# Trap to write last log when script ends
trap 'write_log; echo "DEBUG: Script finished, last log written" >&2; exit 0' EXIT SIGINT SIGTERM

# Capture journalctl logs for xlxd program
echo "DEBUG: Starting journalctl for $SERVICE_NAME" >&2
journalctl -t xlxd -f -o verbose | while read -r line; do
    # Extract SYSLOG_TIMESTAMP
    if [[ $line =~ SYSLOG_TIMESTAMP=(.*) ]]; then
        TIMESTAMP=${BASH_REMATCH[1]}
        echo "DEBUG: Timestamp found: $TIMESTAMP" >&2
    fi
    # Extracts MESSAGE and immediately writes if TIMESTAMP exists
    if [[ $line =~ MESSAGE=(.*) ]]; then
        MESSAGE=${BASH_REMATCH[1]}
        echo "DEBUG: Message found: $MESSAGE" >&2
        write_log
    fi
done
