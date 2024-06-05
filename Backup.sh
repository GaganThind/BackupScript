#!/bin/bash

function usage {
    echo "Usage: ./$(basename $0) [OPTION...]
    -g    type of device to backup [laptop/phone/desktop]
    -t    type of backup to perform [daily/weekly/monthly]
    -s    parent folder/directory to sync. All the child folders/directories would be synched
    -d    destination backup folder/directory. All backups would be placed inside this in a structure
    -f    number of backups to retian before auto-deletion
    -h    help"
    exit 1
}

while getopts ':t:s:d:g:f:h' opt;
do
    case $opt in
        t) 
            BACK_TYPE=$OPTARG
            ;;
        s)
            HOME_DIR=$OPTARG
            ;;
        d)
            DEST_DIR=$OPTARG
            ;;
        g)
            DEVICE_TYPE=$OPTARG
            ;;
        f)
            RETAIN=$OPTARG
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

ALLOWED_DEVICE_TYPE=("laptop" "phone" "desktop")
if [[ -z $DEVICE_TYPE ]] || [[ -z $BACK_TYPE ]] || [[ -z $HOME_DIR ]] || [[ -z $DEST_DIR ]]; then
    echo "Required arguments not passed" >&2
    usage $0
fi

if ! [[ $(echo ${ALLOWED_DEVICE_TYPE[@]} | fgrep -w $DEVICE_TYPE) ]]; then
    echo "Incorrect DEVICE_TYPE passed" >&2
    usage $0
fi

ALLOWED_BACKUP_TYPES=("daily" "weekly" "monthly")
if ! [[ $(echo ${ALLOWED_BACKUP_TYPES[@]} | fgrep -w $BACK_TYPE) ]]; then
    echo "Incorrect BACKUP_TYPE passed" >&2
    usage $0
fi

if ! [[ -z $RETAIN ]] && ! [[ $RETAIN =~ ^[0-9]+$ ]]; then
    echo "Incorrect FREQUENCY passed. It should be a number." >&2
    usage $0
fi

echo "Home directory is: $HOME_DIR"
echo "Destination directory is: $DEST_DIR"

START="$(date +%s)"

echo "Running Backup script for $BACK_TYPE at $(date)"
echo ""

################################################
################# CONSTANTS ####################
################################################
REGEX_FOLDER_DATE="[0-9]{4}-[0-9]{2}-?[0-9]{0,2}"

if [[ -z $RETAIN ]]; then
    if [[ $BACK_TYPE == "daily" ]]; then
        RETAIN=7
    elif [[ $BACK_TYPE == "weekly" ]]; then
        RETAIN=4
    elif [[ $BACK_TYPE == "monthly" ]]; then
        RETAIN=5
    fi
fi

################################################
########### Pre-Checks starts here #############
################################################

echo "Starting with pre-checks"
echo ""

# If the provided Source does not end with slash (/), then append it with slash (/)
SOURCE_DISK_LOCATION=$(echo "$HOME_DIR" | sed '/\/$/! s|$|/|')

if ! [[ -d $SOURCE_DISK_LOCATION ]] || [[ -z "$(ls -A $SOURCE_DISK_LOCATION)" ]]; then
    echo "$SOURCE_DISK_LOCATION does not exist or is empty. Exiting..."
    exit 0;
fi

echo "$SOURCE_DISK_LOCATION folder exists and contains files"
echo ""

BACKUP_DISK_LOCATION="$DEST_DIR"

if ! [[ -d $BACKUP_DISK_LOCATION ]]; then
    echo "$BACKUP_DISK_LOCATION does not exist. Exiting..."
    exit 0;
fi

echo "$BACKUP_DISK_LOCATION exists and will be used for backing up data"
echo ""

################################################
############ Pre-Checks ends here ##############
################################################

################################################
########## Backup logic starts here ############
################################################

echo "Checking Backup folder structure"
echo ""

BACKUP_TYPE_DIR=""
BACKUP_TYPE_DIR_NAME=""
if [[ $BACK_TYPE == "daily" ]]; then
    BACKUP_TYPE_DIR="Daily"
    BACKUP_TYPE_DIR_NAME="$(date +%Y-%m-%d)"
elif [[ $BACK_TYPE == "weekly" ]]; then
    BACKUP_TYPE_DIR="Weekly"
    BACKUP_TYPE_DIR_NAME="$(date +%Y-%U)"
elif [[ $BACK_TYPE == "monthly" ]]; then
    BACKUP_TYPE_DIR="Monthly"
    BACKUP_TYPE_DIR_NAME="$(date +%Y-%m)"
fi

BACKUP_MAIN_DIR="$BACKUP_DISK_LOCATION/Backups/$DEVICE_TYPE/$BACKUP_TYPE_DIR"
DEST_DEVICE="$BACKUP_MAIN_DIR/$BACKUP_TYPE_DIR_NAME/"
echo "$DEVICE_TYPE will be backed up at $DEST_DEVICE"
echo ""

mkdir -p "$DEST_DEVICE"

echo "Validated folder structure"
echo ""

echo "Starting the backup of $DEVICE_TYPE"
echo ""

rsync -aAX --delete --exclude '*.Trash-1000' "$SOURCE_DISK_LOCATION" "$DEST_DEVICE"

echo "Backup completed"
echo ""

################################################
########### Backup logic ends here #############
################################################

################################################
########## Old backup deletion logic ###########
################################################

echo "Starting with old backup deletion"
echo ""

echo "Retain threshold for $BACK_TYPE is $RETAIN"
echo ""

BACKUP_COUNT=$(find "$BACKUP_MAIN_DIR" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | grep -Eiw $REGEX_FOLDER_DATE | wc -l)

echo "$DEVICE_TYPE backups found: $BACKUP_COUNT"
echo ""

if [[ $BACKUP_COUNT -gt $RETAIN ]]; then
    find "$BACKUP_MAIN_DIR" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | 
    grep -Eiw $REGEX_FOLDER_DATE | 
    sort -r | 
    tail -n +$(($RETAIN + 1)) | 
    while IFS= read line
    do
        echo "Deleting backup $line \n"
        rm -rf "$line"
    done
else 
    echo "No $DEVICE_TYPE backup to be deleted"
    echo ""
fi

DURATION=$[ $(date +%s) - ${START}]
echo ""
echo "Time taken to run the script in seconds : $DURATION s"
echo ""
echo "Backup script completed"
