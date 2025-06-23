#!/bin/bash

# Script to copy Flutter framework to the correct location for simulator builds
# This fixes the "Framework 'Flutter' not found" error

set -e

# Get the Flutter root path
FLUTTER_ROOT=$(flutter --version --machine | python3 -c "import sys, json; print(json.load(sys.stdin)['flutterRoot'])")

# Source framework path
SOURCE_FRAMEWORK="$FLUTTER_ROOT/bin/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework"

# Find the DerivedData directory for this project
DERIVED_DATA_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "Runner-*" -type d | head -1)

if [ -n "$DERIVED_DATA_DIR" ]; then
    TARGET_DIR="$DERIVED_DATA_DIR/Build/Products/Debug-iphonesimulator/Flutter"
    
    # Create target directory if it doesn't exist
    mkdir -p "$TARGET_DIR"
    
    # Copy Flutter framework if it doesn't exist
    if [ ! -d "$TARGET_DIR/Flutter.framework" ]; then
        echo "Copying Flutter framework to $TARGET_DIR"
        cp -R "$SOURCE_FRAMEWORK" "$TARGET_DIR/"
        echo "Flutter framework copied successfully"
    else
        echo "Flutter framework already exists in $TARGET_DIR"
    fi
else
    echo "DerivedData directory not found. Build the project first."
fi
