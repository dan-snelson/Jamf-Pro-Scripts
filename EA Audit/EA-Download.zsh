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
# Version 1.0.0, 30-Sep-2025, Dan K. Snelson (@dan-snelson)
#   - First "official" version (tested with Jamf Pro 11.21.0)
#
# Version 1.0.1, 04-Mar-2026, Dan K. Snelson (@dan-snelson)
#   - Added pagination so discovery is complete when there are more than 100 EAs (thanks for the heads-up, I.S.!)
#   - Added discovery summary logging and masked sensitive credentials in DEBUG logs
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="1.0.1"

# Client-side Log
scriptLog="org.churchofjesuschrist.log"

# Log Level [ DEBUG, INFO, WARNING, ERROR ]
logLevel="DEBUG"

# Path of the current script
typeset -gr scriptPath=${(%):-%x}   
typeset -gr scriptName=${scriptPath:t}
typeset -gr scriptBase=${scriptPath:t:r}


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

function logDebug()     { [[ "$logLevel" == "DEBUG" ]] && log DEBUG "$@"; }
function logError()     { log ERROR "$@"; }
function logFatal()     { log FATAL "$@"; exit 1; }
function logInfo()      { log INFO "$@"; }
function logNotice()    { log NOTICE "$@"; }
function logWarn()      { log WARNING "$@"; }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Mask credentials for display
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function maskCredential() {
    local credential="${1}"
    if [[ -z "${credential}" ]] || [[ ${#credential} -lt 7 ]]; then
        echo "***"
    else
        echo "${credential:0:3}$(printf '%*s' $((${#credential}-4)) '' | tr ' ' '*')${credential: -3}"
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Help
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function help() {

    local apiURL=$( /usr/bin/defaults read "/Library/Preferences/com.jamfsoftware.jamf.plist" jss_url )
    printf "\nAfter creating a Jamf Pro API Role and Client with the \"Read Computer Extension Attributes\" privilege,\n"
    printf "use the following commands to create entries in Keychain Access:\n\n"
    printf "    security add-generic-password -s \"${organizationScriptName:l}ApiUrl\" -a ${USER} -w \"${apiURL}\"\n"
    printf "    security add-generic-password -s \"${organizationScriptName:l}ApiClientID\" -a ${USER} -w \"API Client ID Goes Here\"\n"
    printf "    security add-generic-password -s \"${organizationScriptName:l}ApiClientSecret\" -a ${USER} -w \"API Client Secret Goes Here\""
    printf "\n\nUse \"zsh ${scriptName} configuration\" with logLevel set to DEBUG to display API credentials.\n\n\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function configuration() {

    logNotice "Configuration:"
    local apiURL=$( security find-generic-password -s "${organizationScriptName:l}ApiUrl" -a "${USER}" -w 2>/dev/null )
    local apiClientID=$( security find-generic-password -s "${organizationScriptName:l}ApiClientID" -a "${USER}" -w 2>/dev/null )
    local apiClientSecret=$( security find-generic-password -s "${organizationScriptName:l}ApiClientSecret" -a "${USER}" -w 2>/dev/null )

    if [ -z ${apiURL} ] || [ -z ${apiClientID} ] || [ -z ${apiClientSecret} ]; then
        logFatal "Unable to read API credentials. Please run \"zsh ${scriptName} help\" to configure API credentials."
    else
        if [[ ${logLevel} == "DEBUG" ]]; then
            logDebug "Displaying API credentials in plain text (logLevel is set to DEBUG)"
            echo "          URL: ${apiURL}"
            echo "    Client ID: ${apiClientID}"
            echo "Client Secret: ${apiClientSecret}"
        else
            logInfo "Displaying masked API credentials (logLevel is not set to DEBUG)"
            maskedApiURL=$(maskCredential "${apiURL}")
            maskedApiClientID=$(maskCredential "${apiClientID}")
            maskedApiClientSecret=$(maskCredential "${apiClientSecret}")
            echo "          URL: ${apiURL}"
            echo "    Client ID: ${maskedApiClientID}"
            echo "Client Secret: ${maskedApiClientSecret}"
        fi
    fi

    printf "\n\n\nUse the following commands to update entries in Keychain Access:\n\n"
    printf "    security add-generic-password -U -s \"${organizationScriptName:l}ApiUrl\" -a ${USER} -w \"${apiURL}\"\n"
    printf "    security add-generic-password -U -s \"${organizationScriptName:l}ApiClientID\" -a ${USER} -w \"API Client ID Goes Here\"\n"
    printf "    security add-generic-password -U -s \"${organizationScriptName:l}ApiClientSecret\" -a ${USER} -w \"API Client Secret Goes Here\"\n\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Obtain Bearer Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function obtainBearerToken() {
    
    logNotice "Obtain Bearer Token …"

    apiBearerToken=$( curl -s -X POST "${apiURL}/api/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${apiClientID}" \
    --data-urlencode "client_secret=${apiClientSecret}" \
    --data-urlencode "grant_type=client_credentials" \
    | jq -r '.access_token' )

    logDebug "apiBearerToken: $(maskCredential "${apiBearerToken}")"

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
        logError "INVALID API CREDENTIALS"
        logError "Please run \"zsh ${scriptName} configuration\" with logLevel set to DEBUG to display API credentials."
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

    logNotice "Invalidating bearer token..."

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

    logNotice "Generate Extension Attribute List …"

    local page=0
    local pageSize=100
    local totalCount=0
    local fetchedCount=0
    local pagesFetched=0
    local pageResultCount=0
    local pagedResponse
    local pagedResultsFile="${workingDirectory}/extensionAttributeList.pages.jsonl"
    local discoveredCount=0

    : > "${pagedResultsFile}"

    while true; do

        pagedResponse=$( curl -s -X GET "${apiURL}/api/v1/computer-extension-attributes?page=${page}&page-size=${pageSize}" \
            --header "Authorization: Bearer ${apiBearerToken}" )

        if [[ -z "${pagedResponse}" ]]; then
            logFatal "Empty response received while requesting page ${page}; exiting."
        fi

        if ! jq -e . >/dev/null 2>&1 <<< "${pagedResponse}"; then
            logFatal "Invalid JSON response received while requesting page ${page}; exiting."
        fi

        # Use printf (not echo) so JSON escape sequences are preserved verbatim.
        printf '%s\n' "${pagedResponse}" >> "${pagedResultsFile}"

        if (( page == 0 )); then
            totalCount=$(jq -r '.totalCount // 0' <<< "${pagedResponse}")
            logDebug "Total Extension Attributes reported by API: ${totalCount}"
        fi

        pageResultCount=$(jq -r '(.results // []) | length' <<< "${pagedResponse}")
        (( fetchedCount += pageResultCount ))
        if (( pageResultCount > 0 )); then
            (( pagesFetched += 1 ))
        fi
        (( page += 1 ))

        logDebug "Fetched page ${page} (${pageResultCount} records; ${fetchedCount}/${totalCount})"

        if (( pageResultCount == 0 )); then
            break
        fi

        if (( totalCount > 0 && fetchedCount >= totalCount )); then
            break
        fi

    done

    if ! jq -s '{
        totalCount: (.[0].totalCount // ([.[].results[]?] | length)),
        results: [.[].results[]?]
    }' "${pagedResultsFile}" > "${workingDirectory}/extensionAttributeList.json"; then
        logFatal "Failed to merge paged extension attribute responses into extensionAttributeList.json; exiting."
    fi

    rm -f "${pagedResultsFile}"

    # Check if the downloaded file is zero bytes
    if [[ ! -s "${workingDirectory}/extensionAttributeList.json" ]]; then
        logFatal "Downloaded ${workingDirectory}/extensionAttributeList.json is empty (zero bytes); exiting."
    else
        extensionAttributeIDs=$(jq -r '.results[].id'  "${workingDirectory}/extensionAttributeList.json")
        extensionAttributeNames=$(jq -r '.results[].name' "${workingDirectory}/extensionAttributeList.json")
        discoveredCount=$(jq -r '(.results // []) | length' "${workingDirectory}/extensionAttributeList.json")
        logInfo "Discovered ${discoveredCount} Extension Attributes across ${pagesFetched} page(s)."
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
    logNotice "Extracting Script Extension Attributes…"
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
            echo "# Extracted on: ${dateTimeStamp} by ${humanReadableScriptName} (${scriptVersion}) from https://snelson.us/audit"
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
logInfo "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# https://snelson.us/audit\n#\n# Log Level: ${logLevel}\n###\n"



# Check for help command
if [[ "${1}" = "help" ]]; then

    logNotice "Displaying Help …"
    help
    exit 0



# Check for configuration command
elif [[ "${1}" = "configuration" ]]; then

    logNotice "Displaying Configuration …"
    configuration
    exit 0


# Download Extension Attributes
else

    # Retrieve API Credentials from Keychain
    logInfo "Retrieve API Credentials from Keychain …"
    local apiURL=$( security find-generic-password -s "${organizationScriptName:l}ApiUrl" -a "${USER}" -w 2>/dev/null )
    local apiClientID=$( security find-generic-password -s "${organizationScriptName:l}ApiClientID" -a "${USER}" -w 2>/dev/null )
    local apiClientSecret=$( security find-generic-password -s "${organizationScriptName:l}ApiClientSecret" -a "${USER}" -w 2>/dev/null )

    if [ -z ${apiURL} ] || [ -z ${apiClientID} ] || [ -z ${apiClientSecret} ]; then
        logFatal "Unable to read API credentials. Please run \"zsh ${scriptName} help\" to configure API credentials."
    fi

    if [[ ${logLevel} == "DEBUG" ]]; then
        maskedApiClientID=$(maskCredential "${apiClientID}")
        maskedApiClientSecret=$(maskCredential "${apiClientSecret}")
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
