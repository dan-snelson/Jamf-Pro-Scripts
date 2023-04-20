#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Execute a Jamf Pro Policy Trigger (for restart) or ID (for login) after computer reboot
#   https://snelson.us/2023/04/trigger-jamf-pro-policy-at-login-or-reboot-0-0-2/
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 20-Mar-2023, Dan K. Snelson (@dan-snelson)
#       Based on Recon at Reboot
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

updateScriptLog "\n\n###\n# Trigger Policy at Login or Reboot: Create (${scriptVersion})\n###\n"
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
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set LaunchDaemon or LaunchAgent based on launchOption
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${launchOption} in

    "login"     ) 
    
        # Create User's LaunchAgents directory as required
        if [[ ! -d "/Users/${loggedInUser}/Library/LaunchAgents/" ]]; then
            updateScriptLog "Create '/Users/${loggedInUser}/Library/LaunchAgents/' …"
            mkdir -pv "/Users/${loggedInUser}/Library/LaunchAgents"
            chown -v "${loggedInUser}":staff "/Users/${loggedInUser}/Library/LaunchAgents"
            chmod -v 755 "/Users/${loggedInUser}/Library/LaunchAgents"
        fi

        # Create LaunchAgent to call Jamf Pro Policy
        updateScriptLog "Create LaunchAgent to call Jamf Pro Policy: ${triggerOrID} ..."
        /bin/echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Enabled</key>
    <true/>
    <key>EnableTransactions</key>
    <true/>
    <key>Label</key>
    <string>${reverseDomain}.${triggerOrID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>jamfselfservice://content?entity=policy&id=${triggerOrID}&action=execute</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>" > "/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}"

    # Set the permission on the file
    updateScriptLog "Set permissions on launchd plist ..."
    chown "${loggedInUser}":staff "/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}"
    chmod 644 "/Users/${loggedInUser}/Library/LaunchAgents/${plistFilename}"
    
    ;;

    "restart" | *  )

        # Create LaunchDaemon to call Jamf Pro Policy Trigger
        updateScriptLog "Create LaunchDaemon to call Jamf Pro Policy Trigger: ${triggerOrID} ..."
/bin/echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key> 
    <string>${reverseDomain}.${triggerOrID}</string>
    <key>ProgramArguments</key> 
    <array> 
        <string>/usr/local/jamf/bin/jamf</string>
        <string>policy</string>
        <string>-event</string>
        <string>${triggerOrID}</string>
        <string>-verbose</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict> 
</plist>" > "/Library/LaunchDaemons/${plistFilename}"    

    # Set the permissions on LaunchDaemon
    updateScriptLog "Setting permissions on '/Library/LaunchDaemons/${plistFilename}' ..."
    chown root:wheel "/Library/LaunchDaemons/${plistFilename}"
    chmod 644 "/Library/LaunchDaemons/${plistFilename}"
    updateScriptLog "Set permissions on '/Library/LaunchDaemons/${plistFilename}'"

    ;;

esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "So long!"
exit 0