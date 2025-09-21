#!/bin/bash

# MongoDB Backup Script
# Usage: ./mongodb-backup.sh

set -e

# Configuration
BACKUP_DIR="/home/elon/Desktop/LYBOOK/backups/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_DB="library"
MONGO_USER="mongo_user"
MONGO_PASS="mongo_password"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting MongoDB backup..."

# Create database dump
mongodump \
  --host "$MONGO_HOST:$MONGO_PORT" \
  --db "$MONGO_DB" \
  --username "$MONGO_USER" \
  --password "$MONGO_PASS" \
  --authenticationDatabase "admin" \
  --out "$BACKUP_DIR/dump_$DATE"

# Compress the backup
tar -czf "$BACKUP_DIR/mongodb_backup_$DATE.tar.gz" -C "$BACKUP_DIR" "dump_$DATE"

# Remove uncompressed dump
rm -rf "$BACKUP_DIR/dump_$DATE"

# Keep only last 7 backups
find "$BACKUP_DIR" -name "mongodb_backup_*.tar.gz" -type f -mtime +7 -delete

echo "MongoDB backup completed: mongodb_backup_$DATE.tar.gz"
echo "Backup size: $(du -h "$BACKUP_DIR/mongodb_backup_$DATE.tar.gz" | cut -f1)"