#!/bin/zsh 
# shellcheck shell=bash
# shellcheck disable=SC2001

####################################################################################################
#
# Jamf Pro Health Check
# https://snelson.us/jphc
#
# Overview:
#
#   1.  This script creates a client-side LaunchDaemon which marks the Mac as "unhealthy"
#       each morning shortly after midnight.
#
#   2.  Adding this script to your Jamf Pro daily inventory update policy will mark the Mac
#       as "healthy" each time the policy is executed successfully.
#
#   3.  Leverage a vendor's ability to read client-side `.plist` values to determine if the Mac is
#       "healthy" or "unhealthy", based on the Mac's ability to update its inventory with the
#       Jamf Pro server.
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 25-Jan-2024, Dan K. Snelson (@dan-snelson)
#   - Original version, with code and inspiration from:
#       - [robjschroeder](https://github.com/robjschroeder)
#       - [bigmacadmin](https://github.com/bigmacadmin)
#       - [drtaru](https://github.com/drtaru)
#
#   Version 0.0.2, 26-Jan-2024, Dan K. Snelson (@dan-snelson)
#   - LaunchDaemon modifications
#
#   Version 0.0.3, 26-Jan-2024, Dan K. Snelson (@dan-snelson)
#   - LaunchDaemon modifications
#   - Logging modifications
#
#   Version 0.0.4, 26-Jan-2024, Dan K. Snelson (@dan-snelson)
#   - Conditional LaunchDaemon unloading (to avoid "Boot-out failed: 5: Input/output error")
#
#   Version 0.0.5, 27-Jan-2024, Dan K. Snelson (@dan-snelson)
#   - Added `resetConfiguration` options: None (blank) | All | LaunchDaemon | Script | Uninstall
#   - Added logging to "unhealthy" script
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Script Version
scriptVersion="0.0.5"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Parameter 4: Script Log (i.e., Your organization's default location for client-side logs)
scriptLog="${4:-"/var/log/org.churchofjesuschrist.log"}"

# Parameter 5: Configuration Files to Reset (i.e., None (blank) | All | LaunchDaemon | Script | Uninstall)
resetConfiguration="${5:-""}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Organization's Reverse Domain Name Notation (i.e., com.company.division)
reverseDomainNameNotation="org.churchofjesuschrist"

# Script Human-readabale Name
humanReadableScriptName="Jamf Pro Health Check"

# Organization's Directory (i.e., where the script-generated files reside; must previously exist)
organizationDirectory="/path/to/your/client-side/scripts/"

# Organization's Script Name
organizationScriptName="jphc"

# LaunchDaemon Name & Path
launchDaemonName="${reverseDomainNameNotation}.${organizationScriptName}.plist"
launchDaemonPath="/Library/LaunchDaemons/${launchDaemonName}"

# Property List File
plistFilepath="/Library/Preferences/${reverseDomainNameNotation}.${organizationScriptName}.plist"

# Property List "Key" for which the value will be set
key="${humanReadableScriptName}"

# Property List "Healthy Value"
healthyValue="true"

# Property List "Unhealthy Value"
unhealthyValue="false"

# Vendor's Directory (validated to ensure vendor's software is installed; must previously exist)
vendorDirectory="/Library/Application Support/PaloAltoNetworks/GlobalProtect/"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Computer Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

computerName=$( scutil --get ComputerName )
serialNumber=$( ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}' )
modelName=$( /usr/libexec/PlistBuddy -c 'Print :0:_items:0:machine_name' /dev/stdin <<< "$(system_profiler -xml SPHardwareDataType)" )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Operating System Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

osVersion=$( sw_vers -productVersion )
osVersionExtra=$( sw_vers -productVersionExtra ) 
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )

# Report RSR sub-version if applicable
if [[ -n $osVersionExtra ]] && [[ "${osMajorVersion}" -ge 13 ]]; then osVersion="${osVersion} ${osVersionExtra}"; fi



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

function debugVerbose() {
    if [[ "$debugMode" == "verbose" ]]; then
        updateScriptLog "[DEBUG VERBOSE]   ${1}"
    fi
}

function debug() {
    if [[ "$debugMode" == "true" ]]; then
        updateScriptLog "[DEBUG]           ${1}"
    fi
}

function errorOut(){
    updateScriptLog "[ERROR]           ${1}"
}

function error() {
    updateScriptLog "[ERROR]           ${1}"
    let errorCount++
}

function warning() {
    updateScriptLog "[WARNING]         ${1}"
    let errorCount++
}

function fatal() {
    updateScriptLog "[FATAL ERROR]     ${1}"
    exit 1
}

function quitOut(){
    updateScriptLog "[QUIT]            ${1}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetConfiguration() {

    notice "Reset Configuration: ${1}"

    case ${1} in

        "All" )

            info "Reset All Configuration Files … "

            # Reset LaunchDaemon
            info "Reset LaunchDaemon … "
            launchDaemonStatus
            if [[ -n "${launchDaemonStatus}" ]]; then
                logComment "Unload '${launchDaemonPath}' … "
                launchctl bootout system "${launchDaemonPath}"
                launchDaemonStatus
            fi
            logComment "Removing '${launchDaemonPath}' … "
            rm -f "${launchDaemonPath}" 2>&1
            logComment "Removed '${launchDaemonPath}'"

            # Reset Script
            info "Reset Script … "
            logComment "Removing '${organizationDirectory}/${organizationScriptName}-unhealthy.zsh' … "
            rm -f "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"
            logComment "Removed '${organizationDirectory}/${organizationScriptName}-unhealthy.zsh' "
            ;;

        "LaunchDaemon" )

            info "Reset LaunchDaemon … "
            launchDaemonStatus
            if [[ -n "${launchDaemonStatus}" ]]; then
                logComment "Unload '${launchDaemonPath}' … "
                launchctl bootout system "${launchDaemonPath}"
                launchDaemonStatus
            fi
            logComment "Removing '${launchDaemonPath}' … "
            rm -f "${launchDaemonPath}" 2>&1
            logComment "Removed '${launchDaemonPath}'"
            ;;

        "Script" )

            info "Reset Script … "
            logComment "Removing '${organizationDirectory}/${organizationScriptName}-unhealthy.zsh' … "
            rm -f "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"
            logComment "Removed '${organizationDirectory}/${organizationScriptName}-unhealthy.zsh' "
            ;;

        "Uninstall" )

            warning "*** UNINSTALLING ${humanReadableScriptName} ***"

            # Uninstall LaunchDaemon
            info "Uninstall LaunchDaemon … "
            launchDaemonStatus
            if [[ -n "${launchDaemonStatus}" ]]; then
                logComment "Unload '${launchDaemonPath}' … "
                launchctl bootout system "${launchDaemonPath}"
                launchDaemonStatus
            fi
            logComment "Removing '${launchDaemonPath}' … "
            rm -f "${launchDaemonPath}" 2>&1
            logComment "Removed '${launchDaemonPath}'"

            # Uninstall Script
            info "Uninstall Script … "
            logComment "Removing '${organizationDirectory}/${organizationScriptName}-unhealthy.zsh' … "
            rm -f "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"
            logComment "Removed '${organizationDirectory}/${organizationScriptName}-unhealthy.zsh' "

            # Uninstall .plist
            info "Uninstall .plist … "
            logComment "Removing '${plistFilepath}' … "
            rm -f "${plistFilepath}"
            logComment "Removed '${plistFilepath}'"

            # Exit
            logComment "Uninstalled all ${humanReadableScriptName} configuration files"
            notice "Thanks for using ${humanReadableScriptName}!"
            exit 0
            ;;
            
        * )

            warning "None of the expected reset options was entered; don't reset anything"
            ;;

    esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Write "Healthy" Plist Value
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function writeHealthyPlistValue() {

    info "Write Healthy Plist Value: \"${key}\" \"${healthyValue}\" "
    /usr/bin/defaults write "${plistFilepath}" "${key}" -string "${healthyValue}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Write "Unhealthy" Plist Value
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function writeUnhealthyPlistValue() {

    info "Write Healthy Plist Value: '${key}' '${unhealthyValue}'"
    defaults write "${plistFilepath}" "${key}" -string "${unhealthyValue}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Read Plist Value
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function readPlistValue() {

    info "Read Plist Value: '${key}'"
    writtenValue=$( defaults read "${plistFilepath}" "${key}" 2>&1 )
    logComment "'${key}' is set to '${writtenValue}'"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create "Unhealthy" Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function createUnhealthyScript() {

    info "Create 'Unhealthy' Script: ${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"

    # The following creates a script that writes the "unhealthy" value to the client-side .plist. 
    # (Note: Leave a full return at the end of the content before the last "ENDOFUNHEALTHYSCRIPT" line.)

(
cat <<ENDOFUNHEALTHYSCRIPT
#!/bin/zsh 

####################################################################################################
#
# Jamf Pro Health Check: Write Unhealthy Value
# https://snelson.us/jphc
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin




####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo "${organizationScriptName}-unhealthy ($scriptVersion): \$( date +%Y-%m-%d\ %H:%M:%S ) - \${1}"
}


####################################################################################################
#
# Program
#
####################################################################################################

updateScriptLog "\n\n***\n* Jamf Pro Health Check: Write Unhealthy Value\n***\n"

updateScriptLog "Current Status"
defaults read "${plistFilepath}" "${key}"

updateScriptLog "Change Status"
defaults write "${plistFilepath}" "${key}" -string "${unhealthyValue}"

updateScriptLog "Updated Status"
defaults read "${plistFilepath}" "${key}"

exit 0

ENDOFUNHEALTHYSCRIPT
) > "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"

    logComment "Unhealthy script created"
    logComment "Setting permissions …"

    chmod 755 "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"
    chown root:wheel "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function createLaunchDaemon() {

    info "Create LaunchDaemon"

    # The following creates the LaunchDaemon file which executes the "unhealthy" script
    # (Note: Leave a full return at the end of the content before the last "ENDOFLAUNCHDAEMON" line.)

logComment "Creating '${launchDaemonPath}' …"

(
cat <<ENDOFLAUNCHDAEMON
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${launchDaemonName}</string>
    <key>UserName</key>
    <string>root</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${organizationDirectory}/${organizationScriptName}-unhealthy.zsh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>0</integer>
        <key>Minute</key>
        <integer>1</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>${scriptLog}</string>
    <key>StandardOutPath</key>
    <string>${scriptLog}</string>
</dict>
</plist>

ENDOFLAUNCHDAEMON
)  > "${launchDaemonPath}"

    logComment "Setting permissions for '${launchDaemonPath}' …"
    chmod 644 "${launchDaemonPath}"
    chown root:wheel "${launchDaemonPath}"

    logComment "Loading '${launchDaemonName}' …"
    launchctl bootstrap system "${launchDaemonPath}"
    launchctl start "${launchDaemonPath}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# LaunchDaemon Status
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function launchDaemonStatus() {

    info "LaunchDaemon Status"
    
    launchDaemonStatus=$( launchctl list | grep "${launchDaemonName}" )

    if [[ -n "${launchDaemonStatus}" ]]; then
        logComment "${launchDaemonStatus}"
    else
        logComment "${launchDaemonName} is NOT loaded"
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
        preFlight "Created specified scriptLog: ${scriptLog}"
    else
        fatal "Unable to create specified scriptLog '${scriptLog}'; exiting.\n\n(Is this script running as 'root' ?)"
    fi
else
    preFlight "Specified scriptLog '${scriptLog}' exists; writing log entries to it"
fi




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# https://snelson.us\n###\n"
preFlight "Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    fatal "This script must be run as root; exiting."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Organization Directory
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -d "${organizationDirectory}" ]]; then
    preFlight "Specified Organization Directory of '${organizationDirectory}' exists; proceeding …"
else
    fatal "The specified Organization Directory of '${organizationDirectory}' is NOT found; exiting."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Vendor Directory
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -d "${vendorDirectory}" ]]; then
    preFlight "Specified Vendor Directory of '${vendorDirectory}' exists; proceeding …"
else
    fatal "The specified Vendor Directory of '${vendorDirectory}' is NOT found; exiting."
fi



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
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resetConfiguration "${resetConfiguration}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Validation / Creation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "*** VALIDATING SCRIPT ***"

if [[ -f "${organizationDirectory}/${organizationScriptName}-unhealthy.zsh" ]]; then

    logComment "Unhealthy script '"${organizationDirectory}/${organizationScriptName}-unhealthy.zsh"' exists"

else

    createUnhealthyScript

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# LaunchDaemon Validation / Creation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "*** VALIDATING LAUNCHDAEMON ***"

logComment "Checking for LaunchDaemon '${launchDaemonPath}' …"

if [[ -f "${launchDaemonPath}" ]]; then

    # logComment "LaunchDaemon '${launchDaemonPath}' exists"

    launchDaemonStatus

else

    createLaunchDaemon

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Status Checks
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "*** STATUS CHECKS ***"

launchDaemonStatus

sleep 0.8

writeHealthyPlistValue

readPlistValue



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "*** Thank you! ***"

exit 0