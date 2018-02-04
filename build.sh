#!/bin/sh

if [ $# != 2 ] ; then 
echo "Usage: ${0} PackageName DaemonVersion"
exit 1; 
fi 

PACKAGE_NAME="${1:-latest}"
DAEMON_VERSION="${2}"

# 0
echo "Update adapter..."
./adapter_encode.sh

# 1
echo "Bump version..."
./bump_version.sh ${DAEMON_VERSION}

# 2
echo "Trigger build..."
xcodebuild archive -workspace XXTExplorer.xcworkspace -scheme XXTExplorer-Archive -archivePath Releases/${PACKAGE_NAME} | xcpretty --color

# 3
echo "Trigger export..."
xcodebuild -exportArchive -archivePath Releases/${PACKAGE_NAME}.xcarchive -exportPath Releases/${PACKAGE_NAME} -exportOptionsPlist DefaultExportOptions.plist -allowProvisioningUpdates | xcpretty --color

# 4
echo "Succeed."
open Releases
