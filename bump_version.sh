#!/bin/bash

BVER="${1}"

find . -name "*.plist" -exec plutil -lint {} \;
plutil -replace "DAEMON_VERSION" -string "${BVER}" "XXTExplorer/Defines/XXTEAppDefines.plist"
plutil -replace "DAEMON_VERSION" -string "${BVER}" "XXTExplorer/Defines/XXTEAppDefines.AppStore.plist"
plutil -replace "items.1" -xml "<dict><key>cell</key><string>About</string><key>label</key><string>XXTouch Editor\nv1.2-4</string><key>value</key><string>https://www.xxtouch.com\n2016-2017 © XXTouch Team.\nAll Rights Reserved.</string></dict>"
