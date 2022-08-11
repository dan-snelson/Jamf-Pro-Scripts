#!/bin/bash

####################################################################################################
#
# ABOUT
#
# Sophos Endpoint Scripted Install
#
# Reference: https://snelson.us/2022/08/sophos-endpoint-scripted-install/
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0, 05-Aug-2022, Dan K. Snelson (@dan-snelson)
#   Original version
#
####################################################################################################



####################################################################################################
#
# VARIABLES
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Global Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.0.0"
scriptResult="v${scriptVersion}; "
tempDirectory="/private/var/tmp/SophosEndpoint"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for a specified "Sub-Estate" setting (Parameter 4); defaults to "Sub-Estate 3"
# Options: ( Sub-Estate 1 | Sub-Estate 2 | Sub-Estate 3 | Sub-Estate 4 )
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${4}" != "" ]] && [[ "${subEstate}" == "" ]]; then
    subEstate="${4}"
    scriptResult+="Using \"${subEstate}\" as the Sophos Central Sub-Estate; "
else
    subEstate="Sub-Estate 3"
    scriptResult+="Parameter 4 is blank; using \"${subEstate}\" as the Sophos Central Sub-Estate; "
fi



case "${subEstate}" in

    "Sub-Estate 1" )
            sophosCentralURL="https://api-cloudstation-us-east-2.sophos.com/api/download/NWxW1o9ezB07XquznpBjz/SophosInstall.zip"
            ;;

    "Sub-Estate 2" )
            sophosCentralURL="https://api-cloudstation-us-east-1.sophos.com/api/download/qwZiIUu2ipY9hC8T01UmI/SophosInstall.zip"
            ;;

    "Sub-Estate 3" )
            sophosCentralURL="https://api-cloudstation-us-east-3.sophos.com/api/download/j8e6n7n5y3099/SophosInstall.zip"
            ;;

    "Sub-Estate 4" | * )
            sophosCentralURL="https://api-cloudstation-us-east-4.sophos.com/api/download/QsAW3hCKRn8Cw62oyXHc0/SophosInstall.zip"
            ;;


esac



####################################################################################################
#
# PROGRAM
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Sophos Endpoint: Scripted Installation (${scriptVersion})"
echo "Using \"${subEstate}\" as the Sophos Central Sub-Estate"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Delete / Create Temporary Directory
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Delete Temporary Directory … "
/bin/rm -Rf "${tempDirectory}"

scriptResult+="Create Temporary Directory … "
/bin/mkdir "${tempDirectory}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Download and unzip installer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Downloading … "
/usr/bin/curl --location --silent "${sophosCentralURL}" -o "${tempDirectory}/SophosCentralInstall.zip"

scriptResult+="Expanding … "
/usr/bin/unzip -q "${tempDirectory}/SophosCentralInstall.zip" -d "${tempDirectory}"

sleep "15"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Permissions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Update Permissions … "
/bin/chmod a+x "${tempDirectory}/Sophos Installer.app/Contents/MacOS/Sophos Installer"
/bin/chmod a+x "${tempDirectory}/Sophos Installer.app/Contents/MacOS/tools/com.sophos.bootstrap.helper"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Install
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Install … "
${tempDirectory}/Sophos\ Installer.app/Contents/MacOS/Sophos\ Installer --quiet

sleep "60"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Sophos Endpoint RTS Files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Validate Sophos Endpoint RTS Files … "

RESULT="Not Installed"

if [[ -d /Applications/Sophos/Sophos\ Endpoint.app ]]; then
    if [[ -f /Library/Preferences/com.sophos.sav.plist ]]; then
        sophosOnAccessRunning=$( /usr/bin/defaults read /Library/Preferences/com.sophos.sav.plist OnAccessRunning )
        case ${sophosOnAccessRunning} in
            "0" ) RESULT="Disabled" ;;
            "1" ) RESULT="Enabled" ;;
             *  ) RESULT="Unknown" ;;
        esac
    else
        RESULT="Not Found"
    fi
fi

scriptResult+="Result: ${RESULT}; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Delete Temporary Directory
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Delete Temporary Directory … "
/bin/rm -Rf "${tempDirectory}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Goodbye!"

echo "${scriptResult}"

exit 0