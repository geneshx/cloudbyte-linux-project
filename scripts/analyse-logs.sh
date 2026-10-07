#!/bin/bash
# analyse-logs.sh: summarise /logs/cloudbyte-app.log into a timestamped report.
# Author:  <your name>
# Created: <date>
# Purpose: Count entries by severity, find the busiest hour, and list every
#          CRITICAL entry; write the report to /logs/reports/ and print it.
# Usage:   sudo bash analyse-logs.sh

set -eo pipefail

# --- Sudo guard -----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo "Error: analyse-logs.sh must be run as root (it writes to /logs)."
    echo "Hint: sudo bash $0"
    exit 1
fi

# --- Config ---------------------------------------------------------------
LOG=/logs/cloudbyte-app.log
REPORT="/logs/reports/log-analysis-$(date +%F-%H%M%S).txt"

# --- Build the report (tee writes it to file and to the screen at once) ---
{
    echo "=== CloudByte log analysis: $(date) ==="
    echo "Source: $LOG"
    echo "Total entries: $(wc -l < "$LOG")"
    echo ""
    echo "--- Count by severity ---"
    awk '{ print $3 }' "$LOG" | sort | uniq -c | sort -rn
    echo ""
    echo "--- Busiest hour ---"
    awk '{ print $2 }' "$LOG" | cut -c1-2 | sort | uniq -c | sort -rn | head -1
    echo ""
    echo "--- CRITICAL entries ---"
    grep '\[CRITICAL\]' "$LOG" || echo "(none)"
} | tee "$REPORT"
