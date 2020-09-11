#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Remove a LaunchDaemon
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 24-Aug-2015, Dan K. Snelson
#		Original version
#		Inspired by Kyle Brockman (brockma9)
#		https://jamfnation.jamfsoftware.com/discussion.html?id=6990
#	Version 1.1, 02-Nov-2017, Dan K. Snelson
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

plistDomain="com.company"   # Hard-coded domain name (i.e., "com.company")
plistLabel="${4}"           # Unique label for this plist (i.e., "presentationMode2")



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Program
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Remove ${plistDomain}.${plistLabel}"



# Remove launchd plist
echo "• Remove ${plistDomain}.${plistLabel} ..."
/bin/launchctl remove ${plistDomain}.${plistLabel}



# Send result back to the Jamf Pro server
echo "Removed ${plistDomain}.${plistLabel}"



exit 0
