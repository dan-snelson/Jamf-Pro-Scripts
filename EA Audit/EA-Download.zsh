#!/bin/zsh --no-rcs 
# shellcheck shell=bash

####################################################################################################
#
# EA Download
#
#   Purpose: Command-line script to download Jamf Cloud-hosted Extension Attributes (EAs)
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1, 30-Jun-2025, Dan K. Snelson (@dan-snelson)
#   - Initial, proof-of-concept version
#
# Version 0.0.2, 30-Jun-2025, Dan K. Snelson (@dan-snelson)
#   - Simplified the script extraction logic
#
# Version 0.0.3, 30-Jun-2025, Dan K. Snelson (@dan-snelson)
#   - Improved script output
#
# Version 0.0.4, 30-Jun-2025, Dan K. Snelson (@dan-snelson)
#   - Refactored API token handling
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="0.0.4"

# Client-side Log
scriptLog="org.churchofjesuschrist.log"

# Log Level [ DEBUG, INFO, WARNING, ERROR ]
logLevel="INFO"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Script Human-readabale Name
humanReadableScriptName="EA Download"

# Organization's Script Name
organizationScriptName="EAD"

# Date Time Stamp
dateTimeStamp=$( date '+%Y-%m-%d-%H%M%S' )



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function log() {
  echo "${organizationScriptName} ($scriptVersion): $( date +%Y-%m-%d\ %H:%M:%S ) - [${1}] ${2}" | tee -a "${workingDirectory}/${scriptLog}"
}

function logInfo()  { log INFO "$@"; }
function logWarn()  { log WARNING "$@"; }
function logError() { log ERROR "$@"; }
function logFatal() { log FATAL "$@"; exit 1; }
function logDebug() { [[ "$logLevel" == "DEBUG" ]] && log DEBUG "$@"; }



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Help
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function help() {

    local apiURL=$( /usr/bin/defaults read "/Library/Preferences/com.jamfsoftware.jamf.plist" jss_url )
    printf "\nAfter creating a Jamf Pro API Role and Client with the \"Read Computer Extension Attributes\" privilege,\n"
    printf "use the following commands to create entries in Keychain Access:\n\n"
    printf "    security add-generic-password -s \"${organizationScriptName:l}ApiUrl\" -a ${USER} -w \"${apiURL}\"\n"
    printf "    security add-generic-password -s \"${organizationScriptName:l}ApiClientID\" -a ${USER} -w \"API Client ID Goes Here\"\n"
    printf "    security add-generic-password -s \"${organizationScriptName:l}ApiClientSecret\" -a ${USER} -w \"API Client Secret Goes Here\"\n\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Obtain Bearer Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function obtainBearerToken() {
    
    logInfo "Obtain Bearer Token …"

    apiBearerToken=$( curl -s -X POST "${apiURL}/api/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${apiClientID}" \
    --data-urlencode "client_secret=${apiClientSecret}" \
    --data-urlencode "grant_type=client_credentials" \
    | jq -r '.access_token' )

    logDebug "apiBearerToken: ${apiBearerToken}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Bearer Token (returns the HTTP status code)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateBearerToken() {

    apiBearerTokenCheck=$( curl -s -o /dev/null -w "%{http_code}" "${apiURL}/api/v1/auth" \
        --request GET \
        --header "Authorization: Bearer ${apiBearerToken}")

    logDebug "apiBearerTokenCheck: ${apiBearerTokenCheck}"

    if [[ "${apiBearerTokenCheck}" != 200 ]]; then
        logFatal "Error: ${apiBearerTokenCheck}; exiting."
    else
        logInfo "Bearer Token is valid."
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate and optionally renew the Bearer Token; returns the HTTP status code
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateRenewBearerToken() {

    validateBearerToken
    
    if [[ "${apiBearerTokenCheck}" = "200" ]]; then

        apiBearerToken=$( curl -s -X POST "${apiURL}/api/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "client_id=${apiClientID}" \
        --data-urlencode "client_secret=${apiClientSecret}" \
        --data-urlencode "grant_type=client_credentials" \
        | jq -r '.access_token' )

    else

        logInfo "Expired Bearer Token; renewing …"
        obtainBearerToken

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Invalidate the Bearer Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function invalidateBearerToken() {

    logInfo "Invalidating bearer token..."

    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${apiURL}/api/v1/auth/invalidate-token" \
        -H "accept: application/json" \
        -H "Authorization: Bearer $apiBearerToken")

    if [[ "$response" == "204" ]]; then
        logInfo "Bearer token invalidated successfully."
    else
        logWarn "Failed to invalidate bearer token. HTTP Status: $response"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Generate Extension Attribute List
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function generateExtensionAttributeList() {

    logInfo "Generate Extension Attribute List …"
    
    extensionAttributeList=$( curl -s -X GET "${apiURL}/api/v1/computer-extension-attributes" \
        --header "Authorization: Bearer ${apiBearerToken}" \
        -o "${workingDirectory}/extensionAttributeList.json" )

    # Check if the downloaded file is zero bytes
    if [[ ! -s "${workingDirectory}/extensionAttributeList.json" ]]; then
        logFatal "Downloaded ${workingDirectory}/extensionAttributeList.json is empty (zero bytes); exiting."
    else
        extensionAttributeIDs=$( jq -r '.id' "${workingDirectory}/extensionAttributeList.json" )
        extensionAttributeNames=$( jq -r '.name' "${workingDirectory}/extensionAttributeList.json" )
    fi

    if [[ "${logLevel}" == "DEBUG" ]]; then
        sortedExtensionAttributeNames=$(echo "${extensionAttributeNames}" | sort)
        logDebug "The following Script Extension Attributes will be downloaded to the ${dateTimeStamp} directory:"
        echo "${sortedExtensionAttributeNames}" | tee -a "${workingDirectory}/${scriptLog}"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Extract Script Extension Attributes
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function extractScriptExtensionAttributes() {
    logInfo "Extracting Script Extension Attributes…"
    local json_file="${workingDirectory}/extensionAttributeList.json"
    local output_dir="${workingDirectory}/scripts"

    # Create output directory
    mkdir -p "$output_dir"

    # Extract and write script contents for SCRIPT inputTypes
    while IFS= read -r entry; do
        local id name raw_script filename shebang script_body
        id=$(jq -r '.id' <<< "$entry")
        name=$(jq -r '.name | gsub("[^A-Za-z0-9_]+"; "_")' <<< "$entry")
        raw_script=$(jq -r '.script' <<< "$entry")
        filename="${output_dir}/${id}-${name}.sh"

        # Extract shebang if present
        if [[ "$raw_script" == \#!* ]]; then
            shebang=$(head -n1 <<< "$raw_script")
            script_body=$(tail -n +2 <<< "$raw_script")
        else
            shebang="#!/bin/bash"
            script_body="$raw_script"
        fi

        {
            [[ -n "$shebang" ]] && echo "$shebang"
            echo ""
            echo "###"
            echo "# Name: ${name}"
            echo "#  URL: ${apiURL}/view/settings/computer-management/computer-extension-attributes/${id}"
            echo "#   ID: ${id}"
            echo "#"
            echo "# Extracted on: ${dateTimeStamp} by ${humanReadableScriptName} (${scriptVersion}) from https://snelson.us"
            echo "###"
            echo ""
            echo "$script_body"
        } > "$filename"

        # Convert to Unix line endings
        sed -i '' $'s/\r$//' "$filename"

        chmod +x "$filename"
        echo "Extracted: $filename"
        printf "\n-------------------------\n\n"
    done < <(
        jq -c '
            .results[] |
            select(.inputType == "SCRIPT") |
            {id, name, script: .scriptContents}
        ' "$json_file"
    )
}



####################################################################################################
#
# Main Program
#
####################################################################################################

# Clear the screen
/usr/bin/clear


# Create Working Directory, based on ${dateTimeStamp}
workingDirectory="$(cd "$(dirname "$0")" && pwd)/${dateTimeStamp}"
mkdir -p "${workingDirectory}"
logInfo "Created working directory: ${workingDirectory}"

# Client-side Logging
if [[ ! -f "${workingDirectory}/${scriptLog}" ]]; then
    touch "${workingDirectory}/${scriptLog}"
    if [[ -f "${workingDirectory}/${scriptLog}" ]]; then
        logInfo "Created specified scriptLog: ${scriptLog}"
    else
        logFatal "Unable to create specified scriptLog '${scriptLog}'; exiting.\n\n(Is this script running as 'root' ?)"
    fi
else
    # logInfo "Specified scriptLog '${scriptLog}' exists; writing log entries to it"
fi



# Pre-flight Check: Logging Preamble
logInfo "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# Log Level: ${logLevel}\n###\n"



# Check for help command
if [[ "${1}" = "help" ]]; then

    logInfo "Displaying Help …"
    help
    exit 0

else

    # Retrieve API Credentials from Keychain
    logInfo "Retrieve API Credentials from Keychain …"
    local apiURL=$( security find-generic-password -s "${organizationScriptName:l}ApiUrl" -a "${USER}" -w 2>/dev/null )
    local apiClientID=$( security find-generic-password -s "${organizationScriptName:l}ApiClientID" -a "${USER}" -w 2>/dev/null )
    local apiClientSecret=$( security find-generic-password -s "${organizationScriptName:l}ApiClientSecret" -a "${USER}" -w 2>/dev/null )

    if [ -z ${apiURL} ] || [ -z ${apiClientID} ] || [ -z ${apiClientSecret} ]; then
        logFatal "Unable to read API credentials. Please run \"zsh ${0##*/} help\" to configure API credentials."
    fi

    if [[ ${logLevel} == "DEBUG" ]]; then
        maskedApiClientID="${apiClientID:0:3}$(printf '%*s' $((${#apiClientID}-4)) '' | tr ' ' '*')${apiClientID: -3}"
        maskedApiClientSecret="${apiClientSecret:0:3}$(printf '%*s' $((${#apiClientSecret}-4)) '' | tr ' ' '*')${apiClientSecret: -3}"
        logDebug "API URL: ${apiURL}"
        logDebug "API Client ID: ${maskedApiClientID}"
        logDebug "API Client Secret: ${maskedApiClientSecret}"
    else
        logInfo "API Credentials retrieved successfully."
    fi

    # Get Bearer Token
    obtainBearerToken
    validateBearerToken

    # Download Extension Attributes
    generateExtensionAttributeList
    extractScriptExtensionAttributes

    # Invalidate Bearer Token
    invalidateBearerToken

    # Open Working Directory
    open -R "${workingDirectory}"
    logInfo "Working directory opened in Finder: ${workingDirectory}"

    exit 0

fi