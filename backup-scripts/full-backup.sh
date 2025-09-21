#!/bin/bash

# Complete Application Backup Script
# Backs up MongoDB, application files, and Docker volumes

set -e

# Configuration
PROJECT_DIR="/home/elon/Desktop/LYBOOK"
BACKUP_ROOT="/home/elon/Desktop/LYBOOK/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "Starting full LYBOOK application backup..."

# 1. MongoDB Backup
echo "1. Backing up MongoDB..."
./mongodb-backup.sh

# 2. Application Files Backup
echo "2. Backing up application files..."
mkdir -p "$BACKUP_ROOT/app-files"
tar -czf "$BACKUP_ROOT/app-files/app_backup_$DATE.tar.gz" \
  --exclude="node_modules" \
  --exclude="backups" \
  --exclude="*.log" \
  -C "$PROJECT_DIR/.." \
  LYBOOK

# 3. Docker Volumes Backup
echo "3. Backing up Docker volumes..."
mkdir -p "$BACKUP_ROOT/volumes"

# Backup mongo volume
docker run --rm -v lybook_mongo_data:/data -v "$BACKUP_ROOT/volumes:/backup" \
  alpine tar -czf "/backup/mongo_volume_$DATE.tar.gz" -C /data .

# Backup other volumes
docker run --rm -v lybook_redis_data:/data -v "$BACKUP_ROOT/volumes:/backup" \
  alpine tar -czf "/backup/redis_volume_$DATE.tar.gz" -C /data .

# 4. Environment Configuration Backup
echo "4. Backing up environment files..."
mkdir -p "$BACKUP_ROOT/config"
cp "$PROJECT_DIR/.env.enhanced" "$BACKUP_ROOT/config/env_$DATE.backup" 2>/dev/null || true
cp "$PROJECT_DIR/.env.local" "$BACKUP_ROOT/config/env_local_$DATE.backup" 2>/dev/null || true

# 5. Create complete backup archive
echo "5. Creating complete backup archive..."
tar -czf "$BACKUP_ROOT/complete_backup_$DATE.tar.gz" \
  -C "$BACKUP_ROOT" \
  mongodb app-files volumes config

# Cleanup individual backups (keep the complete one)
rm -rf "$BACKUP_ROOT/app-files" "$BACKUP_ROOT/volumes" "$BACKUP_ROOT/config"

# Retention policy - keep last 5 complete backups
find "$BACKUP_ROOT" -name "complete_backup_*.tar.gz" -type f | sort | head -n -5 | xargs rm -f

echo "Full backup completed: complete_backup_$DATE.tar.gz"
echo "Backup location: $BACKUP_ROOT"
echo "Backup size: $(du -h "$BACKUP_ROOT/complete_backup_$DATE.tar.gz" | cut -f1)"