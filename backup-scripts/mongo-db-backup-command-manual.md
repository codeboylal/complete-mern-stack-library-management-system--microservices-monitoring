# MongoDB Backup & Restore Manual

## 1. Backup Process

**Goal:** Create a compressed backup (`.tar.gz`) of your `library` database.

**Run Backup Script:**
```bash
cd ~/Desktop/LYBOOK
./mongodb-backup.sh
```

**Backup will be stored in:**
```
~/Desktop/LYBOOK/backups/mongodb
```

**Example backup file:**
```
mongodb_backup_20250921_163821.tar.gz
```

---

## 2. Restore Process

**Goal:** Restore the database from a compressed backup file.

### Step 1: Navigate to Backup Folder
```bash
cd ~/Desktop/LYBOOK/backups/mongodb
ls
```
**Example output:**
```
mongodb_backup_20250921_163821.tar.gz
```

### Step 2: Drop the Old Database *(Optional but Recommended)*
```bash
mongo --host localhost --port 27017 \
    -u mongo_user -p mongo_password --authenticationDatabase admin \
    --eval "db.getSiblingDB('library').dropDatabase()"
```
*Ensures a clean restore without duplicate/conflicting data.*

### Step 3: Extract the Backup
```bash
tar -xzf mongodb_backup_20250921_163821.tar.gz -C /tmp
```
**Extracted folder example:**
```
/tmp/dump_20250921_163821/library/books.bson
/tmp/dump_20250921_163821/library/books.metadata.json
```

### Step 4: Restore the Database
```bash
mongorestore --host localhost:27017 \
    --username mongo_user --password mongo_password \
    --authenticationDatabase admin \
    /tmp/dump_20250921_163821
```
**Expected Output:**
```
restoring library.books from /tmp/dump_20250921_163821/library/books.bson
finished restoring library.books (27 documents)
done
```

### Step 5: Verify Restoration
```bash
mongo --host localhost --port 27017 \
    -u mongo_user -p mongo_password --authenticationDatabase admin
```
**Inside Mongo shell:**
```javascript
use library
show collections
db.books.countDocuments()     // Should match original count
db.books.find().pretty()      // Verify data integrity
exit
```

### Step 6: Cleanup *(Optional)*
```bash
rm -rf /tmp/dump_20250921_163821
```

---

## Quick Commands Summary

| Action           | Command                                                                                                                                      |
|------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| Run backup       | `./mongodb-backup.sh`                                                                                                                       |
| Drop database    | `mongo --host localhost --port 27017 -u mongo_user -p mongo_password --authenticationDatabase admin --eval "db.getSiblingDB('library').dropDatabase()"` |
| Extract backup   | `tar -xzf mongodb_backup_<DATE>.tar.gz -C /tmp`                                                                                             |
| Restore database | `mongorestore --host localhost:27017 -u mongo_user -p mongo_password --authenticationDatabase admin /tmp/dump_<DATE>`                       |
| Verify restore   | `mongo --host localhost --port 27017 -u mongo_user -p mongo_password --authenticationDatabase admin --eval "db.getSiblingDB('library').books.countDocuments()"` |

---

## Folder Paths

- **Backup Script:** `~/Desktop/LYBOOK/mongodb-backup.sh`
- **Backup Storage:** `~/Desktop/LYBOOK/backups/mongodb`
- **Extracted Temp Folder:** `/tmp/dump_<DATE>`

---

## Tips

- Schedule automatic backups with cron:
    ```bash
    crontab -e
    ```
    **Example:** Run every day at 2 AM
    ```
    0 2 * * * /home/elon/Desktop/LYBOOK/mongodb-backup.sh >> /home/elon/Desktop/LYBOOK/backups/mongodb/backup.log 2>&1
    ```

- Always verify restoration after backups to ensure data integrity.
- Keep at least last 5–7 backups for safety.

---

## In Short

- **Backup:** Run `./mongodb-backup.sh` → produces `.tar.gz` file.
- **Restore:** Extract → `mongorestore` → Verify → Cleanup. ✅