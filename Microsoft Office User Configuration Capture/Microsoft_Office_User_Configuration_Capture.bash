#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Microsoft Office User Configuration Capture
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0, 02-Sep-2022, Dan K. Snelson
#   Original version
#
# Version 1.0.1, 02-Sep-2022, Dan K. Snelson
#   Exclude "Webkit" and "Cookies" (per Obi-Bryson)
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="1.0.1"
scriptResult=""
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
loggedInUserHome=$( dscl . -read /Users/$loggedInUser | grep NFSHomeDirectory: | cut -c 19- | head -n 1 )
serialNumber=$( system_profiler SPHardwareDataType | grep "Serial Number" | awk -F ": " '{ print $2 }' )
timestamp=$( date '+%Y-%m-%d-%H%M%S' )
filename="microsoft_case_86753099_${serialNumber}-${timestamp}"



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (thanks, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck(){

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$( curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }" )

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    # Check for Dialog and install if not found
    if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then

        scriptResult+="Installing Dialog; "

        # Create temporary working directory
        workDirectory=$( basename "$0" )
        tempDirectory=$( mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

        # Download the installer package
        curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

        # Verify the download
        teamID=$( spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()' )

        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" = "$teamID" ]] || [[ "$expectedDialogTeamID" = "" ]]; then
            installer -pkg "$tempDirectory/Dialog.pkg" -target /
        else
            jamfDisplayMessage "Dialog Team ID verification failed."
            exit 1
        fi

        # Remove the temporary working directory when done
        rm -Rf "$tempDirectory"  

    else

        scriptResult+="Dialog version $(dialog --version) found; proceeding..."

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Message: Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function displayMessageDialog() {

    rm /var/tmp/dialog.log

    title="${1}"
    message="${2}"
    icon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

    scriptResult+="Display \"${title}\" message to ${loggedInUser}; "

    dialog --title "${title}" --message "${message}" --icon "${icon}" --ontop --moveable

    echo "quit:" >> /var/tmp/dialog.log

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# JAMF Display Message (for fallback in case swiftDialog fails to install)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfDisplayMessage() {
    scriptResult+="${1}"
    jamf displayMessage -message "${1}" &
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reveal File in Finder
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function revealMe() {
    /usr/bin/su - "${loggedInUser}" -c '/usr/bin/open -R "'"${1}"'" '
}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Microsoft Office User Configuration Capture (${scriptVersion}); "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    scriptResult+="This script should be run as root; exiting."
    echo "${scriptResult}"
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
    scriptResult+="No user logged-in; exiting."
    echo "${scriptResult}"
    exit 0
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate swiftDialog is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Compress Microsoft Word-related directories
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Compress Microsoft Word-related directories; "

zip --quiet --recurse-paths --symlinks "${loggedInUserHome}/Desktop/${filename}.zip" "/Library/Application Support/Microsoft/Office365/User Content.localized" "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized" "${loggedInUserHome}/Library/Containers/com.microsoft.Word" --exclude "${loggedInUserHome}/Library/Containers/com.microsoft.Word/Data/Library/Cookies/*" --exclude "${loggedInUserHome}/Library/Containers/com.microsoft.Word/Data/Library/WebKit/*"

scriptResult+="Microsoft Word-related directories saved to: ${loggedInUserHome}/Desktop/${filename}.zip; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display End-user Message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

displayMessageDialog "Microsoft Case No. 86753099 (${scriptVersion})" "## Log Gathering Complete  \n\nYour computer logs have been saved
to your Desktop as:  \n\n\`${filename}.zip\`  \n\nPlease [upload](https://support.microsoft.com/files?workspace=ridiculously-long-URL-goes-here) the file to Microsoft."



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reveal Compressed File
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Reveal Compressed File; "

revealMe "${loggedInUserHome}/Desktop/${filename}.zip"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Complete!"

echo "${scriptResult}"

exit 0