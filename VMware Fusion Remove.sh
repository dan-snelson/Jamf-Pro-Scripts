#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	VMware Fusion Remove
#	See: https://kb.vmware.com/s/article/1017838
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 29-May-2020, Dan K. Snelson
#		Original version
#
####################################################################################################



echo " "
echo "##############################"
echo "# VMware Fusion Remove 1.0.0 #"
echo "##############################"
echo " "


###
# Variables
###

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )



###
# Program
###

# Exit if no user is logged in
if [ "${loggedInUser}" = "" ]; then
	echo "No user logged in."
	exit 0
fi

echo " "
echo "• Remove VMware Fusion.app …"
rm -R /Applications/VMware\ Fusion.app

echo " "
echo "• Remove general VMware Fusion supporting files …"
rm -Rv /Library/Application\ Support/VMware
rm -Rv /Library/Application\ Support/VMware\ Fusion
rm -Rv /Library/Preferences/VMware\ Fusion

echo " "
echo "• Remove ${loggedInUser}'s VMware Fusion supporting files …"
rm -Rv /Users/${loggedInUser}/Library/Application\ Support/VMware\ Fusion*
rm -Rv /Users/${loggedInUser}/Library/Caches/com.vmware.fusion
rm -Rv /Users/${loggedInUser}/Library/Preferences/VMware\ Fusion
rm -Rv /Users/${loggedInUser}/Library/Preferences/com.vmware.fusion*
rm -Rv /Users/${loggedInUser}/Library/Logs/VMware
rm -Rv /Users/${loggedInUser}/Library/Logs/VMware\ Fusion
rm -Rv /Users/${loggedInUser}/Library/Logs//VMware\ Fusion\ Applications\ Menu

echo " "
echo "• Remove VMware Fusion StagedExtensions …"
echo "`ls -lah /Library/StagedExtensions/`"
/usr/sbin/kextcache --clear-staging
echo "`ls -lah /Library/StagedExtensions/`"

echo "Restart after showing a confirmation dialog"
/usr/bin/su \- "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'"



exit 0
