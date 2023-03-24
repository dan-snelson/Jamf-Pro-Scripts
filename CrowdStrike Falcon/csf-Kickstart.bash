#!/bin/bash

####################################################################################################
#
#   CrowdStrike Falcon Kickstart
#
#   Purpose: Load CrowdStrike Falcon's Sensor
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1, 28-Feb-2023, Dan K. Snelson (@dan-snelson)
#   Original version
#
# Version 0.0.2, 10-Mar-2023, Dan K. Snelson (@dan-snelson)
#   Added licensing step
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.2"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
falconBinary="/Applications/Falcon.app/Contents/Resources/falconctl"
scriptLog="${4:-"/var/log/com.company.log"}"    # Parameter 4: Full path to your company's client-side log
exitCode="0"



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

updateScriptLog "\n\n###\n# CrowdStrike Falcon Kickstart (${scriptVersion})\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm CrowdStrike Falcon is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f "${falconBinary}" ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon installed; proceeding …"
else
    updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon NOT found; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm CrowdStrike Falcon CCID
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

ccidTest=$( defaults read "/Library/Preferences/com.crowdstrike.falcon.plist" ccid 2>&1 )
if [[ "${ccidTest}" == *"does not exist"* ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon CCID NOT found; exiting."
    exit 1
else
    updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon CCID found; proceeding …"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm CrowdStrike Falcon System Extension is running
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

systemExtensionTest=$( systemextensionsctl list | grep -o "com.crowdstrike.falcon.Agent.*" | cut -f2- -d" " )
if [[ -n "${systemExtensionTest}" ]]; then
    systemExtensionStatus="${systemExtensionTest}"
else
    systemExtensionStatus="Not Found"
fi

updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon System Extension Status:"
updateScriptLog "${systemExtensionStatus}"



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
# Process CrowdStrike Falcon System Extension Status
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Processing System Extension Status …"

case ${systemExtensionStatus} in

    *"[activated enabled]"* )
        updateScriptLog "CrowdStrike Falcon System Extension enabled"

        updateScriptLog "Validating Sensor Operation …"
        sensorOperationalStatus=$( $falconBinary stats agent_info | awk '/Sensor operational:/{print $3}' )

        if [[ "${sensorOperationalStatus}" == "true" ]]; then

            updateScriptLog "Falcon Sensor Operational: ${sensorOperationalStatus}"
            updateScriptLog "Updating inventory …"
            jamf recon
            exitCode="0"

        else

            updateScriptLog "Attempting to kickstart Falcon Sensor …"

            falconKickStartLicense=$( ${falconBinary} license "$( defaults read /Library/Managed\ Preferences/com.crowdstrike.falcon.plist ccid )" --noload --verbose)
            updateScriptLog "Falcon Kickstart License Result: ${falconKickStartLicense}"

            falconKickStartLoad=$( ${falconBinary} load -verbose )
            updateScriptLog "Falcon Kickstart Load Result: ${falconKickStartLoad}"

            if [[ "${falconKickStartLoad}" == "Falcon sensor is loaded" ]]; then

                sensorOperationalStatus=$( $falconBinary stats agent_info | awk '/Sensor operational:/{print $3}' )

                if [[ "${sensorOperationalStatus}" == "true" ]]; then

                    updateScriptLog "Falcon Sensor Operational: ${sensorOperationalStatus}"
                    updateScriptLog "Updating inventory …"
                    jamf recon
                    exitCode="0"

                fi

            else

                exitCode="1"

            fi

            exitCode="0"

        fi
        ;;

    "Not Found" )

        updateScriptLog "CrowdStrike Falcon System Extension NOT found"

        updateScriptLog "Attempting re-installation …"
        falconKickStartUninstall=$( ${falconBinary} uninstall -verbose )
        updateScriptLog "Falcon Kickstart Uninstall Result: ${falconKickStartUninstall}"

        updateScriptLog "Updating computer inventory …"
        jamf recon

        updateScriptLog "Re-installing CrowdStrike Falcon …"
        jamf policy -trigger crowdStrikeFalcon

        exitCode="1"
        ;;

    * )
        updateScriptLog "Code for 'Catch-all' goes here"
        exitCode="1"
        ;;

esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Exit Code: ${exitCode}"

exit "${exitCode}"