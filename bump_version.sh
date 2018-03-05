#!/bin/bash

if [ $# != 2 ] ; then 
echo "Usage: $0 SchemeName DaemonVersion"
exit 1; 
fi

YEAR=`date +%Y`

# 1
SCHEME="${1}"
BVER="${2}"

# 2
find . -name "*.plist" -exec plutil -lint {} \; > /dev/null

if [ "${SCHEME}" == "XXTExplorer-Archive" ]; then

plutil -replace "CFBundleShortVersionString" -string "${BVER}" "XXTExplorer/Supporting Files/Base.lproj/Info.plist"
plutil -replace "CFBundleShortVersionString" -string "${BVER}" "XXTExplorer/Supporting Files/Base.lproj/Archive-Info.plist"
plutil -replace "DAEMON_VERSION" -string "${BVER}" "XXTExplorer/Defines/XXTEAppDefines.plist"
plutil -remove "items.1" "XXTExplorer/Supporting Files/Settings.Pro.bundle/About.plist"
plutil -insert "items.1" -xml "<dict><key>cell</key><string>About</string><key>label</key><string>XXTouch
v${BVER}</string><key>value</key><string>https://www.xxtouch.com
2016-${YEAR} © XXTouch Team.
All Rights Reserved.</string></dict>" "XXTExplorer/Supporting Files/Settings.Pro.bundle/About.plist"
plutil -remove "items.6" "XXTExplorer/Supporting Files/Settings.Pro.bundle/About.plist"
plutil -insert "items.6" -xml "<dict><key>cell</key><string>Button</string><key>label</key><string>Mail Feedback</string><key>action</key><string>SendMail:</string><key>args</key><dict><key>subject</key><string>[Feedback] XXTouch v${BVER}</string><key>toRecipients</key><array><string>bug@xxtouch.com</string></array><key>ccRecipients</key><array><string>i.82@qq.com</string></array></dict><key>icon</key><string>res/XXTEAboutIconMail.png</string><key>iconRenderingMode</key><string>AlwaysTemplate</string></dict>" "XXTExplorer/Supporting Files/Settings.Pro.bundle/About.plist"
plutil -remove "PreferenceSpecifiers.3" "XXTExplorer/Supporting Files/Settings.Pro.bundle/Root.plist"
plutil -insert "PreferenceSpecifiers.3" -xml "<dict><key>Type</key><string>PSTitleValueSpecifier</string><key>DefaultValue</key><string>${BVER}</string><key>Title</key><string>Version</string><key>Key</key><string>sbVersion</string></dict>" "XXTExplorer/Supporting Files/Settings.Pro.bundle/Root.plist"

elif [ "${SCHEME}" == "XXTExplorer" ]; then

plutil -replace "CFBundleShortVersionString" -string "${BVER}" "XXTExplorer/Supporting Files/Base.lproj/Info.AppStore.plist"
plutil -replace "DAEMON_VERSION" -string "${BVER}" "XXTExplorer/Defines/XXTEAppDefines.AppStore.plist"
plutil -remove "items.1" "XXTExplorer/Supporting Files/Settings.bundle/About.plist"
plutil -insert "items.1" -xml "<dict><key>cell</key><string>About</string><key>label</key><string>XXTouch Editor
v${BVER}</string><key>value</key><string>https://www.xxtouch.com
2016-${YEAR} © XXTouch Team.
All Rights Reserved.</string></dict>" "XXTExplorer/Supporting Files/Settings.bundle/About.plist"
plutil -remove "items.6" "XXTExplorer/Supporting Files/Settings.bundle/About.plist"
plutil -insert "items.6" -xml "<dict><key>cell</key><string>Button</string><key>label</key><string>Mail Feedback</string><key>action</key><string>SendMail:</string><key>args</key><dict><key>subject</key><string>[Feedback] XXTouch Editor v${BVER}</string><key>toRecipients</key><array><string>bug@xxtouch.com</string></array><key>ccRecipients</key><array><string>i.82@qq.com</string></array></dict><key>icon</key><string>res/XXTEAboutIconMail.png</string><key>iconRenderingMode</key><string>AlwaysTemplate</string></dict>" "XXTExplorer/Supporting Files/Settings.bundle/About.plist"
plutil -remove "PreferenceSpecifiers.3" "XXTExplorer/Supporting Files/Settings.bundle/Root.plist"
plutil -insert "PreferenceSpecifiers.3" -xml "<dict><key>Type</key><string>PSTitleValueSpecifier</string><key>DefaultValue</key><string>${BVER}</string><key>Title</key><string>Version</string><key>Key</key><string>sbVersion</string></dict>" "XXTExplorer/Supporting Files/Settings.bundle/Root.plist"

fi
