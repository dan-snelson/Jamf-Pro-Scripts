#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   CrowdStrike Falcon Tags
#       - See: https://snelson.us/2023/01/grouping-tag-hacks/
#
#   Inspired by:
#       - Phillip Boushy
#       - https://macadmins.slack.com/archives/CA9SU2FSS/p1617295375480700?thread_ts=1617196227.417300&cid=CA9SU2FSS
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 19-Jan-2023, Dan K. Snelson (@dan-snelson)
#   - Original version
#
#   Version 0.0.2, 22-Jan-2023, Dan K. Snelson (@dan-snelson)
#   - Changed exit status when 'groupingTags' not found in com.crowdstrike.falcon.plist
#
#   Version 0.0.3, 27-Jan-2023, Dan K. Snelson (@dan-snelson)
#   - Changed exit status when 'groupingTags' not found in com.crowdstrike.falcon.plist
#
#   Version 0.0.4, 31-Jan-2023, Dan K. Snelson (@dan-snelson)
#   - Added Palo Alto Networks GlobalProtect HIP-compatibility
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
# Confirm CrowdStrike Falcon is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -d "/Applications/Falcon.app" ]]; then
    echo "CrowdStrike Falcon installed; proceeding …"
else
    echo "CrowdStrike Falcon NOT found; exiting."
    exit #1
fi



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="0.0.4"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
falconBinary="/Applications/Falcon.app/Contents/Resources/falconctl"
scriptLog="${4:-"/var/log/com.company.log"}"
plist="/Library/Preferences/com.crowdstrike.falcon.plist"
maintenanceToken="${5:-"J8E6N7N5Y3J0E9N9NYJ8E6N7N5Y3J0E9N9NY"}"   # [ CrowdStrike Maintenance Token ]
mode="${6:-"reset"}"                                              # [ get | set | clear | reset (default) ]
tags="${7:-"Server,Lane,Site"}"                                   # [ Server,Lane,Site (default) ]
exitCode="0"



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
# Get CrowdStrike Falcon Tags
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getCrowdStrikeFalconTags() {

    # updateScriptLog "# Get CrowdStrike Falcon Tags:"

    currentTags=$("${falconBinary}" grouping-tags get | sed 's/.*: //')

    if [[ "${currentTags}" == *" "* ]]; then
        currentTags=""
    fi

    updateScriptLog "# Current Tags: ${currentTags}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set CrowdStrike Falcon Tags
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function setCrowdStrikeFalconTags() {

    updateScriptLog "# Set CrowdStrike Falcon Tags"
    if [[ -n "${tags}" ]]; then
        updateScriptLog "• New Tags: ${tags}"
        "${falconBinary}" grouping-tags set "$tags" | tee -a "${scriptLog}"
    else
        updateScriptLog "• Tags [Parameter 7] is blank; nothing to set"
        exitCode="1"
    fi

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Clear CrowdStrike Falcon Tags
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function clearCrowdStrikeFalconTags() {

    updateScriptLog "# Clear CrowdStrike Falcon Tags"
    "${falconBinary}" grouping-tags clear | sed 's/.*: //' | tee -a "${scriptLog}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset CrowdStrike Falcon Tags
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetCrowdStrikeFalconTags() {

    updateScriptLog "# Reset CrowdStrike Falcon Tags"

    if [[ -f "/Library/Managed Preferences/com.crowdstrike.falcon.plist" ]]; then
        tags=$( defaults read /Library/Managed\ Preferences/com.crowdstrike.falcon.plist groupingTags 2>&1 )
    else
        updateScriptLog "• com.crowdstrike.falcon.plist NOT found; exiting"
        exitCode="0" #1
    fi

    if [[ ${tags} == *"does not exist"* ]]; then
        updateScriptLog "• 'groupingTags' not found in com.crowdstrike.falcon.plist; exiting with warning"
        exitCode="0"
    else
        updateScriptLog "• Resetting Tags: ${tags}"
        "${falconBinary}" grouping-tags set "$tags" | tee -a "${scriptLog}"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Restart CrowdStrike Falcon
# shellcheck disable=SC2317
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function restartCrowdStrikeFalcon() {

    updateScriptLog "# Restarting CrowdStrike Falcon"

    if [[ -z "${1}" ]]; then

        updateScriptLog "• Unloading CrowdStrike Falcon sensor (sans Maintenance Token) …"
        "${falconBinary}" unload | tee -a "${scriptLog}"

    else

        updateScriptLog "• Unloading CrowdStrike Falcon sensor …"
        unloadCommand=$( expect <<EOF
spawn sudo "${falconBinary}" unload --maintenance-token
expect "Token:"
send "${1}\r"
expect "*#*"
EOF
)

        # updateScriptLog "unloadCommand: ${unloadCommand}"

        if [[ ${unloadCommand} == *"Error"* ]]; then
            updateScriptLog "• Result: $(echo "${unloadCommand}" | tail -n1)"
            exitCode="1"
        else
            updateScriptLog "• Result: $(echo "${unloadCommand}" | tail -n1)"
            updateScriptLog "• Loading CrowdStrike Falcon sensor …"
            "${falconBinary}" load | tee -a "${scriptLog}"
        fi

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

updateScriptLog "\n\n###\n# CrowdStrike Falcon Tags (${scriptVersion})\n###\n"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Palo Alto Networks GlobalProtect HIP-compatibility 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n# # #\n# Palo Alto Networks GlobalProtect HIP-compatibility\n# # #\n"

if [[ -f "/Library/Managed Preferences/com.crowdstrike.falcon.plist" ]]; then
    updateScriptLog "Creating hard link of 'com.crowdstrike.falcon.plist' …"
    ln -v "/Library/Managed Preferences/com.crowdstrike.falcon.plist" "${plist}" | tee -a "${scriptLog}"
else
    updateScriptLog "• com.crowdstrike.falcon.plist NOT found; exiting with error"
    exitCode="1"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute specified mode option
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n# # #\n# Executing specified mode option: '${mode}'\n# # #\n"

case ${mode} in

    "get" )
        getCrowdStrikeFalconTags
        ;;

    "set" )
        getCrowdStrikeFalconTags
        setCrowdStrikeFalconTags
        getCrowdStrikeFalconTags
        # restartCrowdStrikeFalcon "${maintenanceToken}"
        ;;

    "clear" )
        getCrowdStrikeFalconTags
        clearCrowdStrikeFalconTags
        getCrowdStrikeFalconTags
        # restartCrowdStrikeFalcon "${maintenanceToken}"
        ;;

    "reset" )
        getCrowdStrikeFalconTags
        resetCrowdStrikeFalconTags
        getCrowdStrikeFalconTags
        # restartCrowdStrikeFalcon "${maintenanceToken}"
        ;;

    * )
        updateScriptLog "• Catch-all: ${mode}; exiting with error"
        exitCode="1"
        ;;

esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Exit Code: ${exitCode}"

exit "${exitCode}"