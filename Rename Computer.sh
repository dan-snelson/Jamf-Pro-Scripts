#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Rename Computer
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 18-Jun-2015, Dan K. Snelson
#		Original version
#
####################################################################################################

echo "*** Rename Computer ***"

### Log current computer name
currentComputerName=$( /usr/sbin/scutil --get ComputerName )
echo "Current Computer Name: $currentComputerName"


### Prompt for new computer name
newComputerName="$(/usr/bin/osascript -e 'Tell application "System Events" to display dialog "Enter the new computer name:" default answer "" buttons {"Rename","Cancel"} default button 2' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    echo "User clicked Cancel"
    exit 1 # exit with an error status
elif [ -z "$newComputerName" ]; then
    # The user left the computer name blank
    echo "User left the computer name blank"
    /usr/bin/osascript -e 'Tell application "System Events" to display alert "No computer name entered; cancelling." as critical'
    exit 1 # exit with an error status
fi


### Set and log new computer name
/usr/sbin/scutil --set ComputerName "$newComputerName"
echo "New Computer Name: $newComputerName"

### Update the JSS
/usr/local/jamf/bin/jamf recon

# Inform user of computer renamed
/usr/local/jamf/bin/jamf displayMessage -message "Renamed computer from: \"$currentComputerName\" to \"$newComputerName\"" &

echo "Renamed computer from: \"$currentComputerName\" to \"$newComputerName\""

exit 0		## Success
exit 1		## Failure
