#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Jamf Pro Policy Viewer: Launch a brower to view a policy via the API
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 24-Jul-2018, Dan K. Snelson
#   	Original Version, based on:
#   	https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Jamf%20Pro%20Policy%20Editor%20Lite
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# Values for API connection; if left blank, you will be prompted to interactively enter
apiURL=""
apiUser=""
apiPassword=""



# ------------------------------ No edits required below this line --------------------------------



###################################################################################################
#
# Define the Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Lane Selection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function laneSelection() {

	echo "Please select a lane:

[d] Development
[s] Stage
[p] Production
[x] Exit"

	read -n 1 -r -p "`echo $'\n> '`" lane

	case "${lane}" in

	d|D )

			# "Development Lane"
			apiURL=""
			apiUser=""
			apiPassword=""
			;;

	s|S )

			# "Stage Lane"
			apiURL=""
			apiUser=""
			apiPassword=""
			;;

	p|P )

			# "Production Lane"
			apiURL=""
			apiUser=""
			apiPassword=""
			;;

	x|X)

			# "Exiting. Goodbye!"
			printf "\n\nExiting. Goodbye!\n\n"
			exit 0
			;;

	*)

			printf "\nERROR: Did not recognize response: $lane; exiting."
			exit 1
			;;

	esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# API Connection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function apiConnectionSettings() {

	printf "\n-------------------------------------------------------------------------------------------------------"
	printf "\n\n###\n"
	echo "# Step 1 of 2: API Connection Settings"
	printf "###\n"

	promptAPIurl

	promptAPIusername

	promptAPIpassword

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API URL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIurl() {

	if [[ -z "$apiURL" ]]; then
		# "API URL is blank; attempt to read from JAMF plist ..."
		if [[ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]]; then
			# "Found JAMF plist; read its URL ..."
			apiURL=$( defaults read "/Library/Preferences/com.jamfsoftware.jamf.plist" jss_url | sed 's|/$||' )
			echo "
Use this URL? ${apiURL}

[y] Yes - Use the URL presented above
[n] No - Enter the API URL at the next prompt
[x] Exit"

			read -n 1 -r -p "`echo $'\n> '`" urlResponse

			case "$urlResponse" in

				y|Y)

					apiURL="$apiURL"
					;;

				n|N)

					printf "\n\nEnter the API URL:"
					read -r -p "`echo $'\n> '`" newURLResponse
					if [[ -z "$newURLResponse" ]]; then
						printf "\nNo API URL provided; exiting.\n\n"
						exit 0
					fi
					apiURL="${newURLResponse}"
					;;

				x|X)

					printf "\n\nExiting. Goodbye!\n\n"
					exit 0
					;;

				*)

					printf "\n\nERROR: Invalid response; exiting.\n\n"
					exit 1
					;;

			esac

		else

			# "No API URL is specified in the script; prompt user ..."

			echo "
No API URL is specified in the script. Enter it now?

[y] Yes - Enter the URL at the next prompt
[n] No - Exit the script"

			read -n 1 -r -p "`echo $'\n> '`" urlResponse

			case "$urlResponse" in

				y|Y)

					printf "\n\nEnter the API URL:"
					read -r -p "`echo $'\n> '`"  userURLResponse
					if [[ -z "$userURLResponse" ]]; then
						printf "\nNo API URL provided; exiting.\n\n"
						exit 0
					fi
					apiURL="$userURLResponse"
					;;

				n|N)

					printf "\n\nExiting. Goodbye!\n\n"
					exit 0
					;;

				*)

					printf "\n\nERROR: Invalid response; exiting.\n\n"
					exit 1
					;;

			esac
		fi
	fi

	apiURL=$( echo "$apiURL" | sed 's|/$||' )

	printf "\n• Using the API URL of: ${apiURL}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API Username
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIusername() {

	if [[ -z "${apiUser}" ]]; then
		printf "\n\nNo API Username has been supplied. Enter it now?

[y] Yes - Enter the Username at the next prompt
[n] No - Exit
"

		read -n 1 -r -p "`echo $'\n> '`" apiUsernameResponse

		case "$apiUsernameResponse" in

			y|Y)

				printf "\n\nAPI Username:"
				read -r -p "`echo $'\n> '`" apiUserName
				if [[ -z "${apiUserName}" ]]; then
					printf "\nNo API Username provided; exiting.\n\n"
					exit 0
				fi
				apiUser="${apiUserName}"
				;;

			n|N)

				printf "\n\nExiting. Goodbye!\n\n"
				exit 0
				;;

			*)

				printf "\n\nInvalid response! Please try again."
				promptAPIusername
				;;

		esac

	fi

	printf "\n• Using the API Username of: ${apiUser}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API Password
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIpassword() {

	if [[ -z "${apiPassword}" ]]; then

		printf "\n\nNo API Password has been supplied. Enter it now?

[y] Yes - Enter the password at the next prompt
[n] No - Exit
"

		read -n 1 -r -p "`echo $'\n> '`" apiPasswordEntryResponse

		case "$apiPasswordEntryResponse" in

			y|Y)

				printf "\n\nAPI Password:\n>"
				read -s apiPasswordEntry
				if [[ -z "${apiPasswordEntry}" ]]; then
					printf "\nNo API Password provided; exiting.\n\n"
					exit 0
				fi
				apiPassword="${apiPasswordEntry}"
				;;

			n|N)

				printf "\n\nExiting. Goodbye!\n\n"
				exit 0
				;;

			*)

				printf "\n\nInvalid response! Please try again."
				promptAPIpassword
				;;

		esac

	fi

	printf "\n• Using the supplied API password\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Select Policy to Update (Thanks, mm2270!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selectPolicy() {

	# Reset Variables
	unset policyNames policyIDs policyName policyNamesArray policyID policyIDsArray policyChoice

	printf "\n-------------------------------------------------------------------------------------------------------"
	printf "\n\n###\n"
	echo "# Step 2 of 2: Select Policy to View"
	printf "###\n\n"

	# Build two lists via the API: One for Policy names; the other for their respective IDs.
	policyNames=$( /usr/bin/curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/policies" | xmllint --format - | awk -F'>|<' '/<name>/{print $3}')

	# Exit if API connection settings are incorrect
	if [[ -z ${policyNames} ]]; then
		printf "\n\nERROR: API connection settings incorrect; exiting\n\n"
		exit 1
	fi

	policyIDs=$( /usr/bin/curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/policies" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}')

	# Create array for Policy names
	while read policyName; do
		policyNamesArray+=("$policyName")
	done < <( printf '%s\n' "$policyNames" )

	# Create array for Policy IDs
	while read policyID; do
		policyIDsArray+=("$policyID")
	done < <( printf '%s\n' "$policyIDs" )

	# Display Policy names with index labels
	for i in "${!policyNamesArray[@]}"; do
	printf "%s\t%s\n" "[$i]" "${policyNamesArray[$i]}"
	done

	echo "
	Choose the Policy to view by entering its index number:"

	read -r -p "`echo $'\n> '`" policyChoice

	if [ "${policyChoice}" -eq "${policyChoice}" ] 2>/dev/null; then
		printf "\nPolicy Index: ${policyChoice}"
	else
		printf "\n\nERROR: \"${policyChoice}\" is not an index number; exiting.\n\n"
		exit 1
	fi

	echo " "
	echo " Policy Name: ${policyNamesArray[$policyChoice]}"
	echo "   Policy ID: ${policyIDsArray[$policyChoice]}"
	echo " "

	# Assign Policy ID to variable
	policyID="${policyIDsArray[$policyChoice]}"

	promptToContinue

}





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# View Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function viewPolicy() {

	printf "\n-------------------------------------------------------------------------------------------------------\n"
	printf "\n###\n"
	echo "# Complete: View Policy"
	printf "###\n"

	printf "\n• Launching browser to view \"${policyNamesArray[$policyChoice]}\" policy ...\n"
	/usr/bin/open $apiURL/policies.html?id=${policyID}

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt to Continue
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptToContinue(){

	unset choice

	# Prompt user for permission to proceed
	read -n 1 -r -p "Would you like to view this policy? [y]es or [n]o: `echo $'\n> '`" choice

	case "${choice}" in

	y|Y )

			viewPolicy

			;;

	n|N )

			/usr/bin/clear
			selectPolicy
			;;

	*)

			printf "\nERROR: Did not recognize response: $choice; exiting."
			exit 1
			;;

	esac

}



####################################################################################################
#
# Main Program
#
####################################################################################################

# Clear the user's Terminal session
/usr/bin/clear

echo "#######################################"
echo "# Jamf Pro Policy Editor Viewer, v1.0 #"
echo "#######################################"
echo " "
echo "[PI-005903] Jamf Pro may experience a long load time when viewing the Policies object if it contains a large number (e.g., 4000) of policy or policy_script records.

This script opens a selected policy in a browser.
"


if [[ -z ${apiURL} && -z ${apiUser} && -z ${apiPassword} ]]; then
	# API credentials blank; prompt user to select lane ...
	laneSelection
fi

apiConnectionSettings

selectPolicy

exit 0
