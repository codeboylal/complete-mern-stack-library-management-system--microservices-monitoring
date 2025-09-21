#!/bin/bash

# Automated Backup Setup for LYBOOK
# This script sets up automated backups using cron

SCRIPT_DIR="/home/elon/Desktop/LYBOOK/backup-scripts"
CRON_FILE="/tmp/lybook_cron"

echo "Setting up automated backups for LYBOOK..."

# Create cron jobs
cat > "$CRON_FILE" << EOF
# LYBOOK Automated Backups
# Daily MongoDB backup at 2 AM
0 2 * * * cd $SCRIPT_DIR && ./mongodb-backup.sh >> /var/log/lybook-backup.log 2>&1

# Weekly full backup on Sundays at 3 AM
0 3 * * 0 cd $SCRIPT_DIR && ./full-backup.sh >> /var/log/lybook-backup.log 2>&1

# Monthly backup cleanup (first day of month at 4 AM)
0 4 1 * * find /home/elon/Desktop/LYBOOK/backups -name "*.tar.gz" -type f -mtime +30 -delete >> /var/log/lybook-backup.log 2>&1
EOF

# Install cron jobs
crontab "$CRON_FILE"
rm "$CRON_FILE"

# Create log file
sudo touch /var/log/lybook-backup.log
sudo chown $USER:$USER /var/log/lybook-backup.log

echo "Automated backup schedule installed:"
echo "- Daily MongoDB backup: 2:00 AM"
echo "- Weekly full backup: Sunday 3:00 AM"
echo "- Monthly cleanup: 1st day 4:00 AM"
echo ""
echo "View logs: tail -f /var/log/lybook-backup.log"
echo "View cron jobs: crontab -l"