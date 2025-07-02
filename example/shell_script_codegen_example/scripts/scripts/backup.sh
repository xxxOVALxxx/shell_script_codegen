#!/bin/bash

# Backup Script
# Supports parameters: -s (source, required), -t (target, required), -c (compress)

SOURCE=""
TARGET=""
COMPRESS=false

# Parse command line arguments
while getopts "s:t:c" opt; do
  case $opt in
    s)
      SOURCE="$OPTARG"
      ;;
    t)
      TARGET="$OPTARG"
      ;;
    c)
      COMPRESS=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Validate parameters
if [ -z "$SOURCE" ]; then
    echo "Error: Source directory parameter (-s) is required"
    exit 1
fi

if [ -z "$TARGET" ]; then
    echo "Error: Target directory parameter (-t) is required"
    exit 1
fi

echo "=== Backup Script ==="
echo "Source: $SOURCE"
echo "Target: $TARGET"
echo "Compress: $COMPRESS"

# Check if source exists
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source directory $SOURCE does not exist"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET"

# Perform backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_$TIMESTAMP"

if [ "$COMPRESS" = true ]; then
    echo "Creating compressed backup..."
    tar -czf "$TARGET/${BACKUP_NAME}.tar.gz" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
    echo "Compressed backup created: $TARGET/${BACKUP_NAME}.tar.gz"
else
    echo "Creating uncompressed backup..."
    cp -r "$SOURCE" "$TARGET/$BACKUP_NAME"
    echo "Backup created: $TARGET/$BACKUP_NAME"
fi

echo "Backup completed successfully!"