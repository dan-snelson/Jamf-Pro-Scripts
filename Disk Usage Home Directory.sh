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
#		Updated with df; thanks to seann and EdLuo
#		See: https://www.jamf.com/jamf-nation/discussions/14881/
#
####################################################################################################


# Variables
loggedInUser=$( /usr/bin/stat -f%Su /dev/console )
loggedInUserHome=$( /usr/bin/dscl . -read /Users/$loggedInUser NFSHomeDirectory | /usr/bin/awk '{print $NF}' ) # mm2270
machineName=$( /usr/sbin/scutil --get LocalHostName )
volumeName=$( /usr/sbin/diskutil info / | /usr/bin/grep "Volume Name:" | /usr/bin/awk '{print $3,$4}' )
availableSpace=$( /bin/df -g / | /usr/bin/awk 'FNR==2{print $4}' )
totalSpace=$( /bin/df -g / | /usr/bin/awk 'FNR==2{print $2}' )
percentageAvailable=$( /bin/echo "scale=3; ($availableSpace / $totalSpace) * 100" | /usr/bin/bc )
outputFileName="$loggedInUserHome/Desktop/$loggedInUser-DiskUsage.txt"



# Output to user
/bin/echo "--------------------------------------------------------------------------------------------------------------" > $outputFileName
/bin/echo "`now` Disk usage for \"$loggedInUserHome\" for volume \"$volumeName\" on computer \"$machineName\" " >> $outputFileName
/bin/echo "* Available Space:	$availableSpace GB" >> $outputFileName
/bin/echo "* Total Space:		$totalSpace GB" >> $outputFileName
/bin/echo "* Percentage Free: 	$percentageAvailable%" >> $outputFileName
/bin/echo "--------------------------------------------------------------------------------------------------------------" >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo "GBs	Directory or File" >> $outputFileName
/bin/echo " " >> $outputFileName
/usr/bin/du -axrg $loggedInUserHome | /usr/bin/sort -nr | /usr/bin/head -n 75 >> $outputFileName


if [ -f $outputFileName ]; then	# Open in Safari
	/usr/bin/su - $loggedInUser -c "open -a safari $outputFileName"
fi

exit 0		## Success
exit 1		## Failure
