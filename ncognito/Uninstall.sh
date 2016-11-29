#! /bin/sh

#
#  Uninstall.sh
#  ncognito
#
#  Created by GM on 21/10/2016.
#  Copyright © 2016 Georgios Moustakas. All rights reserved.
#

# This uninstalls everything installed by ncognito.

sudo launchctl unload /Library/LaunchDaemons/com.giorgosmoustakas.ncognitoHelper.plist
sudo rm /Library/LaunchDaemons/com.giorgosmoustakas.ncognitoHelper.plist
sudo rm /Library/PrivilegedHelperTools/com.giorgosmoustakas.ncognitoHelper
sudo rm -R /Library/Application\ Support/com.giorgosmoustakas.ncognitoHelper
sudo rm /tmp/oui.txt
sudo rm /tmp/hosts.txt
sudo rm /var/log/ncgnito.log
