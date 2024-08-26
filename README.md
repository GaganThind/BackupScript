**Usage:**
```
./DeviceBackup.sh [OPTION...]
    -t    type of backup to perform [daily/weekly/monthly]
    -h    help
```
```
./Backup.sh [OPTION...]
    -n    unique name of the device to backup
    -t    type of backup to perform [daily/weekly/monthly]
    -s    parent folder/directory to sync. All the child folders/directories would be synched
    -d    destination backup folder/directory. All backups would be placed inside this in a structure
    -f    number of backups to retian before auto-deletion
    -e    exclude these files/folders from backup [comma seperated list]
    -i    only backup these files/folders [comma seperated list]
    -h    help
```
```
./SyncHDs.sh [OPTION...]
    -s    Source Hard Disk
    -d    Destination Hard Disk
    -h    help
```

**Example:**
```
./Backup.sh -n I-Phone -t weekly -s ~/Documents/Test/src/ -d ~/Documents/Test/dest/ -f 3 -e 1,3,6
```