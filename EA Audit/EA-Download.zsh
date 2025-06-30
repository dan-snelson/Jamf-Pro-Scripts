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
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="0.0.1"

# Client-side Log
scriptLog="org.churchofjesuschrist.log"

# Log Level [ DEBUG, INFO, WARNING, ERROR ]
logLevel="DEBUG"



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
    
    validateBearerToken

    if [[ "${apiBearerTokenCheck}" == 200 ]]; then

        logInfo "Bearer Token still valid; invalidate …"

        apiBearerToken=$( curl "${apiURL}/api/v1/auth/invalidate-token" --silent --header "Authorization: Bearer ${apiBearerToken}" -X POST )
        apiBearerToken=""

        logInfo "Bearer Token invalidated"

    else

        logInfo "Bearer Token already expired"

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

        # Output only Script Extension Attributes (i.e., inputType.type == "SCRIPT")
        jq '.results[] | select(.inputType == "SCRIPT")' "${workingDirectory}/extensionAttributeList.json" > "${workingDirectory}/scriptExtensionAttributeList.json"

        extensionAttributeIDs=$( jq -r '.id' "${workingDirectory}/scriptExtensionAttributeList.json" )
        extensionAttributeNames=$( jq -r '.name' "${workingDirectory}/scriptExtensionAttributeList.json" )
    fi

    if [[ "${logLevel}" == "DEBUG" ]]; then
        sortedExtensionAttributeNames=$(echo "${extensionAttributeNames}" | sort)
        logDebug "The following Script Extension Attributes will be downloaded to the ${dateTimeStamp} directory:"
        echo "${sortedExtensionAttributeNames}" | tee -a "${workingDirectory}/${scriptLog}"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Extract Extension Attributes
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function extractExtensionAttributes() {
    logInfo "Extracting Extension Attributes…"
    local input_file="${workingDirectory}/scriptExtensionAttributeList.json"
    local output_dir="${workingDirectory}/scripts"

    mkdir -p "$output_dir"

    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Run JSON parsing logic inside Bash for proper read -n1 behavior
    /bin/bash <<EOF
input_file="${input_file}"
output_dir="${output_dir}"
tmp_dir="${tmp_dir}"
object_file="\$tmp_dir/object.json"

depth=0
object=""

while IFS= read -r -n1 char; do
    object+="\$char"
    if [[ "\$char" == "{" ]]; then
        ((depth++))
    elif [[ "\$char" == "}" ]]; then
        ((depth--))
    fi

    if [[ \$depth -eq 0 && -n "\$object" ]]; then
        echo "\$object" > "\$object_file"

        if jq -e 'select(.inputType == "SCRIPT")' "\$object_file" >/dev/null 2>&1; then
            id=\$(jq -r '.id' "\$object_file")
            name=\$(jq -r '.name // "Unnamed"' "\$object_file" | tr -cd '[:alnum:]_-')
            script=\$(jq -r '.scriptContents' "\$object_file")

            filename="\$output_dir/\${id}-\${name}.sh"
            echo "\$script" > "\$filename"
            chmod +x "\$filename"
            echo "Created \$filename"
        fi

        object=""
    fi
done < "\$input_file"
EOF

    rm -rf "$tmp_dir"
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
    extractExtensionAttributes

    # Invalidate Bearer Token
    invalidateBearerToken

    # Open Working Directory
    open -R "${workingDirectory}"
    logInfo "Working directory opened in Finder: ${workingDirectory}"

fi

