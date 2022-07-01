#!/bin/bash

####################################################################################################
#
#   recoveryOS Password View
#
#   Purpose: Displays the computer's Recovery Lock Password to the end-user and then generates
#   a new, random Recovery Lock password via `SetRecoveryLock - Scheduled`
#
#   See: https://snelson.us/2022/06/view-recoveryos-password/
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 04-Feb-2022, Dan K. Snelson (@dan-snelson)
#       Original version
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.1"
scriptResult="Executing v${scriptVersion}; "
apiBearerToken=""
authorizationKey="${4}"
apiUsername="${5}"
apiPasswordEncrypted="${6}"
Salt="Salt_Goes_Here"
Passphrase="Passphrase_Goes_Here"
apiURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
computerUUID=$(/usr/sbin/ioreg -d2 -c IOPlatformExpertDevice | /usr/bin/awk -F\" '/IOPlatformUUID/{print $(NF-1)}')
osProductVersion=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $1}')



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for a specified value in Parameter 4 to prevent unauthorized script execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function authorizationCheck() {

    if [[ "${authorizationKey}" != "PurpleMonkeyDishwasher" ]]; then

        scriptResult+="Error: Incorrect Authorization Key; exiting."
        echo "${scriptResult}"
        exit 1

    else

        scriptResult+="Correct Authorization Key, proceeding; "

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Decrypt Password
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function decryptPassword() {
    /bin/echo "${1}" | /usr/bin/openssl enc -aes256 -md sha256 -d -a -A -S "${2}" -k "${3}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display User Message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function displayUserMessage() {
    /usr/local/jamf/bin/jamf displayMessage -message "${1}" &
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON string ($1) and return the desired key ($2)
# https://paulgalow.com/how-to-work-with-json-api-data-in-macos-shell-scripts
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getJsonValue() {
    JSON="$1" /usr/bin/osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Obtain Jamf Pro Bearer Token via Basic Authentication
# https://derflounder.wordpress.com/2022/01/05/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function obtainJamfProAPIBearerToken() {

    if [[ ${osProductVersion} -lt 12 ]]; then
        apiBearerToken=$(/usr/bin/curl -X POST --silent -u "${apiUsername}:${apiPassword}" "${apiURL}/api/v1/auth/token" | /usr/bin/python -c 'import sys, json; print json.load(sys.stdin)["token"]')
    else
        apiBearerToken=$(/usr/bin/curl -X POST --silent -u "${apiUsername}:${apiPassword}" "${apiURL}/api/v1/auth/token" | /usr/bin/plutil -extract token raw -)
    fi

    # scriptResult+="apiBearerToken: ${apiBearerToken}; "

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Verify API authentication is using a valid Bearer Token; returns the HTTP status code
# https://derflounder.wordpress.com/2022/01/05/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateJamfProAPIBearerToken() {

    apiBearerTokenCheck=$(/usr/bin/curl --write-out %{http_code} --silent --output /dev/null "${apiURL}/api/v1/auth" --request GET --header "Authorization: Bearer ${apiBearerToken}")

    scriptResult+="apiBearerTokenCheck: ${apiBearerTokenCheck}; "

    if [[ ${apiBearerTokenCheck} != 200 ]]; then

        scriptResult+="Error: ${apiBearerTokenCheck}; exiting."
        echo "${scriptResult}"
        exit 1

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate and optionally renew the Bearer Token; returns the HTTP status code
# https://derflounder.wordpress.com/2022/01/05/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateRenewBearerToken() {

    validateJamfProAPIBearerToken

    if [[ ${apiBearerTokenCheck} == 200 ]]; then

        if [[ ${osProductVersion} -lt 12 ]]; then
            apiBearerToken=$(/usr/bin/curl "${apiURL}/api/v1/auth/keep-alive" --silent --request POST --header "Authorization: Bearer ${apiBearerToken}" | python -c 'import sys, json; print json.load(sys.stdin)["token"]')
        else
            apiBearerToken=$(/usr/bin/curl "${apiURL}/api/v1/auth/keep-alive" --silent --request POST --header "Authorization: Bearer ${apiBearerToken}" | plutil -extract token raw -)
        fi

        scriptResult+="Renewed Bearer Token: ${apiBearerToken}; "

    else

        scriptResult+="Expired Bearer Token; renewing …"

        obtainJamfProAPIBearerToken

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Invalidate the Bearer Token
# https://derflounder.wordpress.com/2022/01/05/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function invalidateJamfProAPIBearerToken() {

    validateJamfProAPIBearerToken

    if [[ ${apiBearerTokenCheck} == 200 ]]; then

        scriptResult+="Bearer Token still valid; invalidate; "

        apiBearerToken=$(/usr/bin/curl "${apiURL}/api/v1/auth/invalidate-token" --silent --header "Authorization: Bearer ${apiBearerToken}" -X POST)
        apiBearerToken=""

        scriptResult+="Bearer Token invalidated; "

    else

        scriptResult+="Bearer Token already expired; "

    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="RecoveryOS Password View (${scriptVersion})"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Authorization
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

authorizationCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Decrypt API Password
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

apiPassword=$(decryptPassword "${apiPasswordEncrypted}" ${Salt} ${Passphrase})



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Obtain and validate Jamf Pro API Bearer Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

obtainJamfProAPIBearerToken

validateJamfProAPIBearerToken



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Determine computer's Jamf Pro Computer ID
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

computerRecord=$(/usr/bin/curl -s "${apiURL}api/v1/computers-inventory?section=GENERAL&filter=udid%3D%3D%22${computerUUID}%22" -H "Authorization: Bearer ${apiBearerToken}")

jssID=$(getJsonValue "$computerRecord" 'results[0].id')

if [[ -z ${jssID} ]]; then

    scriptResult+="Error: Unable to determine jssID; exiting."
    echo "${scriptResult}"
    exit 1

else

    # scriptResult+="jssID: ${jssID}; "
    scriptResult+="Determined computer's Jamf Pro Computer ID; proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Determine and display the computer's recoveryOS Password
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

computerRecoveryOSPasswordRaw=$(/usr/bin/curl -s "${apiURL}api/v1/computers-inventory/${jssID}/view-recovery-lock-password" -H "Authorization: Bearer ${apiBearerToken}")

computerRecoveryOSPassword=$(getJsonValue "$computerRecoveryOSPasswordRaw" 'recoveryLockPassword')

computerRecoveryOSPasswordHumanRedable=$(echo ${computerRecoveryOSPassword} | sed 's/.\{4\}/& /g')

# scriptResult+="recoveryOS Password: ${computerRecoveryOSPasswordHumanRedable}; "

displayUserMessage "recoveryOS Password:

${computerRecoveryOSPasswordHumanRedable}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Generate a new, random Recovery Lock password
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# The `SetRecoveryLock - Scheduled` Jamf Pro API Command is not currently available
# Please upvote JN-I-25769
# https://ideas.jamf.com/ideas/JN-I-25769



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

invalidateJamfProAPIBearerToken

scriptResult+="Goodbye!"

echo "${scriptResult}"

exit 0