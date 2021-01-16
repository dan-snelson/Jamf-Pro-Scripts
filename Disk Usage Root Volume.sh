#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Disk Usage: Home Directory
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 8-Dec-2014, Dan K. Snelson
#	Version 1.1, 8-Jun-2015, Dan K. Snelson
#		See: https://jamfnation.jamfsoftware.com/discussion.html?id=14701
#	Version 1.2, 4-Jan-2017, Dan K. Snelson
#		Updated for macOS 10.12
#	Version 1.3, 4-Jul-2018, Dan K. Snelson
#		Updated for macOS 10.13
#	Version 1.4, 11-Nov-2020, Dan K. Snelson
#		Updates from Disk Usage Home Directory
#
####################################################################################################



# Variables
loggedInUser=$( /usr/bin/stat -f%Su /dev/console )
loggedInUserHome=$( /usr/bin/dscl . -read /Users/$loggedInUser NFSHomeDirectory | /usr/bin/awk '{print $NF}' ) # mm2270
machineName=$( /usr/sbin/scutil --get LocalHostName )
volumeName=$( /usr/sbin/diskutil info / | /usr/bin/grep "Volume Name:" | /usr/bin/awk '{print $3,$4}' )
FreeSpace=$( /usr/sbin/diskutil info / | /usr/bin/grep  -E 'Free Space|Available Space|Container Free Space' | /usr/bin/awk -F ":\s*" '{ print $2 }' | awk -F "(" '{ print $1 }' | xargs )
FreeBytes=$( /usr/sbin/diskutil info / | /usr/bin/grep -E 'Free Space|Available Space|Container Free Space' | /usr/bin/awk -F "(\\\(| Bytes\\\))" '{ print $2 }' )
DiskBytes=$( /usr/sbin/diskutil info / | /usr/bin/grep -E 'Total Space' | /usr/bin/awk -F "(\\\(| Bytes\\\))" '{ print $2 }' )
FreePercentage=$(echo "scale=2; $FreeBytes*100/$DiskBytes" | bc)
diskSpace="$FreeSpace free (${FreePercentage}% available)"
outputFileName="$loggedInUserHome/Desktop/$machineName-ComputerDiskUsage-`date '+%Y-%m-%d-%H%M%S'`.txt"



# Output to Terminal
echo "### Disk usage for volume \"$volumeName\" on computer \"$machineName\"  ###"
echo "Disk Space: $diskSpace"
echo "Report Location: $outputFileName"

# Output to user
/bin/echo "-----------------------------------------------------------------------------------------------------------------------------------------" > $outputFileName
/bin/echo "Disk usage for \"$loggedInUserHome\" for volume \"$volumeName\" on computer \"$machineName\" " >> $outputFileName
/bin/echo "Disk Space: $diskSpace" >> $outputFileName
/bin/echo "Report Location: $outputFileName" >> $outputFileName
/bin/echo "-----------------------------------------------------------------------------------------------------------------------------------------" >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo "GBs	Directory or File" >> $outputFileName
/bin/echo " " >> $outputFileName
/usr/bin/du -axrg / 2>/dev/null | /usr/bin/sort -nr | /usr/bin/head -n 75 >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo "-----------------------------------------------------------------------------------------------------------------------------------------" >> $outputFileName



if [ -f $outputFileName ]; then	# Open in Safari
	/usr/bin/su - $loggedInUser -c "open -a safari $outputFileName"
fi

exit 0		## Success
exit 1		## Failure
