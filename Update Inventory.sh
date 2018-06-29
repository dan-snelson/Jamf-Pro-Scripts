#!/bin/bash

########################################################################################################
# Update inventory with endUsername, from Enterprise Connect's "adUsername." See also:                 #
# http://docs.jamf.com/10.5.0/jamf-pro/administrator-guide/Computer_Inventory_Collection_Settings.html #
########################################################################################################

echo "*** Updating inventory ***"

# Get the logged in users username
loggedInUser=$( /usr/bin/stat -f %Su "/dev/console" )

if [[ ${loggedInUser} == "root" ]] || [[ ${loggedInUser} == "adobeinstall" ]] || [[ ${loggedInUser} == "_mbsetupuser" ]] ; then

	echo "${loggedInUser} is currently the logged-in user; starting normal inventory update ..."

	/usr/local/jamf/bin/jamf recon

else

	if [[ -f "/Applications/Enterprise Connect.app/Contents/SharedSupport/eccl" ]] ; then

		adUsername=$( /usr/bin/su \- "${loggedInUser}" -c "/Applications/Enterprise\ Connect.app/Contents/SharedSupport/eccl -p adUsername" | /usr/bin/sed 's/adUsername: //' )

		if [[ ${adUsername} == "missing value" ]]; then	# Enterprise Connect installed, but user is NOT logged in

			echo "${loggedInUser} NOT logged into Enterprise Connect; Starting inventory update for logged-in user ${loggedInUser}  ..."

			/usr/local/jamf/bin/jamf recon -endUsername ${loggedInUser}

		else	# Enterprise Connect installed and the user is logged in

			echo "Starting inventory update for Enterprise Connect user ${adUsername} ..."

			/usr/local/jamf/bin/jamf recon -endUsername ${adUsername}

		fi

	else

		echo "Enterprise Connect NOT installed; Starting inventory update for the logged-in user ${loggedInUser} ..."

		/usr/local/jamf/bin/jamf recon -endUsername ${loggedInUser}

	fi

fi



exit 0
