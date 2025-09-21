#!/bin/bash

# Restore Script for LYBOOK Application
# Usage: ./restore.sh <backup_file>

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 /path/to/complete_backup_20241201_143022.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="/tmp/lybook_restore_$(date +%s)"
PROJECT_DIR="/home/elon/Desktop/LYBOOK"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Starting LYBOOK application restore..."
echo "Backup file: $BACKUP_FILE"

# Create temporary restore directory
mkdir -p "$RESTORE_DIR"

# Extract backup
echo "1. Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# Stop running containers
echo "2. Stopping running containers..."
cd "$PROJECT_DIR"
docker-compose down

# Restore MongoDB
echo "3. Restoring MongoDB..."
if [ -d "$RESTORE_DIR/mongodb" ]; then
    MONGO_BACKUP=$(find "$RESTORE_DIR/mongodb" -name "mongodb_backup_*.tar.gz" | head -1)
    if [ -n "$MONGO_BACKUP" ]; then
        tar -xzf "$MONGO_BACKUP" -C "$RESTORE_DIR"
        DUMP_DIR=$(find "$RESTORE_DIR" -name "dump_*" -type d | head -1)
        
        # Start only MongoDB container
        docker-compose up -d mongo
        sleep 10
        
        # Restore database
        mongorestore \
          --host localhost:27017 \
          --username mongo_user \
          --password mongo_password \
          --authenticationDatabase admin \
          --drop \
          "$DUMP_DIR"
    fi
fi

# Restore Docker volumes
echo "4. Restoring Docker volumes..."
if [ -d "$RESTORE_DIR/volumes" ]; then
    # Restore mongo volume
    MONGO_VOL=$(find "$RESTORE_DIR/volumes" -name "mongo_volume_*.tar.gz" | head -1)
    if [ -n "$MONGO_VOL" ]; then
        docker run --rm -v lybook_mongo_data:/data -v "$RESTORE_DIR/volumes:/backup" \
          alpine sh -c "cd /data && tar -xzf /backup/$(basename "$MONGO_VOL")"
    fi
    
    # Restore redis volume
    REDIS_VOL=$(find "$RESTORE_DIR/volumes" -name "redis_volume_*.tar.gz" | head -1)
    if [ -n "$REDIS_VOL" ]; then
        docker run --rm -v lybook_redis_data:/data -v "$RESTORE_DIR/volumes:/backup" \
          alpine sh -c "cd /data && tar -xzf /backup/$(basename "$REDIS_VOL")"
    fi
fi

# Restore application files (optional - be careful)
echo "5. Application files found in backup (manual restore recommended)"
if [ -d "$RESTORE_DIR/app-files" ]; then
    echo "   App backup available at: $RESTORE_DIR/app-files/"
    echo "   Extract manually if needed: tar -xzf app_backup_*.tar.gz"
fi

# Restore configuration
echo "6. Restoring configuration files..."
if [ -d "$RESTORE_DIR/config" ]; then
    cp "$RESTORE_DIR/config"/env_*.backup "$PROJECT_DIR/.env.restored" 2>/dev/null || true
    echo "   Environment files restored as .env.restored"
fi

# Start all services
echo "7. Starting all services..."
docker-compose up -d

# Cleanup
echo "8. Cleaning up..."
rm -rf "$RESTORE_DIR"

echo "Restore completed successfully!"
echo "Please verify your application is working correctly."