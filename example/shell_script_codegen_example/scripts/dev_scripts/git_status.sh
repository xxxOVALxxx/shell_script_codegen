#!/bin/bash

# Git Status Script
# Supports parameters: -b (branch info)

SHOW_BRANCH=false

# Parse command line arguments
while getopts "b" opt; do
  case $opt in
    b)
      SHOW_BRANCH=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo "📋 Git Repository Status"
echo "======================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not a git repository"
    exit 1
fi

# Show branch information if requested
if [ "$SHOW_BRANCH" = true ]; then
    echo "🌿 Branch Information:"
    echo "   Current branch: $(git branch --show-current)"
    echo "   All branches:"
    git branch -a | sed 's/^/   /'
    echo ""
fi

# Show status
echo "📊 Repository Status:"
git status --short

# Show recent commits
echo ""
echo "📜 Recent Commits:"
git log --oneline -5