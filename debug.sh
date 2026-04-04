#!/bin/bash

APP_NAME="YMusicSpectrogram"
# Default swift build directory for debug
BUILD_DIR=".build/debug"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST_SRC="YMusicSpectrogram/Resources/Info.plist"
INFO_PLIST_DEST="$CONTENTS_DIR/Info.plist"

echo "Building $APP_NAME (Debug)..."
swift build

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

echo "Creating $APP_NAME.app (Debug)..."

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

# Copy app icon
ICON_SRC="YMusicSpectrogram/Resources/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$RESOURCES_DIR/"
fi

# Set executable permissions
chmod +x "$MACOS_DIR/$APP_NAME"

echo "Launching $APP_NAME..."
# Run the app directly to see logs in terminal
"$MACOS_DIR/$APP_NAME"
