#!/bin/bash

function usage {
    echo "Usage: ./$(basename $0) [OPTION...]
    -t    type of backup to perform [daily/weekly/monthly]
    -h    help"
    exit 1
}

while getopts ':t:h' opt;
do
    case $opt in
        t) 
            BACK_TYPE_=$OPTARG
            ;;
        h)
            usage $0
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            usage $0
            ;;
    esac
done
shift $((OPTIND-1))

################################################
############## Required Argument ###############
################################################
if [[ -z $BACK_TYPE_ ]]; then
    echo "Required arguments not passed" >&2
    usage $0
fi

ALLOWED_BACKUP_TYPES_=("daily" "weekly" "monthly")
if ! [[ $(echo ${ALLOWED_BACKUP_TYPES_[@]} | fgrep -w $BACK_TYPE_) ]]; then
    echo "Incorrect BACKUP_TYPE passed" >&2
    usage $0
fi

################################################
########## Backup logic starts here ############
################################################

START_="$(date +%s)"

echo "DeviceBackup script - started at $(date)"
echo ""

# Copy Laptop and Phone data to backup directory except photos
SRC_LAPTOP_HOME="/home/$USER/Documents"
SRC_PHONE_HOME="/home/$USER/Phone/IPhone"
DEST="/media/Other_Backup"
LOGS="/home/$USER/Logs"

echo "Backup of laptop and phone started"
echo ""

Backup.sh -g laptop -t "$BACK_TYPE_" -e DCIM -s "$SRC_LAPTOP_HOME" -d "$DEST" > "$LOGS/Other_Backup_Logs_Laptop_$BACK_TYPE_.log"
Backup.sh -g phone -t "$BACK_TYPE_" -e DCIM -s "$SRC_PHONE_HOME" -d "$DEST" > "$LOGS/Other_Backup_Logs_Phone_$BACK_TYPE_.log"

echo "Backup of laptop and phone done"
echo ""

# Copy photos to different directory. We just want to copy all the photos.
if [[ $BACK_TYPE_ == "daily" ]]; then
    echo "Backup of phone photos started"
    echo ""

    SRC_PHONE_PHOTOS="$SRC_PHONE_HOME/DCIM"
    DEST_PHONE_PHOTOS="$DEST/Backups/IPhone_DCIM"
    rsync -aAX "$SRC_PHONE_PHOTOS" "$DEST_PHONE_PHOTOS"

    echo "Backup of phone photos done"
    echo ""
fi

echo "Sync Primary and Secondary Hardrive started"
echo ""

# Sync Second Hard Disk with Primary Hard Disk
SRC_SYNC="/media/Other_Backup"
DEST_SYNC="/media/BackUp/"
SyncHDs.sh -s "$SRC_SYNC" -d "$DEST_SYNC" > "$LOGS/SyncHDs.log"

echo "Sync Primary and Secondary Hardrive ended"

DURATION_=$[ $(date +%s) - ${START_}]
echo ""
echo "Time taken to run the script in seconds : $DURATION_ s"

echo ""
echo "DeviceBackup script - completed"