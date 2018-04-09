#!/bin/sh

if [ $# != 2 ] ; then 
echo "Usage: ${0} PackageName DaemonVersion"
exit 1; 
fi 

PACKAGE_NAME="${1:-latest}"
DAEMON_VERSION="${2}"

SRC_DIR="Releases/${PACKAGE_NAME}.xcarchive"
DEST_DIR="Releases/${PACKAGE_NAME}"

echo "Update repository..."
git pull

echo "Update Cocoapods..."
pod update --verbose

# 0
echo "Update adapter..."
./adapter_encode.sh

# 1
echo "Bump version..."
./bump_version.sh "XXTExplorer-Archive" ${DAEMON_VERSION}

# 2
echo "Trigger build..."
xcodebuild archive -workspace "XXTExplorer.xcworkspace" -scheme "XXTExplorer-Archive" -archivePath "${DEST_DIR}" | xcpretty --color

# 3
echo "Trigger export..."
xcodebuild -exportArchive -archivePath "${SRC_DIR}" -exportPath "${DEST_DIR}" -exportOptionsPlist "DefaultExportOptions.plist" -allowProvisioningUpdates | xcpretty --color

# 4
echo "Upload symbols..."
./Libraries/BuglydSYMUploader/dSYMUpload.sh "abe3aa1f98" "d133a6f9-a23a-480c-a47a-e105191fd84c" "com.xxtouch.XXTExplorer" "${DAEMON_VERSION}" "${SRC_DIR}" "${DEST_DIR}" 1

# 5
echo "Succeed."
open Releases
