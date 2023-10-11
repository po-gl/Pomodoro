#!/bin/sh

#  ci_post_clone.sh
#  Pomodoro
#
#  Created by Porter Glines on 10/11/23.
#  

set -e

echo "Stage: Post-clone is starting ..."

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

echo "Stage: Post-clone is DONE ..."
exit 0
