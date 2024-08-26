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
USER_="<USER>"
DEST="/media/Other_Backup"
LOGS="/home/$USER_/Logs"

if ! [[ -d "$DEST" ]]; then
    echo "$DEST does not exist or is empty. Exiting..."
    exit 0;
fi

SRC_LAPTOP_HOME="/home/$USER_/Documents"

echo "Backup of laptop started"
echo ""
/opt/Scripts/Backup.sh -n laptop -t "$BACK_TYPE_" -s "$SRC_LAPTOP_HOME" -d "$DEST" > "$LOGS/Other_Backup_Logs_Laptop_$BACK_TYPE_.log"
echo "Backup of laptop done"
echo ""

SRC_PHONE_HOME="/home/$USER_/Phone"
PHONE_1="I-Phone"

echo "Backup of phone(s) started"
echo ""
echo "Backup of $PHONE_1 started"
echo ""

/opt/Scripts/Backup.sh -n $PHONE_1 -t "$BACK_TYPE_" -e DCIM,com.whatsapp -s "$SRC_PHONE_HOME/$PHONE_1" -d "$DEST" > "$LOGS/Other_Backup_Logs_$PHONE_1$BACK_TYPE_.log"

# Copy photos to different directory. We just want to copy all the photos.
if [[ $BACK_TYPE_ == "daily" ]]; then
    echo "Backup of $PHONE_1 photos started"
    echo ""
    rsync -aAX --include 'DCIM' --include 'com.whatsapp' --exclude="*" "$SRC_PHONE_HOME/$PHONE_1" "$DEST/Backups" >> "$LOGS/Other_Backup_Logs_$PHONE_1$BACK_TYPE_.log"
    echo "Backup of $PHONE_1 photos done"
    echo ""
fi
echo "Backup of $PHONE_1 done"
echo ""

echo "Backup of phone(s) done"
echo ""

echo "Sync Primary and Secondary Hardrive started"
echo ""

# Sync Second Hard Disk with Primary Hard Disk
SRC_SYNC="/media/Other_Backup"
DEST_SYNC="/media/OldBackup/"

if ! [[ -d "$DEST_SYNC" ]]; then
    echo "$DEST_SYNC does not exist or is empty. Exiting..."
    exit 0;
fi

/opt/Scripts/SyncHDs.sh -s "$SRC_SYNC" -d "$DEST_SYNC" > "$LOGS/SyncHDs.log"

echo "Sync Primary and Secondary Hardrive ended"

DURATION_=$[ $(date +%s) - ${START_}]
echo ""
echo "Time taken to run the script in seconds : $DURATION_ s"

echo ""
echo "DeviceBackup script - completed"