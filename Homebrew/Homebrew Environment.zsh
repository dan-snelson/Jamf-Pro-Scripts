#!/bin/zsh --no-rcs 
# shellcheck shell=bash

####################################################################################################
#
# Homebrew Environment
#
# See: https://docs.brew.sh/Manpage#environment
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 26-Jul-2024, Dan K. Snelson (@dan-snelson)
#   - Original version
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Script Version
scriptVersion="0.0.1"

# Client-side Log
scriptLog="/var/log/org.churchofjesuschrist.log"

# Current Date and Time
currentDateAndTime="$( date '+%Y-%m-%d-%H%M%S' )"

# Homebrew Environment File Path 
homebrewEnvironmentFilePath="/etc/homebrew/brew.env"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Script Human-readabale Name
humanReadableScriptName="Homebrew Environment"

# Organization's Script Name
organizationScriptName="Brew Env"



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

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n###\n"
preFlight "Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    fatal "This script must be run as root; exiting."
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
# Backup Existing / Create ${homebrewEnvironmentFilePath}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -e "${homebrewEnvironmentFilePath}" ]]; then
    notice "Found existing ${homebrewEnvironmentFilePath}; creating backup …"
    cp -v "${homebrewEnvironmentFilePath}" "${homebrewEnvironmentFilePath}-backup-$( date '+%Y-%m-%d-%H%M%S' )"
else
    notice "Creating ${homebrewEnvironmentFilePath} …"
    mkdir -p "${homebrewEnvironmentFilePath%/*}"
    # chmod 644 "${homebrewEnvironmentFilePath%/*}"
    touch "${homebrewEnvironmentFilePath}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create Homebrew Environment
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notice "Create Homebrew Environment"

(
cat <<ENDOFBREWENV
###
#
# ${humanReadableScriptName} (${scriptVersion})
# Created: ${currentDateAndTime}
# See: https://docs.brew.sh/Manpage#environment
#
###



# Cleanup all cached files older than this many days.
HOMEBREW_CLEANUP_MAX_AGE_DAYS=90

# If set, pass '--verbose' when invoking curl(1).
HOMEBREW_CURL_VERBOSE

# Print install times for each formula at the end of the run.
HOMEBREW_DISPLAY_INSTALL_TIMES

# Output this many lines of output on formula system failures.
HOMEBREW_FAIL_LOG_LINES=30

# A space-separated list of casks. Homebrew will refuse to install a cask if it or any of its dependencies is on this list.
HOMEBREW_FORBIDDEN_CASKS=anaconda

# A space-separated list of formulae. Homebrew will refuse to install a formula or cask if it or any of its dependencies is on this list.
HOMEBREW_FORBIDDEN_FORMULAE=anaconda

# Print this text before the installation summary of each successful build.
HOMEBREW_INSTALL_BADGE=⛪

ENDOFBREWENV
) > "${homebrewEnvironmentFilePath}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

quitOut "Shine on, you crazy diamonds!"

exit 0