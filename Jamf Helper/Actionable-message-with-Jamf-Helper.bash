#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Actionable messages with Jamf Helper
#   See: https://snelson.us/2023/01/jamf-helper/
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0.0, 05-Nov-2014, Dan K. Snelson, Original
#   Version 1.1.0, 15-Nov-2014, Dan K. Snelson, Added logging
#   Version 1.2.0, 14-Oct-2016, Dan K. Snelson, Added action to open paramter 10
#   Version 1.3.0, 06-May-2022, Dan K. Snelson, Check for and exit if OS is greater than macOS Big Sur 11
#   Version 1.4.0, 18-Jan-2023, Dan K. Snelson, Added timeout for full screen mode
#
####################################################################################################



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Ensure computer does not go to sleep while running this script (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Caffeinating this script (PID: $$)"
caffeinate -dimsu -w $$ &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
    echo "No user logged-in; exiting."
    exit #1
else
    loggedInUserID=$(id -u "${loggedInUser}")
fi



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.4.0"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
scriptLog="/var/tmp/org.churchofjesuschrist.log"
JH="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
fullScreenTimeout="30"                                                                   # Number of seconds for the fullscreen messages to display
windowType="${4:-"hud"}"                                                                 # [ hud | utility | fullscreen ]
icon="${5:-"/System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns"}"    # Absolute path
title="${6:-"Title [Parameter 6]"}"                                                      # Sets the window's title to the specified string
heading="${7:-"Heading [Parameter 7]"}"                                                  # Sets the heading of the window to the specified string
description="${8:-"Description [Parameter 8] goes here, which can be as long as needed.  'fullScreenTimeout' is currently set to '$fullScreenTimeout' seconds"}"    # Sets the main contents of the window to the specified string
button1="${9:-"Button1 [P9]"}"                                                           # Creates a default button with the specified label
button2="${10:-"Button2 [P10]"}"                                                         # Creates a second button with the specified label
action="${11:-"/System/Applications/Utilities/Digital Color Meter.app"}"                 # Action (i.e., 'open ...')



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    else
        updateScriptLog "The '$process' process isn't running."
    fi
}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Display Message with Jamf Helper and Action (${scriptVersion})\n###\n"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "The following message will be displayed to the end-user:"
updateScriptLog "${title} ${heading} ${description} ${button1} ${action}"

case "${windowType}" in
    "full screen" | "fullscreen" | "fs" )
        osascript -e "set Volume 6"
        afplay /System/Library/Sounds/Blow.aiff
        /System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/MacOS/LockScreen &
        displayMessage=$( "$JH" -windowType "fs" -icon "${icon}" -heading "${heading}" -alignHeading center -description "${description}" ) &
        updateScriptLog "Pausing for ${fullScreenTimeout} seconds …"
        sleep "${fullScreenTimeout}"
        killall -v LockScreen
        killall -v jamfHelper
        updateScriptLog "Open ${action} ..."
        su - "${loggedInUser}" -c "/usr/bin/open '${action}'"
        ;;
    * )
        displayMessage=$( "$JH" -windowType "${windowType}" -icon "${icon}" -windowPosition ur -title "${title}" -heading "${heading}" -description "${description}" -alignHeading left -button1 "${button1}" -button2 "${button2}" -defaultButton 1 -cancelButton 2 )
        ;;
esac

updateScriptLog "Result of user's interaction: ${displayMessage}"

if [[ "${displayMessage}" == "0" ]]; then

    updateScriptLog "Open ${action} ..."
    /usr/bin/su \- "${loggedInUser}" -c "/usr/bin/open '${action}'"
    updateScriptLog "${title} ${heading} ${description} ${button1} ${action}"
    
else
    
    updateScriptLog "${loggedInUser} cancelled."

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "De-caffeinate …"
killProcess "caffeinate"

updateScriptLog "Goodbye!"

exit 0