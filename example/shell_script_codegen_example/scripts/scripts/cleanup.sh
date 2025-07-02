#!/bin/bash

# Cleanup Script
# Supports parameters: -d (directory, required), -r (recursive)

DIRECTORY=""
RECURSIVE=false

# Parse command line arguments
while getopts "d:r" opt; do
  case $opt in
    d)
      DIRECTORY="$OPTARG"
      ;;
    r)
      RECURSIVE=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Check if directory is provided
if [ -z "$DIRECTORY" ]; then
    echo "Error: Directory parameter (-d) is required"
    exit 1
fi

echo "=== Cleanup Script ==="
echo "Target directory: $DIRECTORY"
echo "Recursive: $RECURSIVE"

# Check if directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Warning: Directory $DIRECTORY does not exist"
    exit 0
fi

# Perform cleanup
if [ "$RECURSIVE" = true ]; then
    echo "Performing recursive cleanup..."
    find "$DIRECTORY" -name "*.tmp" -type f -delete
    find "$DIRECTORY" -name "*.log" -type f -delete
    find "$DIRECTORY" -name "*.cache" -type f -delete
    find "$DIRECTORY" -empty -type d -delete
else
    echo "Performing non-recursive cleanup..."
    rm -f "$DIRECTORY"/*.tmp
    rm -f "$DIRECTORY"/*.log
    rm -f "$DIRECTORY"/*.cache
fi

echo "Cleanup completed for: $DIRECTORY"