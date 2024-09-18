#!/bin/zsh --no-rcs 
# shellcheck shell=bash

####################################################################################################
#
# EDR Script Runner
#
#   Purpose: Executes the specified EDR Script
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1, 05-Sep-2024, Dan K. Snelson (@dan-snelson)
#   - Original, proof-of-concept version
#
# Version 0.0.2, 05-Sep-2024, Dan K. Snelson (@dan-snelson)
#   - Renamed .plist key to "EDR Script Runner"
#
# Version 0.0.3, 11-Sep-2024, Dan K. Snelson (@dan-snelson)
#   - Removed the output of various variables
#
# Version 0.0.4, 18-Sep-2024, Dan K. Snelson (@dan-snelson)
#   - Code clean-up
#
# Version 0.0.5, 18-Sep-2024, Dan K. Snelson (@dan-snelson)
#   - Added `checksumSource` Jamf Pro Script Parameter (thanks for the idea, AB!)
#
####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="0.0.5"

# Client-side Log
scriptLog="/var/log/org.test.log"

# Initialize SECONDS
SECONDS="0"

# Temporary Working Directory
workDirectory=$( basename "${0%%.*}" )
tempDirectory=$( mktemp -d "/private/tmp/$workDirectory.XXXXXX" )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Script Human-readabale Name
humanReadableScriptName="EDR Script Runner"

# Organization's Script Name
organizationScriptName="EDRr"

# Organization's Repository
orgRepo="https://raw.githubusercontent.com/dan-snelson/Jamf-Pro-Scripts/development/EDR/"

# Organization's File
orgFile="edrScript.zsh"

# Organization's .plist
orgPlist="/Library/Preferences/org.test.plist"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Parameter 4: Checksum Source [ script (default) | policy ]
checksumSource="${4:-"script"}"

# Parameter 5: Expected Script Checksum
case ${checksumSource} in
    script      )   expectedScriptChecksum=$( curl --location --silent --fail "${orgRepo}/${orgFile%%.*}Hash.txt" ) ;;
    policy | *  )   expectedScriptChecksum="${5:-"55b9765ed20cd1563382e79d5af7f5505fb6be55488c9b1c7effbfe2b64c8c3b"}" ;;
esac



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

function debug() {
    if [[ "$operationMode" == "debug" ]]; then
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
# Write Plist Value
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function writePlistValue() {

    # Variables
    key="${1}"      # Name of the "key" for which the value will be set
    value="${2}"    # The value to which "key" will be set

    notice "Write Plist Value: '${key}' '${value}'"
    defaults write "${orgPlist}" "${key}" -string "${value}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Read Plist Value
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function readPlistValue() {

    # Variables
    key="${1}"        # Name of the "key" for which the value will be set

    notice "Read Plist Value: '${key}'"
    writtenValue=$( defaults read "${orgPlist}" "${key}" 2>/dev/null )
    if [[ -n "${writtenValue}" ]]; then
        logComment "${writtenValue}"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for running processes (supplied as Parameter 1)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function procesStatus() {

    processToCheck="${1}"
    logComment "Process: ${processToCheck}"
    processToCheckStatus=$( /usr/bin/pgrep -x "${processToCheck}" )
    if [[ -n ${processToCheckStatus} ]]; then
        processCheckResult+="'${processToCheck}' running; "
    else
        processCheckResult+="'${processToCheck}' NOT running; "
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    rm -Rf "${tempDirectory}"
    info "Elapsed Time: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"
    quitOut "End-of-line."
    exit "${1}"

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

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# Checksum Source: ${checksumSource}\n###\n"
preFlight "Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    fatal "This script must be run as root; exiting."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Organization's .plist
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${orgPlist}" ]]; then
    touch "${orgPlist}"
    if [[ -f "${orgPlist}" ]]; then
        preFlight "Created Organization's .plist"
        chown root:wheel "${orgPlist}"
        chmod 0644 "${orgPlist}"
    else
        fatal "Unable to create Organization's .plist; exiting.\n\n(Is this script running as 'root' ?)"
    fi
else
    preFlight "Specified Organization's .plist exists"
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
# Download Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "Download Script"

curl --location --silent --fail "${orgRepo}/${orgFile}" -o "${tempDirectory}/${orgFile}"

if [[ "$?" == "0" ]]; then

    actualScriptChecksum=$( openssl dgst -sha256 "${tempDirectory}/${orgFile}" | awk -F'= ' '{print $2}' )
    if [[ "${expectedScriptChecksum}" != "${actualScriptChecksum}" ]]; then
        fatal "SCRIPT CHECKSUM FAILED; EXITING"
    else
        notice "Script Checksum Passed"
        chmod a+x "${tempDirectory}/${orgFile}"
    fi

else

    fatal "DOWNLOAD FAILED; EXITING"

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Last Execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

readPlistValue "EDR Script Runner"

lastModification="$( grep "scriptModificationTimestamp" "${tempDirectory}/${orgFile}" | awk -F= '{print $2}' )"
lastModification=${lastModification//\"/}
notice "Script Modification Timestamp: $lastModification"
if [[ "${writtenValue}" == "${lastModification}" ]]; then
    quitOut "Execution NOT required; exiting"
    quitScript "0"
else
    notice "Executing …"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run EDR Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

eval "${tempDirectory}/${orgFile}"

writePlistValue "EDR Script Runner" "${lastModification}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

quitScript "0"