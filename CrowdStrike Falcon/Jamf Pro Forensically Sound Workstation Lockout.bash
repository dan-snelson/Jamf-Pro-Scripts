#!/bin/bash
# shellcheck disable=SC2034,SC2317,SC2086,SC2143,SC2181

####################################################################################################
#
# Title:            Jamf Pro Forensically Sound Workstation Lockout
#
# Purpose:          Leverages the built-in macOS LockScreen binary and a LaunchDaemon
#                   to prevent end-user interaction
#
# Documentation:    https://snelson.us/fswl
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0, 15-Mar-2025, Dan K. Snelson (@dan-snelson)
#   - First "official" release
#
####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="1.0.0"

# Client-side Log
scriptLog="/var/log/org.churchofjesuschrist.log"

# jamfHelper Location
JH="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# LaunchDaemon Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Hard-coded domain name
plistDomain="org.churchofjesuschrist"

# Unique label for this plist
plistLabel="fswl"

# Prepend domain to label
plistDomainAndLabel="$plistDomain.$plistLabel"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Script Human-readabale Name
humanReadableScriptName="Forensically Sound Workstation Lockout"

# Organization's Script Name
organizationScriptName="FSWL"

# Organization's Local Admin (for exclusive SSH)
organizationLocalAdmin="organizations_local_admin_account"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Sets the heading of the window to the specified string
heading="${4:-"Heading [Parameter 4]"}"                                                  

# Absolute path to client-side icon
icon="${5:-"/System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns"}"

# Sets the main contents of the window to the specified string
description="${6:-"Description [Parameter 6]"}"

# LaunchDaemon Variation [ Local Script | Remote Policy ]
launchDaemonVariation="${7:-"Local Script"}"

# Policy Trigger
policyTrigger="${8:-"Policy Trigger [Parameter 8]"}"



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo "${organizationScriptName} ($scriptVersion): $( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

function preFlight() {
    updateScriptLog "[PRE-FLIGHT]      ${1}"
}

function logComment() {
    updateScriptLog "                  ${1}"
}

function notice() {
    updateScriptLog "[NOTICE]          ${1}"
}

function info() {
    updateScriptLog "[INFO]            ${1}"
}

function errorOut(){
    updateScriptLog "[ERROR]           ${1}"
}

function error() {
    updateScriptLog "[ERROR]           ${1}"
    (( errorCount++ )) || true
}

function warning() {
    updateScriptLog "[WARNING]         ${1}"
    (( errorCount++ )) || true
}

function fatal() {
    updateScriptLog "[FATAL ERROR]     ${1}"
    exit 1
}

function quitOut(){
    updateScriptLog "[QUIT]            ${1}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create LaunchDaemon for Remote Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function launchDaemonRemotePolicy() {

    logComment "Call remote policy"
    (
    cat <<endOfLaunchDaemonRemote
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Enabled</key>
        <true/>
        <key>EnableTransactions</key>
        <true/>
        <key>Label</key>
        <string>${plistDomainAndLabel}</string>
        <key>UserName</key>
        <string>root</string>
        <key>ProgramArguments</key>
        <array> 
            <string>/usr/local/jamf/bin/jamf</string>
            <string>policy</string>
            <string>-event</string>
            <string>${policyTrigger}</string>
            <string>-verbose</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>${scriptLog}</string>
        <key>StandardOutPath</key>
        <string>${scriptLog}</string>
    </dict>
</plist>

endOfLaunchDaemonRemote
    ) > /Library/LaunchDaemons/$plistDomainAndLabel.plist

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create LaunchDaemon for Local Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function launchDaemonLocalScript() {

    notice "Create LaunchDaemon for Local Script"

    logComment "Create local script directory"
    mkdir -pv "/usr/local/${plistDomain}/scripts/" 

    logComment "Create local script"
    (
    cat <<endOfLaunchDaemonScript
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Enabled</key>
        <true/>
        <key>EnableTransactions</key>
        <true/>
        <key>Label</key>
        <string>${plistDomainAndLabel}</string>
        <key>UserName</key>
        <string>root</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/bash</string>
            <string>/usr/local/${plistDomain}/scripts/${plistLabel}.bash</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>${scriptLog}</string>
        <key>StandardOutPath</key>
        <string>${scriptLog}</string>
    </dict>
</plist>

endOfLaunchDaemonScript
    ) > /Library/LaunchDaemons/$plistDomainAndLabel.plist

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # Create Local Script
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    notice "Create local script ..."
    logComment "/usr/local/${plistDomain}/scripts/${plistLabel}.bash"

    (
    cat <<endOfScript
#!/bin/bash
####################################################################################################
#
# ABOUT
#
#    Forensically Sound Workstation Lockout
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1, 04-Feb-2025, Dan K. Snelson (@dan-snelson)
#   - Original version
#
# Version 0.0.2, 28-Feb-2025, Dan K. Snelson (@dan-snelson)
#   - Added hard-coded sleep of 11 seconds to launchDaemonLocalScript (to try and keep launchd happy)
#
####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="0.0.2"



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Scripts must run at least 10 seconds (or launchd may get suspicious)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sleep 11 



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "The following message will be displayed to the end-user:"
echo "${heading} ${description}"

echo "Lock screen with specified message"
osascript -e "set Volume 10"
afplay /System/Library/Sounds/Blow.aiff
/System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/MacOS/LockScreen &
sleep 1.5
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType fs -icon '${icon}' -heading '${heading}' -description '${description}'

exit 0
endOfScript
    ) > "/usr/local/${plistDomain}/scripts/${plistLabel}.bash"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate / Create Groups
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateCreateGroup(){

    groupName="${1}"
    groupNumber="${2}"

    if [[ $( dscl . list /Groups | grep "${groupName}" ) ]]; then

        logComment "${groupName} Exists: $( dscl . -read Groups/"${groupName}" GroupMembership 2>&1)"

    else

        notice "Creating ${groupName} …"
        dscl . create /Groups/"${groupName}"
        if [[ $? -ne 0 ]]; then
            fatal "Failed to create ${groupName}"
        else
            logComment "Successfully created ${groupName}"
        fi

        notice "Assigning ${groupName} a GID of ${groupNumber} …"
        dscl . create /Groups/"${groupName}" gid "${groupNumber}"
        if [[ $? -ne 0 ]]; then
            fatal "Failed to assign ${groupName} a GID of ${groupNumber}"
        else
            logComment "Successfully assigned ${groupName} a GID of ${groupNumber}"
        fi

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add User to Group
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function addUserToGroup(){

    userName="${1}"
    groupName="${2}"

    notice "Add ${userName} to ${groupName} …"

    membershipCheck=$( dseditgroup -o checkmember -m "${userName}" "${groupName}" )

    if [[ "${membershipCheck}" == *"NOT a member"* ]]; then

        logComment "Adding ${userName} to ${groupName} …"
        dseditgroup -o edit -a "${userName}" -t user "${groupName}"
        if [[ $? -ne 0 ]]; then
            warning "Failed to adding ${userName} to ${groupName}"
        else
            membershipCheck=$( dseditgroup -o checkmember -m "${userName}" "${groupName}" )
            logComment "${membershipCheck}"
        fi
    
    else

        logComment "${membershipCheck}"

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset SSH Privileges
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetSshPrivileges(){

    # Disable SSH
    notice "Disable SSH"
    launchctl bootout system /System/Library/LaunchDaemons/ssh.plist
    if [[ $? -ne 0 ]]; then
        warning "Failed to unload SSH"
    else
        logComment "Unloaded SSH"
    fi

    # Brute-force kill all SSH sessions
    pkill -9 ssh

    # Delete SSH group to reset access for all accounts
    logComment "Delete SSH group to reset access for all accounts"
    dseditgroup -o delete -t group com.apple.access_ssh
    if [[ $? -ne 0 ]]; then
        warning "Failed to delete SSH group"
    else
        logComment "Deleted SSH group"
    fi

    # Enable SSH for Organization Local Admin
    logComment "Enable SSH for Organization Local Admin"
    validateCreateGroup "com.apple.access_ssh" "399"
    addUserToGroup "${organizationLocalAdmin}" "com.apple.access_ssh"
    launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
    if [[ $? -ne 0 ]]; then
        warning "Failed to Bootstrap SSH"
    else
        logComment "Bootstraped SSH"
    fi

    launchctl start /System/Library/LaunchDaemons/ssh.plist
    if [[ $? -ne 0 ]]; then
        warning "Failed to start SSH"
    else
        logComment "Started SSH"
    fi

}




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
    if [[ -f "${scriptLog}" ]]; then
        preFlight "Created specified scriptLog"
    else
        fatal "Unable to create specified scriptLog; exiting.\n\n(Is this script running as 'root' ?)"
    fi
else
    preFlight "Specified scriptLog exists; writing log entries to it"
fi




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n###\n"
preFlight "Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    fatal "This script must be run as root; exiting."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure computer does not go to sleep (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

caffeinatedPID="$$"
preFlight "Caffeinating this script (PID: $caffeinatedPID)"
caffeinate -dimsu -w $caffeinatedPID &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Complete!"



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset SSH Privileges
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resetSshPrivileges



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "The following message will be displayed to the end-user:"
logComment "${heading} ${description}"

notice "Lock screen with specified message"
osascript -e "set Volume 10"
afplay /System/Library/Sounds/Blow.aiff
/System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/MacOS/LockScreen &
sleep 1.5
displayMessage=$( "$JH" -windowType "fs" -icon "${icon}" -heading "${heading}" -description "${description}" ) &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "Create the LaunchDaemon:"
logComment "/Library/LaunchDaemons/$plistDomainAndLabel.plist"

case $launchDaemonVariation in 

    "Remote Policy" )
        launchDaemonRemotePolicy
        ;;
    
    "Local Script" | * )
        launchDaemonLocalScript
        ;;

esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set the permission on the file
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "Set LaunchDaemon file permissions ..."
/usr/sbin/chown root:wheel "/Library/LaunchDaemons/${plistDomainAndLabel}.plist"
/bin/chmod 644 "/Library/LaunchDaemons/${plistDomainAndLabel}.plist"
/bin/chmod +x "/Library/LaunchDaemons/${plistDomainAndLabel}.plist"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

quitOut "Exit"

exit 0