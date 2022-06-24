#!/bin/sh

if [ $# != 2 ] ; then 
echo "Usage: ${0} PackageName DaemonVersion"
exit 1; 
fi 

PACKAGE_NAME="${1:-latest}"
DAEMON_VERSION="${2}"
# BRANCH_NAME=`git symbolic-ref --short -q HEAD`

SRC_DIR="Releases/${PACKAGE_NAME}.xcarchive"
DEST_DIR="Releases/${PACKAGE_NAME}"

# echo "Current branch: ${BRANCH_NAME}"
# echo "Update repository..."
# git pull
# if [ $? != 0 ] ; then
#     exit 1
# fi

# echo "Update Cocoapods..."
# pod update --verbose
# if [ $? != 0 ] ; then
#     exit 1
# fi

# 0
# echo "Update adapter..."
# ./adapter_encode.sh
# if [ $? != 0 ] ; then
#     exit 1
# fi

# 1
echo "Trigger build..."
xcodebuild archive -workspace "XXTExplorer.xcworkspace" -scheme "XXTExplorer-Archive" -archivePath "${DEST_DIR}" | xcpretty --color
if [ $? != 0 ] ; then
    exit 1
fi

# 2
echo "Trigger export..."
xcodebuild -exportArchive -archivePath "${SRC_DIR}" -exportPath "${DEST_DIR}" -exportOptionsPlist "DefaultExportOptions.plist" -allowProvisioningUpdates | xcpretty --color
if [ $? != 0 ] ; then
    exit 1
fi

# 3
# echo "Upload symbols..."
# ./Libraries/BuglydSYMUploader/dSYMUpload.sh "abe3aa1f98" "d133a6f9-a23a-480c-a47a-e105191fd84c" "com.xxtouch.XXTExplorer" "${DAEMON_VERSION}" "${SRC_DIR}" "${DEST_DIR}" 1
# if [ $? != 0 ] ; then
#     exit 1
# fi

# 4
cp ent.xml "${SRC_DIR}/Products/Applications"/ent.xml
cd "${SRC_DIR}/Products/Applications"
codesign --remove-signature XXTExplorer.app
rm -r XXTExplorer.app/_CodeSignature
rm XXTExplorer.app/embedded.mobileprovision
ldid -Sent.xml XXTExplorer.app/XXTExplorer

# 5
echo "Succeed."
open .
