#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Removes Keychain entries as specified in JSS script parameters
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 6-Jun-2018, Dan K. Snelson
#		Original version
#
####################################################################################################


### Variables
loggedInUser=$( /usr/bin/stat -f %Su "/dev/console" )

entryName1="$4"		# Keychain Entry Name (i.e., "com.microsoft.SkypeForBusiness.HockeySDK")
entryName2="$5"		# Keychain Entry Name (i.e., "skype")
entryName3="$6"		# Keychain Entry Name (i.e., "Skype for Business")
entryName4="$7"		# Keychain Entry Name
entryName5="$8"		# Keychain Entry Name
entryName6="$9"		# Keychain Entry Name



### Functions
removeKeychainEntry() {

	echo " " # Blank line for readability

	echo "* Keychain entry to remove: ${1}"

	/usr/bin/security delete-generic-password -l "${1}" /Users/${loggedInUser}/Library/Keychains/login.keychain-db
	echo "* Removed ${1}."

}



### Command

echo " "
echo "### Removing Keychain Entries ###"
echo " "


# Keychain Entry Name 1 to quit
if [ ! -z "${entryName1}" ]; then
	removeKeychainEntry "${entryName1}"
fi

# Keychain Entry Name 2 to quit
if [ ! -z "${entryName2}" ]; then
	removeKeychainEntry "${entryName2}"
fi

# Keychain Entry Name 3 to quit
if [ ! -z "${entryName3}" ]; then
	removeKeychainEntry "${entryName3}"
fi

# Keychain Entry Name 4 to quit
if [ ! -z "${entryName4}" ]; then
	removeKeychainEntry "${entryName4}"
fi

# Keychain Entry Name 5 to quit
if [ ! -z "${entryName5}" ]; then
	removeKeychainEntry "${entryName5}"
fi

# Keychain Entry Name 6 to quit
if [ ! -z "${entryName6}" ]; then
	removeKeychainEntry "${entryName6}"
fi


exit 0		## Success
exit 1		## Failure
