#!/bin/sh
####################################################################################################
#
# Remove App From Unapproved Locations
#
#	Purpose: Apps installed in non-standard paths will NOT be updated by Jamf Pro Patch Policies.
#	This script will remove an app with a given Bundle ID from all unapproved locations.
#
#	Jamf Pro Script Parameter 4: Bundle ID (i.e., "us.zoom.xos")
#	Jamf Pro Script Parameter 5: Authorized Path (i.e., "/Applications/zoom.us.app")
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 12-May-2020, Dan K. Snelson
#		Original version
#		Inspired by donmontalvo: https://www.jamf.com/jamf-nation/discussions/35674/
#
####################################################################################################



####################################################################################################
#
# Define the Variables
#
####################################################################################################

# Bundle ID (exit if blank)
bundleID="${4}"
# Check for a specified value for Bundle ID (Parameter 4)
if [ "${bundleID}" = "" ]; then
	# Parameter 4 is blank; exit with error
	echo "Parameter 4 is blank; exit with error."
	exit 1
fi

# Authorized Path (exit if blank)
authorizedPath="${5}"
# Check for a specified value for Authorized Path (Parameter 5)
if [ "${authorizedPath}" = "" ]; then
	# Parameter 5 is blank; exit with error
	echo "Parameter 5 is blank; exit with error."
	exit 1
fi

searchResults="/private/var/tmp/${bundleID}-searchResults.txt"



####################################################################################################
#
# Define the Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate App Installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

validateAppInstallation() {

	echo "Validate App Installation ..."

	appInstalledTest=$( /usr/bin/mdfind kMDItemCFBundleIdentifier="${bundleID}" )

	if [ -z ${appInstalledTest} ]; then
		echo "${bundleID} NOT installed; exit"
		exit 0
	else
		echo "${bundleID} installed; proceeding ..."
	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Detect Unapproved App Locations
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

detectUnapprovedAppLocations() {
	echo "Detect Unapproved App Locations ..."
	/usr/bin/mdfind kMDItemCFBundleIdentifier="${bundleID}" | /usr/bin/grep -vw "\b${authorizedPath}\b" > "${searchResults}"
	echo "Unapproved App Locations: `/bin/cat ${searchResults}`"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove App From Unapproved Locations
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

removeAppFromUnpprovedLocations() {
	echo "Remove app from unapproved locations ..."
	/usr/bin/xargs -I{} /bin/rm -R {} < "${searchResults}"
}



####################################################################################################
#
# Program
#
####################################################################################################

echo " "
echo "###"
echo "# Remove App From Unapproved Locations"
echo "###"
echo " "

validateAppInstallation

detectUnapprovedAppLocations

removeAppFromUnpprovedLocations

echo "Removed `/bin/cat ${searchResults}`"
/bin/rm "${searchResults}"

exit 0
