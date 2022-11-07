#!/bin/bash

####################################################################################################
#
# Adobe Acrobat Add-in Removal for Microsoft Office
#
# Purpose:   Removes Adobe Acrobat Add-in from Microsoft Office.
#            (Designed to be executed via Jamf Pro Self Service.)
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1, 05-Nov-2022, Dan K. Snelson (@dan-snelson)
#   Original version
#
#   Inspired by
#   - @pbowden https://office-reset.com/macadmins/
#   - @nider https://macadmins.slack.com/archives/C07UZ1X7B/p1662624043863439?thread_ts=1662466049.264489&cid=C07UZ1X7B
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

scriptVersion="0.0.1"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
loggedInUserHome=$( dscl . read /Users/"${loggedInUser}" NFSHomeDirectory | awk -F ": " '{print $2}' )
osVersion=$( /usr/bin/sw_vers -productVersion )
osMajorVersion=$( echo "${osVersion}" | /usr/bin/awk -F '.' '{print $1}' )
dialogApp="/usr/local/bin/dialog"
dialogLog=$( mktemp /var/tmp/dialogLog.XXX )
scriptLog="${4:-"/var/tmp/org.churchofjesuschrist.log"}"
debugMode="${5:-"true"}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Microsoft Office & Adobe Acrobat Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

officeStartupFolder="/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Startup.localized"
excelAddin="/Excel/SaveAsAdobePDF.xlam"
powerpointAddin="/PowerPoint/SaveAsAdobePDF.ppam"
wordAddin="/Word/linkCreation.dotm"

excelIcon="/Applications/Microsoft Excel.app"
pointpointIcon="/Applications/Microsoft PowerPoint.app"
wordIcon="/Applications/Microsoft Word.app"
acrobatIcon="/Applications/Adobe Acrobat DC/Adobe Acrobat.app"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Remove Adobe Acrobat Add-in from Microsoft Office"
message="Please wait while the Adobe Acrobat Add-in is removed"
icon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )
progressText="Initializing …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogAcrobatAddinRemoval="$dialogApp \
--title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--mini \
--moveable \
--progress \
--progresstext \"$progressText\" \
--ontop \
--commandfile \"$dialogLog\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
    echo "No user logged-in; exiting."
    exit 0
else
    uid=$(id -u "${loggedInUser}")
fi



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# JAMF Display Message (for fallback in case swiftDialog fails to install)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfDisplayMessage() {
    updateScriptLog "Jamf Display Message: ${1}"
    /usr/local/jamf/bin/jamf displayMessage -message "${1}" &
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (thanks, Adam!)
# https://github.com/acodega/dialog-scripts/blob/main/dialogCheckFunction.sh
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

  # Expected Team ID of the downloaded PKG
  expectedDialogTeamID="PWA5E9TQ59"

  # Check for Dialog and install if not found
  if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

    updateScriptLog "Dialog not found. Installing..."

    # Create temporary working directory
    workDirectory=$( /usr/bin/basename "$0" )
    tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

    # Verify the download
    teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
 
      /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /

    else

      jamfDisplayMessage "Dialog Team ID verification failed."
      exit 1

    fi
 
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  

  else

    updateScriptLog "swiftDialog version $(dialog --version) found; proceeding..."

  fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    updateScriptLog "Quitting …"
    echo "quit: " >> "${dialogLog}"

    sleep 1
    updateScriptLog "Exiting …"

    # brutal hack - need to find a better way
    # killall tail

    # Remove dialogLog
    if [[ -e ${dialogLog} ]]; then
        updateScriptLog "Removing ${dialogLog} …"
        rm "${dialogLog}"
    fi

    updateScriptLog "Goodbye!"
    exit "${1}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateDialog() {
    sleep 0.35
    echo "${1}" >> "${dialogLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Application status
# confirmApplicationStatus "Process Name" "Human-readable Name" "icon"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function confirmApplicationStatus() {

    appStatus=$( pgrep -x "${1}")

    if [[ -n "${appStatus}" ]]; then
        updateDialog "icon: ${3}"
        updateDialog "message: Please save open files and quit ${2}."
        updateDialog "progresstext: Waiting for ${loggedInUser} to quit ${2} …"
        while [[ -n "${appStatus}" ]]; do
            updateScriptLog "${1} running; pausing …"
            sleep 2
            appStatus=$( pgrep -x "${1}" )
        done
        updateDialog "icon: ${icon}"
        updateDialog "message: ${2} no longer running."
        updateDialog "progresstext: Continuing …"
    else
        updateScriptLog "${1} NOT running; proceeding …"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Add-in
# removeAddin "${variable}" "Human-readable Name" "Progress Percent" "icon"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function removeAddin() {

    updateDialog "icon: ${4}"
    updateDialog "progresstext: Detecting ${2}'s Acrobat Add-in …"
    updateDialog "progress: $(($3-16))"
    sleep 1

    if [[ -e "${loggedInUserHome}${officeStartupFolder}${1}" ]]; then
        updateScriptLog "Removing ${loggedInUserHome}${officeStartupFolder}${1} …"
        updateDialog "progress: $(($3-8))"
        updateDialog "progresstext: Removing ${2}'s Acrobat Add-in …"
        if [[ ${debugMode} == "true" ]]; then
            updateScriptLog "DEBUG MODE: Faux remove ${loggedInUserHome}${officeStartupFolder}${1} …"
        else
            updateScriptLog "Remove ${loggedInUserHome}${officeStartupFolder}${1} …"
            rm -v "${loggedInUserHome}${officeStartupFolder}${1}"
        fi
        updateDialog "progresstext: Removed ${2}'s Acrobat Add-in"
        updateDialog "progress: ${3}"
        updateDialog "progresstext: Continuing …"
        sleep 1
    else
        updateDialog "progresstext: ${2}'s Acrobat Add-in NOT found …"
        updateScriptLog "${loggedInUserHome}${officeStartupFolder}${1} NOT found"
    fi

    updateDialog "icon: ${icon}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Add-in, sans swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function removeAddinUgly() {

    if [[ -e "${loggedInUserHome}${officeStartupFolder}${1}" ]]; then
        updateScriptLog "Removing ${loggedInUserHome}${officeStartupFolder}${1} …"
        rm -v "${loggedInUserHome}${officeStartupFolder}${1}"
    else
        updateScriptLog "${loggedInUserHome}${officeStartupFolder}${1} NOT found"
    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    jamfDisplayMessage "This script must be run as root"
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${debugMode} == "true" ]]; then
    updateScriptLog "DEBUG MODE | Adobe Acrobat Add-in Removal from Microsoft Office (${scriptVersion})"
else
    updateScriptLog "Adobe Acrobat Add-in Removal from Microsoft Office (${scriptVersion})"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Operating System
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${osMajorVersion}" -ge 11 ]] ; then

    updateScriptLog "macOS ${osMajorVersion} installed; proceeding ..."

else

    updateScriptLog "macOS ${osMajorVersion} installed; brute-force removal of Adobe Acrobat Add-in (sans progress) …"

    # Force-quit Microsoft Office and Adobe Acrobat apps
    pkill -9 'Microsoft Word'
    pkill -9 'Microsoft Excel'
    pkill -9 'Microsoft PowerPoint'
    pkill -9 'AdobeAcrobat'

    # Remove Add-ins
    removeAddinUgly "${excelAddin}"
    removeAddinUgly "${powerpointAddin}"
    removeAddinUgly "${wordAddin}"

    jamfDisplayMessage "Removed Adobe Acrobat Add-in"
    
    quitScript "0"

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate swiftDialog is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create "Adobe Acrobat Add-in Removal" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Create Adobe Acrobat Add-in Removal dialog …"
eval "$dialogAcrobatAddinRemoval" &

if [[ ${debugMode} == "true" ]]; then
    sleep 0.5
    updateDialog "title: DEBUG MODE | $title"
    updateDialog "message: Please wait while a DEBUG removal is executed …"
fi

SECONDS="0"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user to quit Microsoft Office and Adobe Acrobat apps
# confirmApplicationStatus "Process Name" "Human-readable Name"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

confirmApplicationStatus "Microsoft Word" "Word" "${wordIcon}"

confirmApplicationStatus "Microsoft Excel" "Excel" "${excelIcon}"

confirmApplicationStatus "Microsoft PowerPoint" "PowerPoint" "${pointpointIcon}"

confirmApplicationStatus "AdobeAcrobat" "Acrobat Pro" "${acrobatIcon}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Adobe Acrobat Add-ins from Microsoft Office startup folders
# removeAddin "${variable}" "Human-readable Name" "Progress Percent"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateDialog "message: Please wait while the Adobe Acrobat Add-in is removed"
updateDialog "progress: 3"
updateDialog "progresstext: Initializing …"
sleep 1

removeAddin "${excelAddin}" "Excel" "25" "${excelIcon}"

removeAddin "${powerpointAddin}" "PowerPoint" "50" "${pointpointIcon}"

removeAddin "${wordAddin}" "Word" "75" "${wordIcon}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Removed Adobe Acrobat Add-in from Microsoft Office"
updateDialog "message: Removed Adobe Acrobat Add-in from Microsoft Office"
updateDialog "progress: 100"
updateDialog "progresstext: Elapsed Time: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"
updateScriptLog "Elapsed Time: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"
sleep 5



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "End-of-line."

quitScript "0"