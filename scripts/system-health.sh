#!/bin/bash
# system-health.sh: snapshot CloudByte server health into a timestamped report.
# Author:  <your name>
# Created: <date>
# Purpose: Capture uptime/load, memory, disk, the top processes, service status,
#          and logged-in users; format with printf; write to /logs/health-reports/
#          and print it. (Alerts and archiving added in later steps.)
# Usage:   sudo bash system-health.sh

set -eo pipefail

# --- Sudo guard -----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo "Error: system-health.sh must be run as root (it writes to /logs)."
    echo "Hint: sudo bash $0"
    exit 1
fi

# --- Config ---------------------------------------------------------------
REPORT_DIR=/logs/health-reports
ARCHIVE_DIR="$REPORT_DIR/archive"
mkdir -p "$ARCHIVE_DIR"
REPORT="$REPORT_DIR/health-$(date +%F-%H%M%S).txt"
SERVICES="crond sshd"
DISK_THRESHOLD=80

# --- Build the report (tee writes it to file and to the screen at once) ---
{
    echo "=== CloudByte system health: $(date) ==="
    printf "Host: %s\n" "$(hostname)"
    echo "Host: $REPORT"
    echo ""
    echo "--- Uptime and load ---"
    uptime
    printf '\n' 
    echo ""
    echo "--- Memory ---"
    free -h    
    printf '\n'
    echo ""
    echo "--- Disk ---"DISK_THRESHOLD=80
    df -h | grep '8.0G'
    printf '\n'
    echo ""
    echo "--- Top processes by CPU ---"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
    printf '\n' 
    echo ""
    echo "--- Services ---"
    for svc in $SERVICES; do
        printf '%-12s %s\n' "$svc" "$(systemctl is-active "$svc")"
    done
    printf '\n'
    echo ""
    echo "--- Logged-in users ---"
    who
    printf '\n'
    echo ""
    echo "--- Alerts ---"
    alert_count=0    
    disk_use=$(df --output=pcent / | tail -1 | tr -d ' %')
    zombies=$(ps -eo stat= | grep -c '^Z' || true)
    for svc in $SERVICES; do
        if ! systemctl is-active --quiet "$svc"; then
                printf "ALERT: One or more required services are down\n"
                alert_count=$((alert_count + 1))
        fi
    done

if [ "$disk_use" -gt "$DISK_THRESHOLD" ]; then
    printf "ALERT: Disk usage is %s%% (threshold: %s%%)\n" \
        "$disk_use" "$DISK_THRESHOLD"
    alert_count=$((alert_count + 1))
fi

if [ "$zombies" -gt 0 ]; then
    printf "ALERT: %s zombie process(es) detected\n" "$zombies"
    alert_count=$((alert_count + 1))
fi

if [ "$alert_count" -eq 0 ]; then
    printf "Everything is within limits\n"
fi
} | tee "$REPORT"

# --- Archive reports older than a week ------------------------------------
find "$REPORT_DIR" -maxdepth 1 -name 'health-*.txt' -mtime +7 -exec mv {} "$ARCHIVE_DIR"/ \;
