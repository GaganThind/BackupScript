#!/bin/bash

function usage {
    echo "Usage: ./$(basename $0) -t BACKUP_TYPE[daily/weekly/monthly]"
    exit 1
}

while getopts t: opt 
do
    case "$opt" in
        t) 
            TYPE=$OPTARG
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            usage $0
            ;;
    esac
    shift
done

if [[ -z $TYPE ]]; then
    echo "No argument passed" >&2
    usage $0
fi

ALLOWED_BACKUP_TYPES=("daily" "weekly" "monthly")
if ! [[ $(echo ${ALLOWED_BACKUP_TYPES[@]} | fgrep -w $TYPE) ]]; then
    echo "Incorrect BACKUP_TYPE passed" >&2
    usage $0
fi

echo "Running Backup script"
echo ""

# Common Variables
USER_LOCAL="chieftain"
HOME_DIR="/home/$USER_LOCAL"

BACKUP_DISK_LOCATION="/media/$USER_LOCAL/Other_Backup"
BACKUP_FOLDER="$BACKUP_DISK_LOCATION/Backups"

# Laptop Variables
SRC_LAPTOP="$HOME_DIR/Documents/"
DEST_LAPTOP="$BACKUP_FOLDER/Laptop_Backups"

# Oneplus Variables
SRC_PHONE_ONEPLUS="$HOME_DIR/OnePlus/"
DEST_PHONE_ONEPLUS="$BACKUP_FOLDER/Phone_Backups"

echo "Starting with pre-checks"
echo ""

# Pre-Checks
if ! [[ -d $SRC_LAPTOP ]] || [[ -z "$(ls -A $SRC_LAPTOP)" ]]; then
    echo "$SRC_LAPTOP does not exist or is empty. Exiting..."
    exit 0;
fi

echo "$SRC_LAPTOP folder exists and contains files"
echo ""

if ! [[ -d $SRC_PHONE_ONEPLUS ]] || [[ -z "$(ls -A $SRC_PHONE_ONEPLUS)" ]]; then
    echo "$SRC_PHONE_ONEPLUS does not exist or is empty. Exiting..."
    exit 0;
fi

echo "$SRC_PHONE_ONEPLUS folder exists and contains files"
echo ""

if ! [[ -d $BACKUP_DISK_LOCATION ]]; then
    echo "$BACKUP_DISK_LOCATION does not exist. Exiting..."
    exit 0;
fi

echo "$BACKUP_DISK_LOCATION exists and will be used for backing up data"
echo ""

echo "Checking Backup folder structure"
echo ""

INNER_FOLDER=""
if [[ $TYPE == "daily" ]]; then
    INNER_FOLDER="Daily/$(date +%d-%m-%Y)/"
elif [[ $TYPE == "weekly" ]]; then
    INNER_FOLDER="Weekly/$(date +%U-%Y)/"
elif [[ $TYPE == "monthly" ]]; then
    INNER_FOLDER="Monthly/$(date +%m-%Y)/"
fi

mkdir -p "$DEST_LAPTOP/$INNER_FOLDER"
mkdir -p "$DEST_PHONE_ONEPLUS/$INNER_FOLDER"

echo "Validated folder structure"
echo ""

# Laptop
rsync -aAX --delete --exclude '*.Trash-1000' "$SRC_LAPTOP" "$DEST_LAPTOP/$INNER_FOLDER/"

# Phone
rsync -aAX --delete --exclude '*.Trash-1000' "$SRC_PHONE_ONEPLUS" "$DEST_PHONE_ONEPLUS/$INNER_FOLDER"

echo "Backup script completed"
