#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Rename Computer (Unattended)
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 27-May-2020, Dan K. Snelson
#		Original version
#
####################################################################################################



echo " "
echo "######################################"
echo "# Rename Computer (Unattended) 1.0.0 #"
echo "######################################"
echo " "


###
# Variables
###

approvedComputerNamePattern="A-"
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
userFullname=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk -F ': ' '/kCGSessionLongUserNameKey :/ && ! /loginwindow/ { print $NF }' )
currentComputerName=$( /usr/sbin/scutil --get ComputerName )
systemProfilerPlist="/Users/${loggedInUser}/Library/Preferences/com.apple.SystemProfiler.plist"

if [ ! -f "${systemProfilerPlist}" ]; then
	echo "${systemProfilerPlist} does NOT exist; create it ..."
	/usr/bin/pkill -l -U "${loggedInUser}" cfprefsd
	/bin/sleep 5
	/usr/bin/su \- "${loggedInUser}" -c "/usr/bin/open -g -j '/System/Library/CoreServices/Applications/About This Mac.app'"
	/bin/sleep 3
	/usr/bin/osascript -e 'quit app "System Information"'
fi

computerModelName=$( /usr/libexec/PlistBuddy -c "print :'CPU Names':$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Serial/ {print $4}' | /usr/bin/cut -c 9-)-en-US_US" ${systemProfilerPlist} )
newComputerName="${userFullname} ${computerModelName}"



###
# Program
###

# Exit if no user is logged in
if [ "${loggedInUser}" = "" ]; then
	echo "No user logged in."
	exit 0
fi

echo "• Logged-in User: ${loggedInUser}"
echo "• Logged-in User's Fullname: ${userFullname}"
echo "• Computer Model Name: ${computerModelName}"
echo "• Current Computer Name: ${currentComputerName}"
echo "• New Computer Name: ${newComputerName}"

case "${currentComputerName}" in
	"${approvedComputerNamePattern}"* )
		echo "Current computer name, \"${currentComputerName}\", already matches the approved computer name pattern; no change required."
		exit 0
		;;
esac

case "${newComputerName}" in
	*"File Doesn't Exist"* )
		echo "ERROR: Unable to rename computer to \"${newComputerName}\"."
		exit 1
		;;
esac

if [ "${currentComputerName}" = "${newComputerName}" ]; then
	echo "Current computer name, \"${currentComputerName}\", already matches the new computer name; no change required."
	exit 0
else
	echo "• Setting Computer Name to: ${newComputerName}"
	/usr/sbin/scutil --set ComputerName "${newComputerName}"
	/usr/local/jamf/bin/jamf recon -endUsername ${loggedInUser}
	echo "Renamed computer from: \"${currentComputerName}\" to \"`/usr/sbin/scutil --get ComputerName`\""
fi



exit 0
