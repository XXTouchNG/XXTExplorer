#!/bin/sh

set -e

BUILD_ROOT=$(git rev-parse --show-toplevel)
PACKAGE_NAME="${1:-XXTExplorer}"

SRC_DIR="${BUILD_ROOT}/Releases/${PACKAGE_NAME}.xcarchive"
DEST_DIR="${BUILD_ROOT}/Releases/${PACKAGE_NAME}"

echo "install pods..."
pod install --verbose --no-repo-update

echo "trigger build..."
xcodebuild archive -workspace "${BUILD_ROOT}/XXTExplorer.xcworkspace" -scheme "XXTExplorer-Archive" -archivePath "${DEST_DIR}" | xcpretty --color

echo "trigger export..."
xcodebuild -exportArchive -archivePath "${SRC_DIR}" -exportPath "${DEST_DIR}" -exportOptionsPlist "DefaultExportOptions.plist" -allowProvisioningUpdates | xcpretty --color

cp ent.xml "${SRC_DIR}/Products/Applications"/ent.xml
cd "${SRC_DIR}/Products/Applications"
codesign --remove-signature XXTExplorer.app
rm -r XXTExplorer.app/_CodeSignature
rm XXTExplorer.app/embedded.mobileprovision
if [ "${TARGET_CODESIGN}" = "ldid" ]
then
    ldid -Sent.xml XXTExplorer.app/XXTExplorer
else
    codesign --entitlements ent.xml --deep --force --sign "${TARGET_CODESIGN_CERT}" XXTExplorer.app
fi

echo "succeed."
cd "${BUILD_ROOT}"
exit 0
