#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Delete the Jamf Pro Policy Trigger (for restart) or ID (for login) after computer reboot
#   https://snelson.us/2023/04/trigger-jamf-pro-policy-at-login-or-reboot-0-0-2/
#
####################################################################################################
#
# HISTORY
#
#    Version 0.0.1, 20-Mar-2023, Dan K. Snelson (@dan-snelson)
#        Based on Recon at Reboot
#
#   Version 0.0.2, 13-Apr-2023, Dan K. Snelson (@dan-snelson)
#       Miscellaneous updates
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="0.0.2"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
reverseDomain="${4:-"org.churchofjesuschrist"}"     # Parameter 4: Reverse Domain Name Notation (i.e., "org.churchofjesuschrist")
launchOption="${5:-"login"}"                        # Parameter 5: Launch Option (i.e., [ restart | login ] )
triggerOrID="${6:-"29"}"                            # Parameter 6: Jamf Pro Policy Trigger (for restart) or ID (for login)
scriptLog="/var/log/${reverseDomain}.log"
plistFilename="${reverseDomain}.${triggerOrID}.plist"
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Trigger Policy at Login or Reboot: Delete (${scriptVersion})\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Complete"



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {

    updateScriptLog "Run \"$@\" as \"$loggedInUserID\" … "
    launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Delete LaunchDaemon or LaunchAgent based on launchOption
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${launchOption} in

    "login"     ) 
    
        if [[ -f "/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}" ]]; then

            # Unload LaunchAgent
            updateScriptLog "Unload ${plistFilename} … "
            runAsUser launchctl bootout gui/"${loggedInUserID}" "/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}" 2>&1

            # Remove LaunchAgent
            updateScriptLog "Remove ${plistFilename} … "
            rm -f "/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}"  2>&1
            updateScriptLog "Removed ${plistFilename}"

        else
            updateScriptLog "The file '/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}' was NOT found"
        fi
    
    ;;

    "restart" | *  )

        if [[ -f "/Library/LaunchDaemons/${plistFilename}" ]]; then

            # Unload LaunchAgent
            updateScriptLog "Unload ${plistFilename} … "
            launchctl bootout system "/Library/LaunchDaemons/${plistFilename}" 2>&1

            # Remove LaunchAgent
            updateScriptLog "Remove ${plistFilename} … "
            rm -f "/Library/LaunchDaemons/${plistFilename}" 2>&1
            updateScriptLog "Removed ${plistFilename}"

        else
            updateScriptLog "The file '/Library/LaunchDaemons/${plistFilename}' was NOT found"
        fi

    ;;

esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Goodbye!"
exit 0