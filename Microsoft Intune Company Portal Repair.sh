#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Microsoft Intune Company Portal Repair
#	See: https://docs.microsoft.com/en-us/mem/intune/protect/troubleshoot-jamf#cause-6
#	See: https://support.microsoft.com/en-us/help/4131870/
#
####################################################################################################
#
# HISTORY
#
#	Version 0.0.1, 11-Jun-2020, Dan K. Snelson
#		Original version
#
####################################################################################################



echo " "
echo "################################################"
echo "# Microsoft Intune Company Portal Repair 0.0.1 #"
echo "################################################"
echo " "



###
# Variables
###

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )



###
# Functions
###

removeKeychainGenericPassword() {

	echo " " # Blank line for readability
	echo "• Keychain generic password to delete: ${1}"
	echo "`/usr/bin/security delete-generic-password -l "${1}" /Users/${loggedInUser}/Library/Keychains/login.keychain-db`"

}

removeKeychainCertificate() {

	echo " " # Blank line for readability
	echo "• Keychain certificate to delete: ${1}"
	echo "`/usr/bin/security delete-certificate -c "${1}" /Users/${loggedInUser}/Library/Keychains/login.keychain-db`"

}

removeKeychainIdentity() {

	echo " " # Blank line for readability
	echo "• Keychain identity to find: ${1}"
	hashID=$( /usr/bin/security find-identity -v -s "${1}" /Users/${loggedInUser}/Library/Keychains/login.keychain-db | /usr/bin/grep -B 1 "valid identities found" | /usr/bin/awk {'print $2'} | /usr/bin/head -1 )
	echo ${hashID}
	echo "• Keychain identity to delete: ${1}"
	echo "`/usr/bin/security delete-identity -Z ${hashID} /Users/${loggedInUser}/Library/Keychains/login.keychain-db`"
	# /usr/bin/su \- "${loggedInUser}" -c "/usr/bin/security delete-identity -Z ${hashID} /Users/${loggedInUser}/Library/Keychains/login.keychain-db"

}

###
# Program
###

echo "• Quit Company Portal"
/usr/bin/pkill -l -U ${loggedInUser} "Company Portal"
/usr/bin/pkill -l -U ${loggedInUser} "nsurlstoraged"

echo "• Remove Company Portal.app"
/bin/rm -R "/Applications/Company Portal.app"

echo "• Perform JamfAAD clean"
echo "`/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/JamfAAD.app/Contents/MacOS/JamfAAD -verbose clean`"

echo "• Remove ${loggedInUser} Company Portal Supporting Files"
/bin/rm -v "/Users/${loggedInUser}/Library/Application Support/com.microsoft.CompanyPortal.usercontext.info"
/bin/rm -Rv "/Users/${loggedInUser}/Library/Application Support/com.microsoft.CompanyPortal"
/bin/rm -Rv "/Users/${loggedInUser}/Library/WebKit/com.microsoft.CompanyPortal"
#/bin/rm -v "/Users/${loggedInUser}/Library/Application Support/com.jamfsoftware.selfservice.mac"
#/bin/rm -v "/Users/${loggedInUser}/Library/Application Support/com.jamfsoftware.selfservice.mac.savedState"
/bin/rm -v "/Users/${loggedInUser}/Library/WebKit/com.microsoft.CompanyPortal.savedState"

echo "• Remove Company Portal Supporting Files"
/bin/rm -v "/Library/Preferences/com.microsoft.CompanyPortal.plist"
/bin/rm -v "/Library/Application Support/com.microsoft.CompanyPortal.usercontext.info"
/bin/rm -v "/Library/Application Support/com.microsoft.CompanyPortal"

echo "• Remove Cookies"
/usr/bin/su \- "${loggedInUser}" -c "/bin/rm -fv /Users/${loggedInUser}/Library/Cookies/com.microsoft.CompanyPortal.binarycookies"
/usr/bin/su \- "${loggedInUser}" -c "/bin/rm -fv /Users/${loggedInUser}/Library/Cookies/com.jamf.management.jamfAAD.binarycookies"

echo "• Remove Keychain entries"
removeKeychainGenericPassword "com.microsoft.CompanyPortal"
removeKeychainGenericPassword "com.microsoft.CompanyPortal.HockeySDK"
removeKeychainGenericPassword "enterpriseregistration.windows.net"
removeKeychainGenericPassword "https://device.login.microsoftonline.com"
removeKeychainGenericPassword "https://device.login.microsoftonline.com/"
removeKeychainIdentity "Microsoft Session Transport Key"	# NOT WORKING
removeKeychainIdentity "Microsoft Workplace Join Key"		# NOT WORKING

# echo "• Update computer inventory"
# /usr/local/bin/jamf recon

# echo "• Install Microsoft Intune Company Portal"
# /usr/local/bin/jamf policy -event CompanyPortalRepair -verbose

# echo "• Register with Intune"
# /Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/JamfAAD.app/Contents/MacOS/JamfAAD -verbose registerWithIntune


exit 0
