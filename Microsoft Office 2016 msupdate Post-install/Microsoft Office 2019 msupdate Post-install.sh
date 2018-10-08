#!/bin/sh
## postinstall

pathToScript=$0
pathToPackage=$1
targetLocation=$2
targetVolume=$3

####################################################################################################
#
#	ABOUT
#
#	Microsoft Office 2019 msupdate Post-install
#	Inspired by: https://github.com/pbowden-msft/msupdatehelper
#
#	Microsoft AutoUpdate (MAU) version 3.18 and later includes the "msupdate" binary which can be
#	used to start the Office for Mac update process.
#	See: https://docs.microsoft.com/en-us/DeployOffice/mac/update-office-for-mac-using-msupdate
#
#	Jamf Pro 10 Patch Management Software Titles currently require a .PKG to apply updates
#	(as opposed to a scripted solution.)
#
#	This script is intended to be used as a post-install script for a payload-free package.
#
#	Required naming convention: "Microsoft Excel 2019 msupdate 16.17.18090901.pkg"
#	• The word after "Microsoft" in the pathToPackage is the application name to be updated (i.e., "Excel").
#	• The word after "msupdate" in the pathToPackage is the target version number (i.e., "16.17.18090901").
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 04-Oct-2018, Dan K. Snelson
#		Based on "Microsoft Office 2016 msupdate 1.0.8"
#
####################################################################################################

###
# Variables
###

msUpdatePause="600"		# Number of seconds for msupdate processes to wait (recommended value: 600)
numberOfChecks="15"		# Number of times to check if the target app has been updated
delayBetweenChecks="30"		# Number of seconds to wait between tests

# IT Admin constants for application path
PATH_WORD="/Applications/Microsoft Word.app"
PATH_EXCEL="/Applications/Microsoft Excel.app"
PATH_POWERPOINT="/Applications/Microsoft PowerPoint.app"
PATH_OUTLOOK="/Applications/Microsoft Outlook.app"
PATH_ONENOTE="/Applications/Microsoft OneNote.app"

# Target app (i.e., the word after "Microsoft" in the pathToPackage)
targetApp=$( /bin/echo ${1} | /usr/bin/awk '{for (i=1; i<=NF; i++) if ($i~/Microsoft/) print $(i+1)}' )

# Target version (i.e., the word after "msupdate" in the pathToPackage)
targetVersion=$( /bin/echo ${1} | /usr/bin/awk '{for (i=1; i<=NF; i++) if ($i~/msupdate/) print $(i+1)}' | /usr/bin/sed 's/.pkg//' )



###
# Define functions
###


# Function to check whether MAU 3.18 or later command-line updates are available
function CheckMAUInstall() {
	if [ ! -e "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" ]; then
		echo "*** Error: MAU 3.18 or later is required! ***"
		exit 1
	else
		mauVersion=$( /usr/bin/defaults read "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/Info.plist" CFBundleVersion )
		echo "• MAU ${mauVersion} installed; proceeding ..."
	fi
}



# Function to check whether Office apps are installed
function CheckAppInstall() {
	if [ ! -e "/Applications/Microsoft ${1}.app" ]; then
		echo "*** Error: Microsoft ${1} is not installed; exiting ***"
		exit 1
	else
		echo "• Microsoft ${1} installed; proceeding ..."
	fi
}



# Function to determine the logged-in state of the Mac
function DetermineLoginState() {
	CONSOLE=$( stat -f%Su /dev/console )
	if [[ "${CONSOLE}" == "root" ]] ; then
		echo "• No user logged in"
		CMD_PREFIX=""
	else
		echo "• User ${CONSOLE} is logged in"
		CMD_PREFIX="sudo -u ${CONSOLE} "
	fi
}



# Function to register an application with MAU
function RegisterApp() {
	echo "• Register App: $1 $2"
	$(${CMD_PREFIX}defaults write com.microsoft.autoupdate2 Applications -dict-add "$1" "{ 'Application ID' = '$2'; LCID = 1033 ; }")
}



# Function to call 'msupdate' and update the target application
function PerformUpdate() {
	echo "• Perform Update: ${CMD_PREFIX}./msupdate --install --apps $1 --version $2 --wait ${msUpdatePause}"
	result=$( ${CMD_PREFIX}/Library/Application\ Support/Microsoft/MAU2.0/Microsoft\ AutoUpdate.app/Contents/MacOS/msupdate --install --apps $1 --version $2 --wait ${msUpdatePause} 2>/dev/null )
	echo "• ${result}"
}



# Function to check the currently installed version
function CheckInstalledVersion() {
	installedVersion=$( /usr/bin/defaults read "${1}"/Contents/Info.plist CFBundleVersion )
	echo "• Installed Version: ${installedVersion}"
}



# Function to confirm the update, then perform recon
function ConfirmUpdate() {
	echo "• Target Application: ${1}"
	CheckInstalledVersion "${1}"
	counter=0
	until [[ ${installedVersion} == ${targetVersion} ]] || [[ ${counter} -gt ${numberOfChecks} ]]; do
		((counter++))
		echo "• Check ${counter}; pausing for ${delayBetweenChecks} seconds ..."
		/bin/sleep ${delayBetweenChecks}
		CheckInstalledVersion "${1}"
	done

	if [[ ${installedVersion} == ${targetVersion} ]]; then
		echo "• Target Version:    ${targetVersion}"
		echo "• Installed Version: ${installedVersion}"
		echo "• Update inventory ..."
		/usr/local/bin/jamf recon
	else
		echo "WARNING: Update not completed within the specified duration; recon NOT performed"
		echo "•       Target Version: ${targetVersion}"
		echo "•    Installed Version: ${installedVersion}"
		echo "• Delay Between Checks: ${delayBetweenChecks}"
		echo "•     Number of Checks: ${numberOfChecks}"
	fi

}



###
# Command
###



echo " "
echo "#############################################################"
echo "# Microsoft Office 2019 msupdate v1.0.0 for ${targetApp}"
echo "#############################################################"
echo " "
echo "• Path to Package: ${1}"
echo "• Target App: ${targetApp}"
echo "• Target Version: ${targetVersion}"
echo " "

CheckMAUInstall
CheckAppInstall ${targetApp}
DetermineLoginState

echo " "
echo "• Updating Microsoft ${targetApp} to version ${targetVersion} ..."

case "${targetApp}" in

	"Word" )

		RegisterApp "${PATH_WORD}" "MSWD2019"
		PerformUpdate "MSWD2019" "${targetVersion}"
		ConfirmUpdate "${PATH_WORD}"
		;;

	"Excel" )

		RegisterApp "${PATH_EXCEL}" "XCEL2019"
		PerformUpdate "XCEL2019" "${targetVersion}"
		ConfirmUpdate "${PATH_EXCEL}"
		;;

	"PowerPoint" )

		RegisterApp "${PATH_POWERPOINT}" "PPT32019"
		PerformUpdate "PPT32019" "${targetVersion}"
		ConfirmUpdate "${PATH_POWERPOINT}"
		;;

	"Outlook" )

		RegisterApp "${PATH_OUTLOOK}" "OPIM2019"
		PerformUpdate "OPIM2019" "${targetVersion}"
		ConfirmUpdate "${PATH_OUTLOOK}"
		;;

	"OneNote" )

		RegisterApp "${PATH_ONENOTE}" "ONMC2019"
		PerformUpdate "ONMC2019" "${targetVersion}"
		ConfirmUpdate "${PATH_ONENOTE}"
		;;

	*)

		echo "*** Error: Did not recognize the target application of ${targetApp}; exiting. ***"
		exit 1
		;;

esac



echo " "
echo "Microsoft Office 2019 msupdate completed for ${targetApp}"
echo "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
echo " "



exit 0		## Success
exit 1		## Failure
