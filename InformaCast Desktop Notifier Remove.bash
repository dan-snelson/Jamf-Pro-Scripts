#!/bin/bash
####################################################################################################
#
# Description
#
#	Removes InformaCast Desktop Notifier
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 07-Jul-2020, Dan K. Snelson
#		Based on: /Applications/DesktopNotifier.app/Contents/Resources/Uninstaller.app
#
####################################################################################################



echo " "
echo "##############################################"
echo "# InformaCast Desktop Notifier Remove, 1.0.0 #"
echo "##############################################"
echo " "



####################################################################################################
#
# Variables
#
####################################################################################################

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )



####################################################################################################
#
# Define the Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit if a odd-ball user is logged-in ...
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

validateLoggedInUser() {

	echo "Validate Logged-in user ..."

	if  [[ ${loggedInUser} == "root" ]] || \
		[[ ${loggedInUser} == "adobeinstall" ]] || \
		[[ ${loggedInUser} == "_mbsetupuser" ]] ; then

		echo "${loggedInUser} is currently logged in; exiting."
		exit 0

	else

		echo "${loggedInUser} is currently logged in; proceeding ..."
		echo ""

	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit App Gracefully
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

quitAppGracefully() {

	echo " " # Blank line for readability

	echo "App to quit: ${1}"

	/usr/bin/osascript -e 'quit app "'"${1}"'"'
	echo "Quit ${1}."

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Directory
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeDirectory() {

	echo " " # Blank line for readability

	echo "Directory to remove: ${1}"

	/bin/rm -Rf "${1}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove File
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeFile() {

	echo " " # Blank line for readability

	echo "File to remove: ${1}"

	/bin/rm -fv "${1}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove LaunchAgent / LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeLaunchAgentDaemon() {

	echo " " # Blank line for readability

	echo "LaunchAgent / LaunchDaemon to remove: ${1}"

	/bin/launchctl unload -wF "${1}"

	/bin/launchctl remove -wF "${1}"


}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Installer Receipt
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeInstallerReceipt() {

	echo " " # Blank line for readability

	echo "Receipt to remove: ${1}"

	/usr/sbin/pkgutil --forget "${1}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Dock Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeDockIcon() {

	echo " " # Blank line for readability

	echo "Dock icon to remove: ${1}"

	dockLocation=$( /usr/bin/su \- "${loggedInUser}" -c "/usr/bin/defaults read com.apple.dock persistent-apps | /usr/bin/grep file-label | /usr/bin/awk '/${1}/ {printf NR}' " )

	dockLocation=$[$dockLocation-1]

	echo "${1} has a Dock location of: ${dockLocation}"

	/usr/bin/su \- "${loggedInUser}" -c "/usr/libexec/PlistBuddy -c 'Delete persistent-apps:"${dockLocation}"' /Users/${loggedInUser}/Library/Preferences/com.apple.dock.plist "

	quitAppGracefully "Dock"

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit if a odd-ball user is logged-in ...
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

validateLoggedInUser



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit InformaCast Desktop Notifier gracefully
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

quitAppGracefully "InformaCast Desktop Notifier"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Dock Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeDockIcon "InformaCast Desktop Notifier"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Directories and Files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeDirectory "/Applications/DesktopNotifier.app"

removeLaunchAgentDaemon "/Library/LaunchAgents/com.singlewire.DesktopNotifierTrashMonitor.plist"
removeFile "/Library/LaunchAgents/com.singlewire.DesktopNotifierTrashMonitor.plist"

removeLaunchAgentDaemon "/Library/LaunchAgents/com.singlewire.DesktopNotifierAgent.plist"
removeFile "/Library/LaunchAgents/com.singlewire.DesktopNotifierAgent.plist"

removeDirectory "/Library/Application Support/Singlewire"

removeInstallerReceipt "com.singlewire.pkg.DesktopNotifier"



echo "Removed InformaCast Desktop Notifier"

exit 0
