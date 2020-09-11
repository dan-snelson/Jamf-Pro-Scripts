#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Disable a LaunchDaemon
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 24-Aug-2015, Dan K. Snelson
#		Original version
#		Inspired by Kyle Brockman (brockma9)
#		https://jamfnation.jamfsoftware.com/discussion.html?id=6990
#	Version 1.1.0, 02-Nov-2017, Dan K. Snelson
#		Updated log writing
#	Version 1.1.1, 17-Aug-2019, Dan K. Snelson
#		Updates for macOS Catalina
#
####################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Variables
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

plistDomain="com.company"				# Hard-coded domain name (i.e., "com.company")
plistLabel="${4}"					# Unique label for this plist (i.e., "presentationMode2")
plistFilename="${plistDomain}.${plistLabel}.plist"	# Prepend domain to label



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Program
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Delayed Policy Trigger Disable"
echo "• Filename: ${plistFilename}"



if [ -f "/Library/LaunchDaemons/${plistFilename}" ] ; then

	# Disable launchd plist
	echo "• Disable ${plistFilename} ..."
	/usr/bin/defaults write /Library/LaunchDaemons/${plistFilename} Disabled -bool true

	# Unload launchd plist
	#echo "• Unload ${plistFilename} ..."
	#/bin/launchctl unload -wF /Library/LaunchDaemons/${plistFilename}

	# Delete launchd plist
	echo "• Delete ${plistFilename} ..."
	/bin/rm -f /Library/LaunchDaemons/${plistFilename}
	echo "• plist ${plistLabel} cleared"

	# Send result back to the Jamf Pro server
	echo "Disabled and deleted ${plistFilename}"

else

	echo "File ${plistFilename} not found."

fi



exit 0
