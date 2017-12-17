#!/bin/sh

PACKAGE_NAME="${1:-latest}"

xcodebuild archive -workspace XXTExplorer.xcworkspace -scheme XXTExplorer-Archive -archivePath Releases/${PACKAGE_NAME} | xcpretty

xcodebuild -exportArchive -archivePath Releases/latest.xcarchive -exportPath Releases/${PACKAGE_NAME} -exportOptionsPlist DefaultExportOptions.plist -allowProvisioningUpdates

