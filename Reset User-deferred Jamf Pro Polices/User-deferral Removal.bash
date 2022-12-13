#!/bin/bash
####################################################################################################
#
# ABOUT
#
#    Jamf Pro Policy User-deferral Removal
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 06-Dec-2022, Dan K. Snelson (@dan-snelson)
#       Original Version
#
#   Version 0.0.2, 10-Dec-2022, Dan K. Snelson (@dan-snelson)
#       Leveraged code from "Policy Delay EA" for displaying file contents
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Global Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="0.0.2"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
testFile="/Library/Application Support/JAMF/.userdelay.plist"
updateScriptLog="${4:-"/var/tmp/org.churchofjesuschrist.log"}"
policyID="${5:-"359"}"  # Policy ID to clear; use "0" for all



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateupdateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${updateScriptLog}"
}



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${updateScriptLog}" ]]; then
    touch "${updateScriptLog}"
    updateupdateScriptLog "*** Created log file via script ***"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateupdateScriptLog "\n\n###\n# Jamf Pro Policy User-deferral Removal (${scriptVersion})\n###\n"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateupdateScriptLog "This script must be run as root; exiting."
    exit 1
else
    updateupdateScriptLog "Script running as \"root\"; proceeding …"
fi



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove User Deferrals
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f "${testFile}" ]]; then

    updateupdateScriptLog "\"${testFile}\" does exists; proceeding …"

    updateupdateScriptLog "Reading contents of \"${testFile}\" … "
    # echo "$(<"$testFile")" | tee -a "${updateScriptLog}"
    plutil -p "${testFile}" | sed 's/[\"\{\}=>]//g; s/ +0000//g; s/^ *//g; s/deferStartDate /S:/g; s/lastChosenDeferDate /E:/g; 1d' | tee -a "${updateScriptLog}"

    if [[ "${policyID}" == "0" ]]; then

        updateupdateScriptLog "Removing entire \"${testFile}\" … "
        rm -v "${testFile}" | tee -a "${updateScriptLog}"

    else

        updateupdateScriptLog "Removing user deferral for Policy ID \"${policyID}\" … "
        plutil -remove "${policyID}" "${testFile}" | tee -a "${updateScriptLog}"

        updateupdateScriptLog "Reading contents of \"${testFile}\" … "
        # echo "$(<"$testFile")" | tee -a "${updateScriptLog}"
        plutil -p "${testFile}" | sed 's/[\"\{\}=>]//g; s/ +0000//g; s/^ *//g; s/deferStartDate /S:/g; s/lastChosenDeferDate /E:/g; 1d' | tee -a "${updateScriptLog}"

    fi

else

    updateupdateScriptLog "\"${testFile}\" does NOT exist"

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateupdateScriptLog "Goodbye!"

exit 0