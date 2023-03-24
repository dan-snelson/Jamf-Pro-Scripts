#!/bin/bash

####################################################################################################
#
# CrowdStrike Falcon Uninstall
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 24-Mar-2023, Dan K. Snelson (@dan-snelson)
#   - Original Version, based on: https://macadmins.slack.com/archives/CA9SU2FSS/p1669062782325789?thread_ts=1669056902.279869&cid=CA9SU2FSS
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version, Jamf Pro Script Parameters and default Exit Code
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="0.0.1"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
jamfBinary="/usr/local/bin/jamf"
falconBinary="/Applications/Falcon.app/Contents/Resources/falconctl"
scriptLog="/var/log/com.company.log"
mode="${4:-"interactive"}"                                      # [ interactive (default) | silent ]
maintenanceToken="${5:-"J8E6N7N5Y3J0E9N9NYJ8E6N7N5Y3J0E9N9NY"}" # [ i.e., Uninstall Token ]



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
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n###\n# CrowdStrike Falcon Uninstall (${scriptVersion})\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm CrowdStrike Falcon is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -d "/Applications/Falcon.app" ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon installed; proceeding …"
else
    updateScriptLog "PRE-FLIGHT CHECK: CrowdStrike Falcon NOT found; exiting."
    eval "${jamfBinary} policy -trigger updateComputerInventory"
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${mode}" == "interactive" ]]; then

    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

    if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
        updateScriptLog "PRE-FLIGHT CHECK: No user logged-in; exiting."
        exit 1
    else
        loggedInUserFullname=$( id -F "${loggedInUser}" )
        loggedInUserFirstname=$( echo "$loggedInUserFullname" | cut -d " " -f 1 )
        loggedInUserID=$(id -u "${loggedInUser}")
    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        updateScriptLog "PRE-FLIGHT CHECK: Dialog not found. Installing..."

        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            dialogVersion=$( /usr/local/bin/dialog --version )
            updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} installed; proceeding..."

        else

            # Display a so-called "simple" dialog if Team ID fails to validate
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "CrowdStrike Falcon Uninstall: Error" buttons {"Close"} with icon caution'
            quitScript "1"

        fi

        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"

    else

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."

    fi

}

if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
    dialogCheck
else
    updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Checks Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Complete"



####################################################################################################
#
# General Dialog Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog path, Command Files and JAMF binary
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
dialogBinary="/usr/local/bin/dialog"
welcomeCommandFile=$( mktemp /var/tmp/dialogWelcomeCommandFile.XXX )
progressCommandFile=$( mktemp /var/tmp/dialogProgressCommandFile.XXX )
failureCommandFile=$( mktemp /var/tmp/dialogFailure.XXX )

# Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)
xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
overlayicon="/var/tmp/overlayicon.icns"



####################################################################################################
#
# Welcome dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CrowdStrike Falcon Information
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

falconInfo=$( ${falconBinary} stats agent_info | tail -n 4 )
falconVersion=$( awk '/version:/{print $2}' <<< "$falconInfo" )
falconAgentID=$( awk '/agentID:/{print $2}' <<< "$falconInfo" )
falconSensorOperational=$( awk '/Sensor operational:/{print $3}' <<< "$falconInfo" )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeTitle="Uninstall Crowdstrike Falcon"
infobuttontext="KB0131377"
welcomeMessage="### Instructions  \n\nPlease enter the required information below, then click **Uninstall**.  \n\n- If the removal is **successful**, the computer's inventory will be updated  \n- If the removal **fails**, a detailed failure screen will be displayed  \n\nPlease see [${infobuttontext}](https://servicenow.company.com/support?id=kb_article_view&sysparm_article=${infobuttontext}) for additional information.  \n\n---  \n\n### CrowdStrike Falcon Agent Information  \n- **Version:** \`${falconVersion}\`  \n- **Agent ID:** \`${falconAgentID}\`  \n- **Sensor Operational:** \`${falconSensorOperational}\`"
welcomeBannerImage="https://img.freepik.com/free-photo/yellow-watercolor-paper_95678-446.jpg"
welcomeBannerText="Uninstall Crowdstrike Falcon"
welcomeIcon="https://ics.services.jamfcloud.com/icon/hash_08d0bef43e4b9df30e94865b488e5cb487b17be554f07a9003dfaddc077233f9"
macOSproductVersion="$( sw_vers -productVersion )"
macOSbuildVersion="$( sw_vers -buildVersion )"
serialNumber=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
infobox="**Computer Information**  \n- **Operating System:** ${macOSproductVersion} ($macOSbuildVersion)  \n\n- **Serial Number:** ${serialNumber}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" JSON
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeJSON='{
    "ontop" : "true",
    "bannerimage" : "'"${welcomeBannerImage}"'",
    "bannertext" : "'"${welcomeBannerText}"'",
    "titlefont" : "shadow=true, size=36",
    "message" : "'"${welcomeMessage}"'",
    "icon" : "'"${welcomeIcon}"'",
    "iconsize" : "150",
    "overlayicon" : "'"${overlayicon}"'",
    "infobox" : "'"${infobox}"'",
    "button1text" : "Uninstall",
    "button2text" : "Quit",
    "infobuttontext" : "'"${infobuttontext}"'",
    "infobuttonaction" : "'"https://servicenow.company.com/support?id=kb_article_view&sysparm_article=${infobuttontext}"'",
    "infotext" : "'"v${scriptVersion} (${mode})"'",
    "blurscreen" : "false",
    "moveable" : "true",
    "messagefont" : "size=14",
    "textfield" : [
        {   "title" : "Ticket Number",
            "required" : true,
            "prompt" : "INC8675309",
        },
        {   "title" : "Uninstall Token",
            "prompt" : "'"${maintenanceToken}"'",
        }
    ],
    "height" : "675"
}'



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Uninstall Progress dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Uninstall CrowdStrike Falcon"
message="Please wait whie CrowdStrike Falcon is uninstalled …"
icon="https://ics.services.jamfcloud.com/icon/hash_08d0bef43e4b9df30e94865b488e5cb487b17be554f07a9003dfaddc077233f9"
overlayicon="/var/tmp/overlayicon.icns"
uninstallProgressText="Initializing …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Uninstall Progress dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

uninstallProgressDialog="$dialogBinary \
--title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--overlayicon \"$overlayicon\" \
--mini \
--messagefont 'size=12' \
--position centre \
--moveable \
--progress reset \
--progresstext \"$uninstallProgressText\" \
--quitkey K \
--commandfile \"$progressCommandFile\" "



####################################################################################################
#
# Failure dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

failureTitle="Uninstall Failed"
failureMessage="Placeholder message; update in the 'quitScript' function"
failureIcon="SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogFailureCMD="$dialogBinary \
--moveable \
--title \"$failureTitle\" \
--message \"$failureMessage\" \
--icon \"$failureIcon\" \
--iconsize 150 \
--width 625 \
--height 375 \
--position topright \
--button1text \"Close\" \
--infotext \"v$scriptVersion\" \
--titlefont 'size=22' \
--messagefont 'size=14' \
--overlayicon \"$overlayicon\" \
--commandfile \"$failureCommandFile\" "



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Progress" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateProgress(){
    updateScriptLog "PROGRESS DIALOG: $1"
    echo "$1" >> "$progressCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Progress" dialog while sleeping
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function sleepProgress(){
    counter="1"
    until [[ "${counter}" -gt "${1}" ]]; do
        # dialogUpdateProgress "progress: increment 2"
        echo "progress: increment 2" >> "$progressCommandFile"
        sleep 1
        ((counter++))
    done
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Failure" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateFailure(){
    updateScriptLog "FAILURE DIALOG: $1"
    echo "$1" >> "$failureCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript for the Welcome dialog (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value_welcomeDialog() {
    for var in "${@:2}"; do jsonkey="${jsonkey}['${var}']"; done
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env)$jsonkey"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    if [[ "${1}" == "1" ]]; then

        updateScriptLog "QUIT SCRIPT: Display Failure Dialog"

        updateScriptLog "FAILURE DIALOG: Display Failure Dialog"
        failureMessage="The supplied Uninstall Token is incorrect:  \n\n\`${maintenanceToken}\`  \n\n---  \n\nPlease confirm the Uninstall Token for:  \n- **Serial Number:**  \n\`${serialNumber}\`  \n\n- **Falcon Agent ID:**  \n\`${falconAgentID}\`"

        eval "${dialogFailureCMD}" & sleep 0.3
        dialogUpdateFailure "message: ${failureMessage}"
        dialogUpdateProgress "quit:"
        wait

    else

        updateScriptLog "QUIT SCRIPT: Uninstall successful"
        dialogUpdateProgress "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        dialogUpdateProgress "message: CrowdStrike Falcon has been uninstalled  \n\nUpdating inventory …"
        dialogUpdateProgress "progress: 100"
        dialogUpdateProgress "progress text: Success!"
        sleep 5

    fi

    updateScriptLog "QUIT SCRIPT: Exiting …"

    # Remove welcomeCommandFile
    if [[ -e ${welcomeCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${welcomeCommandFile} …"
        rm "${welcomeCommandFile}"
    fi

    # Remove progressCommandFile
    if [[ -e ${progressCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${progressCommandFile} …"
        rm "${progressCommandFile}"
    fi

    # Remove failureCommandFile
    if [[ -e ${failureCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${failureCommandFile} …"
        rm "${failureCommandFile}"
    fi

    # Remove any default dialog file
    if [[ -e /var/tmp/dialog.log ]]; then
        updateScriptLog "QUIT SCRIPT: Removing default dialog file …"
        rm /var/tmp/dialog.log
    fi

    exit "${1}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CrowdStrike Falcon Binary Command
# Parameter 1: Command
# Parameter 2: Maintenance Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function falconBinaryCommand() {

    updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND: ${1}"

    if [[ -z "${2}" ]]; then

        updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND:A Maintenance Token was not provided; attempting ${1} …"
        "${falconBinary}" "${1}"

    else

        updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND:${1} CrowdStrike Falcon, using the following Maintenance Token:"
        updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND:${2}"
        command=$( expect <<EOF
set timeout 90
spawn sudo "${falconBinary}" "${1}" --maintenance-token
expect "Falcon Maintenance Token:"
send "${2}\r"
expect "*#*"
EOF
)

        commandResult="${command}"
        updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND: Result ${commandResult}"

        if [[ ${commandResult} == *"Error"* ]]; then

            updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND: Result: $(echo "${commandResult}" | tail -n1)"
            dialogUpdateProgress "progresstext: $(echo "${commandResult}" | tail -n1)"

        else

            updateScriptLog "CROWDSTRIKE FALCON BINARY COMMAND: Result: $(echo "${commandResult}" | tail -n1)"
            dialogUpdateProgress "progresstext: $(echo "${commandResult}" | tail -n1)"

        fi

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm removal of CrowdStike Falcon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function confirmRemoval() {

    updateScriptLog "PROGRESS DIALOG: Confirm removal of CrowdStike Falcon"
    dialogUpdateProgress "message: Confirming removal of CrowdStrike Falcon"
    dialogUpdateProgress "progresstext: Confirming removal …"
    sleepProgress "5"

    if [[ -e "/Applications/Falcon.app/Contents/Resources/falconctl" ]]; then

        updateScriptLog "PROGRESS DIALOG: ERROR: CrowdStrike Falcon Agent remains installed."

        # Load Falcon Sensor
        updateScriptLog "PROGRESS DIALOG: Load Falcon Sensor using Maintenance Token: $maintenanceToken …"
        dialogUpdateProgress "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateProgress "message: Loading CrowdStrike Falcon sensor"
        dialogUpdateProgress "progresstext: Loading …"
        falconBinaryCommand "load" "${maintenanceToken}"
        sleepProgress "5"

        # Display failure in Progress dialog
        dialogUpdateProgress "message: Attempt to uninstall CrowdStrike Falcon failed"
        dialogUpdateProgress "progress: 100"
        dialogUpdateProgress "progresstext: Failed"
        sleepProgress "5"
        quitScript "1"

    else

        updateScriptLog "PROGRESS DIALOG: CrowdStrike Falcon Agent was uninstalled."
        dialogUpdateProgress "message: CrowdStrike Falcon Agent was uninstalled."
        dialogUpdateProgress "progress: 100"
        dialogUpdateProgress "progresstext: Uninstall successful"
        sleep 5
        eval "${jamfBinary} policy -trigger updateComputerInventory"
        eval "${jamfBinary} policy -trigger restartConfirm" &
        dialogUpdateProgress "quit:"
        quitScript "0"

    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Interactive Uninstall
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${mode}" == "interactive" ]]; then

    updateScriptLog "INTERACTIVE MODE: Attempt uninstall with user-interaction"

    # Write Welcome JSON to disk
    echo "$welcomeJSON" > "$welcomeCommandFile"

    # Display Welcome dialog and capture user's input
    updateScriptLog "WELCOME DIALOG: Display Welcome dialog and capture user's input"
    welcomeResults=$( eval "${dialogApp} --jsonfile ${welcomeCommandFile} --json" )

    if [[ -z "${welcomeResults}" ]]; then
        welcomeReturnCode="2"
    else
        welcomeReturnCode="0"
    fi

    case "${welcomeReturnCode}" in

        0)  # Process exit code 0 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked Uninstall"

            # Extract the various values from the welcomeResults JSON
            ticketNumber=$(get_json_value_welcomeDialog "$welcomeResults" "Ticket Number")
            maintenanceToken=$(get_json_value_welcomeDialog "$welcomeResults" "Uninstall Token")

            # Output the various values from the welcomeResults JSON to the log file
            updateScriptLog "WELCOME DIALOG: • Ticket Number: $ticketNumber"
            updateScriptLog "WELCOME DIALOG: • Maintenance Token: $maintenanceToken"

            # Create Uninstall Progress dialog
            updateScriptLog "PROGRESS DIALOG: Create Uninstall Progress dialog"
            eval "$uninstallProgressDialog" &

            # Update progress bar and display 
            dialogUpdateProgress "message: Attempting to uninstall CrowdStrike Falcon"
            sleepProgress "5"

            # Unload
            # updateScriptLog "PROGRESS DIALOG: Unload using Maintenance Token: $maintenanceToken …"
            # dialogUpdateProgress "progresstext: Unloading …"
            # falconBinaryCommand "unload" "${maintenanceToken}"
            # sleepProgress "5"

            # Uninstall
            updateScriptLog "PROGRESS DIALOG: Uninstall using Maintenance Token: $maintenanceToken …"
            dialogUpdateProgress "progresstext: Uninstalling …"
            falconBinaryCommand "uninstall" "${maintenanceToken}" &
            sleepProgress "10"

            # Confirm Removal
            updateScriptLog "PROGRESS DIALOG: Confirm Removal …"
            confirmRemoval
            ;;

        2)  # Process exit code 2 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked Quit"
            quitScript "0"
            ;;

        3)  # Process exit code 3 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked infobutton"
            osascript -e "set Volume 3"
            afplay /System/Library/Sounds/Glass.aiff
            ;;

        4)  # Process exit code 4 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} allowed timer to expire"
            quitScript "1"
            ;;

        *)  # Catch all processing
            updateScriptLog "WELCOME DIALOG: Something else happened; Exit code: ${welcomeReturnCode}"
            quitScript "1"
            ;;

    esac

else

    updateScriptLog "SILENT MODE: Attempt uninstall sans user-interaction"
    falconBinaryCommand "uninstall"
    sleep 30

    if [[ -e "/Applications/Falcon.app/Contents/Resources/falconctl" ]]; then

        updateScriptLog "SILENT MODE: ERROR: CrowdStrike Falcon Agent remains installed."
        quitScript "1"

    else

        updateScriptLog "SILENT MODE: CrowdStrike Falcon Agent was uninstalled."
        quitScript "0"

    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Exiting …"

quitScript "0"