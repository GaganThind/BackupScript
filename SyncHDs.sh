#!/bin/bash

function usage {
    echo "Usage: ./$(basename $0) [OPTION...]
    -s    Source Hard Disk
    -d    Destination Hard Disk
    -h    help"
    exit 1
}

while getopts ':s:d:h' opt; 
do
    case $opt in
        s)
            SRC=$OPTARG
            ;;
        d)
            DEST=$OPTARG
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

if [[ -z $SRC ]] || [[ -z $DEST ]]; then
    echo "Invalid Usage of script" >&2
    usage $0
fi

# If the provided Source does not end with slash (/), then append it with slash (/)
SOURCE=$(echo "$SRC" | sed '/\/$/! s|$|/|')

rsync -ahvAE --delete --delete-excluded --exclude '*.Trash-1000' --exclude 'lost+found' --stats "$SOURCE" "$DEST"
