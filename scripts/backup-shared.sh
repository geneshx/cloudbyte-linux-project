#!/bin/bash
# backup-shared.sh: CloudByte Solutions /shared backup automation
# Author: <your name>
# Created: <today's date in YYYY-MM-DD>
# Purpose: Archive /shared (excluding /shared/backups itself) into a
#          date-stamped .tar.gz under /shared/backups/.
# Usage: sudo bash backup-shared.sh

set -eo pipefail

# --- Sudo guard -----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo "Error: backup-shared.sh must be run as root."
    echo "Hint: sudo bash $0"
    exit 1
fi

# --- Config ---------------------------------------------------------------
SOURCE=/shared
BACKUP_DIR=/shared/backups
ARCHIVE="$BACKUP_DIR/cloudbyte-shared-$(date +%F).tar.gz"

echo "Skeleton OK. Source: $SOURCE  Archive: $ARCHIVE"

cleanup() {
if [ -f "$ARCHIVE" ]; then
rm -f "$ARCHIVE"
echo "Cleanup: removed partial archive $ARCHIVE" >&2
fi
}

trap cleanup EXIT ERR INT

# --- Run the backup ------------------------------------------------------
echo "Backup: archiving $SOURCE to $ARCHIVE ..."

tar -czf "$ARCHIVE" \
    --exclude="$BACKUP_DIR" \
    "$SOURCE"

trap - EXIT ERR INT

echo "Backup: complete. $(du -h "$ARCHIVE" | cut -f1) written to $ARCHIVE"
