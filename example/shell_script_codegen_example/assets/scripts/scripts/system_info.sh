#!/bin/bash

# System Information Script
# Supports parameters: -v (verbose), -f (format)

# Default values
VERBOSE=false
FORMAT="plain"

# Parse command line arguments using getopts
while getopts "vf:" opt; do
  case $opt in
    v)
      VERBOSE=true
      ;;
    f)
      FORMAT="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo "=== System Information ==="

if [ "$VERBOSE" = true ]; then
    echo "Verbose mode: ON"
    echo "Output format: $FORMAT"
    echo "------------------------"
fi

case "$FORMAT" in
    "json")
        echo "{"
        echo "  \"hostname\": \"$(hostname)\","
        echo "  \"user\": \"$(whoami)\","
        echo "  \"date\": \"$(date)\","
        echo "  \"uptime\": \"$(uptime | awk '{print $3}' | sed 's/,//')\","
        echo "  \"disk_usage\": \"$(df -h / | awk 'NR==2{print $5}')\""
        echo "}"
        ;;
    "xml")
        echo "<system>"
        echo "  <hostname>$(hostname)</hostname>"
        echo "  <user>$(whoami)</user>"
        echo "  <date>$(date)</date>"
        echo "  <uptime>$(uptime | awk '{print $3}' | sed 's/,//')</uptime>"
        echo "  <disk_usage>$(df -h / | awk 'NR==2{print $5}')</disk_usage>"
        echo "</system>"
        ;;
    *)
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Date: $(date)"
        echo "Uptime: $(uptime | awk '{print $3}' | sed 's/,//')"
        echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
        ;;
esac

if [ "$VERBOSE" = true ]; then
    echo "------------------------"
    echo "Memory Usage:"
    free -h
    echo "------------------------"
    echo "CPU Info:"
    lscpu | head -5
fi
