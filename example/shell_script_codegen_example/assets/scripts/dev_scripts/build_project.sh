#!/bin/bash

# Build Project Script
# Supports parameters: -e (environment), -c (clean)

ENVIRONMENT="development"
CLEAN=false

# Parse command line arguments
while getopts "e:c" opt; do
  case $opt in
    e)
      ENVIRONMENT="$OPTARG"
      ;;
    c)
      CLEAN=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo "🔨 Building Project"
echo "=================="
echo "🌍 Environment: $ENVIRONMENT"
echo "🧹 Clean build: $CLEAN"

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo ""
    echo "🧹 Cleaning project..."
    if [ -f "pubspec.yaml" ]; then
        dart clean
    elif [ -f "package.json" ]; then
        rm -rf node_modules
        rm -f package-lock.json
    else
        echo "   Performing generic clean..."
        rm -rf build/
        rm -rf dist/
        rm -rf .dart_tool/
    fi
fi

# Build based on environment
echo ""
echo "🏗️ Building for $ENVIRONMENT..."

case "$ENVIRONMENT" in
    "production")
        echo "   Optimizing for production..."
        if [ -f "pubspec.yaml" ]; then
            dart compile exe bin/main.dart -o build/app
        else
            echo "   Production build commands would go here"
        fi
        ;;
    "staging")
        echo "   Building for staging..."
        echo "   Staging build commands would go here"
        ;;
    "development")
        echo "   Building for development..."
        if [ -f "pubspec.yaml" ]; then
            dart pub get
        else
            echo "   Development build commands would go here"
        fi
        ;;
    *)
        echo "   Unknown environment: $ENVIRONMENT"
        echo "   Using default build..."
        ;;
esac

echo ""
echo "✅ Build completed for $ENVIRONMENT environment!"
