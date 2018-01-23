#!/bin/sh

if [ $# != 2 ] ; then 
echo "Usage: ${0} PackageName DaemonVersion"
exit 1; 
fi 

PACKAGE_NAME="${1:-latest}"
DAEMON_VERSION="${2}"

# 1
./bump_version.sh ${DAEMON_VERSION}

# 2
xcodebuild archive -workspace XXTExplorer.xcworkspace -scheme XXTExplorer-Archive -archivePath Releases/${PACKAGE_NAME} | xcpretty --color

# 3
xcodebuild -exportArchive -archivePath Releases/${PACKAGE_NAME}.xcarchive -exportPath Releases/${PACKAGE_NAME} -exportOptionsPlist DefaultExportOptions.plist -allowProvisioningUpdates | xcpretty --color

# 4
open Releases
