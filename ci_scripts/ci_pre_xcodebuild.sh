#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Pomodoro
#
#  Created by Porter Glines on 12/16/23.
#  

set -e

echo "Stage: PRE-Xcode Build is starting ..."

cd ../Shared/

touch Env.plist
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
        <key>serverURL</key>
        <string>$SERVER_URL</string>
</dict>
</plist>" > Env.plist

echo "Stage: PRE-Xcode Build is DONE ..."

exit 0
