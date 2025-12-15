#!/bin/bash

APP_NAME="YMusicSpectrogram"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST_SRC="YMusicSpectrogram/Resources/Info.plist"
INFO_PLIST_DEST="$CONTENTS_DIR/Info.plist"

echo "Creating $APP_NAME.app..."

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Process Info.plist
sed -e "s/\$(EXECUTABLE_NAME)/$APP_NAME/" \
    -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.yixi.$APP_NAME/" \
    -e "s/\$(PRODUCT_NAME)/$APP_NAME/" \
    -e "s/\$(MACOSX_DEPLOYMENT_TARGET)/13.0/" \
    "$INFO_PLIST_SRC" > "$INFO_PLIST_DEST"

# Set executable permissions
chmod +x "$MACOS_DIR/$APP_NAME"

echo "App bundle created at $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
