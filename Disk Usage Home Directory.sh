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
#		Added Time Machine Local Snapshot Information
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
outputFileName="$loggedInUserHome/Desktop/$loggedInUser-DiskUsage-`date '+%Y-%m-%d-%H%M%S'`.txt"

# Output to Terminal
echo "### Disk usage for \"$loggedInUserHome\" for volume \"$volumeName\" on computer \"$machineName\"  ###"
echo "Disk Space: ${diskSpace}"
echo "Report Location: $outputFileName"


# Output to user
/bin/echo "-----------------------------------------------------------------------------------------------------------------------------------------" > $outputFileName
/bin/echo "Disk usage for \"$loggedInUserHome\" for volume \"$volumeName\" on computer \"$machineName\" " >> $outputFileName
/bin/echo "Disk Space: ${diskSpace}" >> $outputFileName
/bin/echo "Report Location: $outputFileName" >> $outputFileName
/bin/echo "-----------------------------------------------------------------------------------------------------------------------------------------" >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo "GBs	Directory or File" >> $outputFileName
/bin/echo " " >> $outputFileName
/usr/bin/su - $loggedInUser -c "/usr/bin/du -axrg $loggedInUserHome 2>/dev/null | /usr/bin/sort -nr | /usr/bin/head -n 50" >> $outputFileName
/bin/echo " " >> $outputFileName
/bin/echo "-----------------------------------------------------------------------------------------------------------------------------------------" >> $outputFileName



# Time Machine Local Snapshot Information

/bin/echo "
###
# Time Machine Information
###
" >> $outputFileName

tmDestinationInfo=$( /usr/bin/tmutil destinationinfo )

if [[ "${tmDestinationInfo}" == *"No destinations configured"* ]]; then

	# Time Machine destination NOT configured.
	/bin/echo "WARNING: Time Machine destination NOT configured." >> $outputFileName

else

	# List Time Machine Local Snapshots
	#/bin/echo "Time Machine Local Snapshots:" >> $outputFileName
	/usr/bin/tmutil listlocalsnapshots / >> $outputFileName

	/bin/echo "
---
- Thin Local Time Machine Snapshots
---

Thinning local Time Machine snapshots can quickly free up disk space by PERMANENTLY deleting local Time Machine snapshots.

man tmutil

	thinlocalsnapshots mount_point [purge_amount] [urgency]

		Thin local Time Machine snapshots for the specified volume.

		When purge_amount and urgency are specified, tmutil will attempt (with urgency level 1-4)
		to reclaim purge_amount in bytes by thinning snapshots.

		If urgency is not specified, the default urgency will be used.



ABSOLUTELY UNSUPPORTED EXAMPLES TO BE USED AT YOUR OWN RISK:

# Free 20 GB of snapshots stored on the boot drive (with maximum urgency)
tmutil thinlocalsnapshots / 21474836480 4

# Free 36 GB of snapshots stored on the boot drive (with maximum urgency)
tmutil thinlocalsnapshots / 38654705664 4



" >> $outputFileName

fi



if [ -f $outputFileName ]; then	# Open in Safari
	/usr/bin/su - $loggedInUser -c "open -a safari $outputFileName"
fi

exit 0		## Success
exit 1		## Failure
