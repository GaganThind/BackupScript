#!/bin/bash

function usage {
    echo "Usage: ./$(basename $0) -t BACKUP_TYPE[daily/weekly/monthly] -s[Parent_Of_Directories_To_Sync] -d[Destination_Disk_Location]"
    exit 1
}

while getopts ':t:s:d:' opt; 
do
    case $opt in
        t) 
            TYPE=$OPTARG
            ;;
        s)
            HOME_DIR=$OPTARG
            ;;
        d)
            DEST_DIR=$OPTARG
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            usage $0
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $TYPE ]]; then
    echo "Please pass backup type" >&2
    usage $0
fi

ALLOWED_BACKUP_TYPES=("daily" "weekly" "monthly")
if ! [[ $(echo ${ALLOWED_BACKUP_TYPES[@]} | fgrep -w $TYPE) ]]; then
    echo "Incorrect BACKUP_TYPE passed" >&2
    usage $0
fi

echo "Home directory is: $HOME_DIR"
if [[ -z $HOME_DIR ]]; then
    echo "Please pass the home directory" >&2
    usage $0
fi

echo "Destination directory is: $DEST_DIR"
if [[ -z $DEST_DIR ]]; then
    echo "Please pass the destination directory" >&2
    usage $0
fi

START="$(date +%s)"

echo "Running Backup script for $TYPE at $(date)"
echo ""

################################################
########### Pre-Checks starts here #############
################################################

SOURCE_DISK_LOCATION="$HOME_DIR"
REGEX_FOLDER_DATE="[0-9]{4}-[0-9]{2}-?[0-9]{0,2}"

echo "Starting with pre-checks"
echo ""

SRC_LAPTOP="$SOURCE_DISK_LOCATION/Documents/"

if ! [[ -d $SRC_LAPTOP ]] || [[ -z "$(ls -A $SRC_LAPTOP)" ]]; then
    echo "$SRC_LAPTOP does not exist or is empty. Exiting..."
    exit 0;
fi

echo "$SRC_LAPTOP folder exists and contains files"
echo ""

SRC_PHONE="$SOURCE_DISK_LOCATION/Phone/Pixel-8"

if ! [[ -d $SRC_PHONE ]] || [[ -z "$(ls -A $SRC_PHONE)" ]]; then
    echo "$SRC_PHONE does not exist or is empty. Exiting..."
    exit 0;
fi

echo "$SRC_PHONE folder exists and contains files"
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
if [[ $TYPE == "daily" ]]; then
    BACKUP_TYPE_DIR="Daily"
    BACKUP_TYPE_DIR_NAME="$(date +%Y-%m-%d)" #%d-%m-%Y
elif [[ $TYPE == "weekly" ]]; then
    BACKUP_TYPE_DIR="Weekly"
    BACKUP_TYPE_DIR_NAME="$(date +%Y-%U)"
elif [[ $TYPE == "monthly" ]]; then
    BACKUP_TYPE_DIR="Monthly"
    BACKUP_TYPE_DIR_NAME="$(date +%Y-%m)"
fi

BACKUP_PHONE_MAIN_DIR="$BACKUP_DISK_LOCATION/Backups/Phone_Backups/$BACKUP_TYPE_DIR"
DEST_PHONE="$BACKUP_PHONE_MAIN_DIR/$BACKUP_TYPE_DIR_NAME/"
echo "Phone will be backed up at $DEST_PHONE"
echo ""

BACKUP_LAPTOP_MAIN_DIR="$BACKUP_DISK_LOCATION/Backups/Laptop_Backups/$BACKUP_TYPE_DIR"
DEST_LAPTOP="$BACKUP_LAPTOP_MAIN_DIR/$BACKUP_TYPE_DIR_NAME/"
echo "Laptop will be backed up at $DEST_LAPTOP"
echo ""

mkdir -p "$DEST_LAPTOP"
mkdir -p "$DEST_PHONE"

echo "Validated folder structure"
echo ""

echo "Starting the backup of Laptop and Phone"
echo ""

# Laptop
rsync -aAX --delete --exclude '*.Trash-1000' "$SRC_LAPTOP" "$DEST_LAPTOP"

# Phone
rsync -aAX --delete --exclude '*.Trash-1000' "$SRC_PHONE" "$DEST_PHONE"

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

if [[ $TYPE == "daily" ]]; then
    RETAIN=7
elif [[ $TYPE == "weekly" ]]; then
    RETAIN=4
elif [[ $TYPE == "monthly" ]]; then
    RETAIN=5
fi

echo "Retain threshold for $TYPE is $RETAIN"
echo ""

PHONE_BACKUP_COUNT=$(find "$BACKUP_PHONE_MAIN_DIR" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | grep -Eiw $REGEX_FOLDER_DATE | wc -l)

echo "Phone backups found: $PHONE_BACKUP_COUNT"
echo ""

if [[ $PHONE_BACKUP_COUNT -gt $RETAIN ]]; then
    find "$BACKUP_PHONE_MAIN_DIR" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | 
    grep -Eiw $REGEX_FOLDER_DATE | 
    sort -r | 
    tail -n +$(($RETAIN + 1)) | 
    while IFS= read line
    do
        echo "Deleting backup $line \n"
        rm -rf "$line"
    done
else 
    echo "No phone backup to be deleted"
fi

echo ""

LAPTOP_BACKUP_COUNT=$(find "$BACKUP_LAPTOP_MAIN_DIR" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | grep -Eiw $REGEX_FOLDER_DATE | wc -l)

echo "Laptop backups found: $LAPTOP_BACKUP_COUNT"
echo ""

if [[ $LAPTOP_BACKUP_COUNT -gt $RETAIN ]]; then
    find "$BACKUP_LAPTOP_MAIN_DIR" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | 
    grep -Eiw $REGEX_FOLDER_DATE | 
    sort -r | 
    tail -n +$(($RETAIN + 1)) | 
    while IFS= read line
    do
        echo "Deleting backup $line \n"
        rm -rf "$line"
    done
else 
    echo "No laptop backup to be deleted"
    echo ""
fi

DURATION=$[ $(date +%s) - ${START}]
echo "Time taken to run the script in seconds : $DURATION s"
echo ""
echo "Backup script completed"
