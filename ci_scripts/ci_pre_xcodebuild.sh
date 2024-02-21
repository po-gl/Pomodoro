#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Pomodoro
#
#  Created by Porter Glines on 12/16/23.
#  

set -e

echo "Stage: PRE-Xcode Build is starting ..."

if [[ $CI_XCODEBUILD_ACTION = "archive" || -d "../Shared/" ]]; then
    cd ../Shared/

    echo "Adding Env.plist to ../Shared/"
    echo "serverURL: $SERVER_URL"

    touch Env.plist
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
    <plist version=\"1.0\">
    <dict>
        <key>serverURL</key>
        <string>$SERVER_URL</string>
    </dict>
    </plist>" > Env.plist
fi

echo "Stage: PRE-Xcode Build is DONE ..."

exit 0
