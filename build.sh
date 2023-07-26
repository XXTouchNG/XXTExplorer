#!/bin/sh

set -e

BUILD_ROOT=$(git rev-parse --show-toplevel)

mkdir -p "$BUILD_ROOT/Releases"
SRC_DIR="$BUILD_ROOT/Releases/XXTExplorer.xcarchive"
DEST_DIR="$BUILD_ROOT/Releases/XXTExplorer"

pod install --verbose --no-repo-update
xcodebuild archive -workspace "$BUILD_ROOT/XXTExplorer.xcworkspace" -scheme "XXTExplorer-Archive" -archivePath "$DEST_DIR" GCC_PREPROCESSOR_DEFINITIONS="JB_PREFIX=\\\"$JB_PREFIX\\\" COCOAPODS=1 PMK_CALAYER=1 PMK_NSNOTIFICATIONCENTER=1 PMK_NSURLCONNECTION=1 PMK_PAUSE=1 PMK_UIACTIONSHEET=1 PMK_UIALERTVIEW=1 PMK_UIVIEW=1 PMK_UIVIEWCONTROLLER=1 PMK_UNTIL=1 PMK_WHEN=1 ARCHIVE=1" | xcpretty --color

cp ent.xml "$SRC_DIR/Products/Applications"/ent.xml
cd "$SRC_DIR/Products/Applications"
codesign --remove-signature XXTExplorer.app

if [ "$TARGET_CODESIGN" = "ldid" ]; then
    ldid -Sent.xml XXTExplorer.app/XXTExplorer
else
    codesign --entitlements ent.xml --deep --force --sign "$TARGET_CODESIGN_CERT" XXTExplorer.app
fi

cd "$BUILD_ROOT"
exit 0