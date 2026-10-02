#!/bin/bash
# cleanup-backups.sh: CloudByte Solutions backup retention
# Author: <student name>
# Created: <YYYY-MM-DD>
# Purpose: Delete backup archives older than 7 days from /shared/backups.
# Usage: sudo bash cleanup-backups.sh           # delete real
# Usage: sudo bash cleanup-backups.sh --preview # list, don't delete

set -eo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Error: cleanup-backups.sh must be run as root."
    echo "Hint: sudo bash $0"
    exit 1
fi

BACKUP_DIR=/shared/backups
RETENTION_DAYS=7
PREVIEW=false

while [ $# -gt 0 ]; do
    case "$1" in
        --preview)
            PREVIEW=true
            shift
            ;;
        -h|--help)
            cat <<'EOF'
cleanup-backups.sh: delete backup archives older than 7 days

Usage:
  sudo bash cleanup-backups.sh           Delete archives older than 7 days
  sudo bash cleanup-backups.sh --preview List what would be deleted, do not delete

EOF
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$1'"
            echo "Hint: sudo bash cleanup-backups.sh --help"
            exit 2
            ;;
    esac
done

if [ "$PREVIEW" = true ]; then
    echo "Preview: archives older than $RETENTION_DAYS days that would be removed:"
    find "$BACKUP_DIR" -name '*.tar.gz' -mtime +"$RETENTION_DAYS" -print
    count=$(find "$BACKUP_DIR" -name '*.tar.gz' -mtime +"$RETENTION_DAYS" | wc -l)
    echo "Preview: would remove $count archive(s)."
else
    count=$(find "$BACKUP_DIR" -name '*.tar.gz' -mtime +"$RETENTION_DAYS" | wc -l)
    find "$BACKUP_DIR" -name '*.tar.gz' -mtime +"$RETENTION_DAYS" -delete
    echo "Cleanup: removed $count archive(s) older than $RETENTION_DAYS days."
fi
