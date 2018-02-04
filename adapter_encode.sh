#!/bin/bash

SRC_PATH="XXTExplorer/Detail/XUIExtensions/Adapter/Xui/XUIAdapter_xui.lua"
MD5_PATH="${SRC_PATH}.md5"
DEST_PATH="XXTExplorer/Detail/XUIExtensions/Adapter/Xui/XUIAdapter_xui.xuic"

if [ ! -f "${SRC_PATH}" ]; then
	echo "\"${SRC_PATH}\" does not exist."
	exit 1
fi

NEW_MD5=`md5 -q "${SRC_PATH}"`

if [ -f "${MD5_PATH}" ]; then
	MD5_CONTENT=`cat ${MD5_PATH}`
	if [ "${MD5_CONTENT}" == "${NEW_MD5}" ]; then
		echo "Skip \"${SRC_PATH}\"."
		exit 0
	fi
fi

echo "Write md5(\"${SRC_PATH}\") = ${NEW_MD5}..."
echo -n "${NEW_MD5}" > "${MD5_PATH}"

echo "Update \"${DEST_PATH}\"..."
./bin/xui_encode "${SRC_PATH}" "${DEST_PATH}"

echo "Succeed."
