**Usage:**
```
./Backup.sh [OPTION...]
    -g    type of device to backup [laptop/phone/desktop]
    -t    type of backup to perform [daily/weekly/monthly]
    -s    parent folder/directory to sync. All the child folders/directories would be synched
    -d    destination backup folder/directory. All backups would be placed inside this in a structure
    -f    number of backups to retain before auto-deletion
    -h    help
```

**Example:**
```
./Backup.sh -g desktop -t weekly -s ~/Documents/Test/src/ -d ~/Documents/Test/dest/ -f 3
```