#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Jamf Pro Policy Editor Lite: Edit a policy's version number via the API
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 23-Jul-2018, Dan K. Snelson
#		Original Version
#		With inspiration from mm2270
#		https://github.com/mm2270/Casper-API/blob/master/Convert-SG-Search-Search-SG.sh
#
#	Version 1.1, 24-Jul-2018, Dan K. Snelson
#		Added lane selection
#		Added check for valid API connection settings
#		Added ability to correct version number
#		Added display of current package name when version is absent from policy name
#		Added additional logging
#
#	Version 1.2, 13-Aug-2018, Dan K. Snelson
#		Added API Connection Validation (Thanks, BIG-RAT!)
#
#	Version 1.3, 24-Aug-2018, Dan K. Snelson
#		Limit policy names displayed by including a search string when calling the script (see "adobe" below)
#		./Jamf\ Pro\ Policy\ Editor\ Lite.sh adobe
#
#	Version 1.4, 10-Oct-2019, Dan K. Snelson
#		Enabled debug mode by default
#		Added more robust debug logging for failed API connections
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# Values for API connection; if left blank, you will be prompted to interactively enter.
# If you have multiple lanes, fill-in variables in the "Lane Selection" function below.
apiURL=""
apiUser=""
apiPassword=""

# Debug mode [ true | false ]
debug="true"

# String to match in policy name
args=("$@")
policyNameSearchString="${args[0]}"



# ------------------------------ No edits required below this line --------------------------------



###################################################################################################
#
# Define the Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create Working Diretory and Log file
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function createWorkingDirectory() {

	# Currently logged-in user
	loggedInUser=$( /usr/bin/stat -f%Su /dev/console )

	# Time stamp for log file
	timestamp=$( /bin/date '+%Y-%m-%d-%H%M%S' )

	# Working Directory
	workingDirectory="/Users/${loggedInUser}/Documents/Jamf_Pro_Policy_Editor_Lite"
	logDirectory="${workingDirectory}/Logs/"
	logFile="${logDirectory}/Jamf_Pro_Policy_Editor_Lite-${timestamp}.log"

	# Ensure Working Directory exists
	if [[ ! -d ${workingDirectory} ]]; then
		/bin/mkdir -p ${workingDirectory}
	fi

	# Ensure Log Directory exists
	if [[ ! -d ${logDirectory} ]]; then
		/bin/mkdir -p ${logDirectory}
	fi

	# Ensure Log File exists
	if [[ ! -d ${logFile} ]]; then
		/usr/bin/touch ${logFile}
		printf "###\n#\n# Jamf Pro Policy Editor Lite\n# Log file created on:\n# `date`\n#\n###\n\n" >> ${logFile}
	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function ScriptLog() { # Re-direct logging to the log file ...

	NOW=`date +%Y-%m-%d\ %H:%M:%S`
	/bin/echo "${NOW}" " ${1}" >> "${logFile}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reveal File in Finder
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function revealMe() {

	/usr/bin/open -R "${1}"

}



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
	ScriptLog "Please select a lane: ${lane}"

	case "${lane}" in

	d|D )

		ScriptLog "Development Lane"
		apiURL=""
		apiUser=""
		apiPassword=""
		;;

	s|S )

		ScriptLog "Stage Lane"
		apiURL=""
		apiUser=""
		apiPassword=""
		;;

	p|P )

		ScriptLog "Production Lane"
		apiURL=""
		apiUser=""
		apiPassword=""
		;;

	x|X)

		ScriptLog "Exiting. Goodbye!"
		printf "\n\nExiting. Goodbye!\n\n"
		exit 0
		;;

	*)

		ScriptLog "ERROR: Did not recognize response: $lane; exiting."
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
	echo "# Step 1 of 6: API Connection Settings"
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
		ScriptLog "API URL is blank; attempt to read from JAMF plist ..."
		# Read the API URL from the JAMF preferences
		if [[ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]]; then
			ScriptLog "Found JAMF plist; read its URL ..."
			apiURL=$( defaults read "/Library/Preferences/com.jamfsoftware.jamf.plist" jss_url | sed 's|/$||' )
			echo "
Use this URL? ${apiURL}

[y] Yes - Use the URL presented above
[n] No - Enter the API URL at the next prompt
[x] Exit"

			read -n 1 -r -p "`echo $'\n> '`" urlResponse
			ScriptLog "Use this URL: ${apiURL}? ${urlResponse}"

			case "$urlResponse" in

				y|Y)

					apiURL="$apiURL"
					;;

				n|N)

					printf "\n\nEnter the API URL:"
					read -r -p "`echo $'\n> '`" newURLResponse
					if [[ -z "$newURLResponse" ]]; then
						ScriptLog "No API URL provided; exiting."
						printf "\nNo API URL provided; exiting.\n\n"
						exit 0
					fi
					apiURL="${newURLResponse}"
					ScriptLog "API URL: ${apiURL}"
					;;

				x|X)

					ScriptLog "Exiting. Goodbye!"
					printf "\n\nExiting. Goodbye!\n\n"
					exit 0
					;;

				*)

					ScriptLog "ERROR: Invalid response: ${urlResponse}; exiting."
					printf "\n\nERROR: Invalid response; exiting.\n\n"
					exit 1
					;;

			esac

		else

			ScriptLog "No API URL is specified in the script; prompt user ..."

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
						ScriptLog "No API URL provided; exiting."
						printf "\nNo API URL provided; exiting.\n\n"
						exit 0
					fi
					apiURL="$userURLResponse"
					ScriptLog "API URL: ${apiURL}"
					;;

				n|N)

					ScriptLog "Exiting. Goodbye!"
					printf "\n\nExiting. Goodbye!\n\n"
					exit 0
					;;

				*)

					ScriptLog "ERROR: Invalid response ${urlResponse}; exiting."
					printf "\n\nERROR: Invalid response; exiting.\n\n"
					exit 1
					;;

			esac
		fi
	fi

	apiURL=$( echo "$apiURL" | sed 's|/$||' )

	ScriptLog "Using the API URL of: ${apiURL}"
	printf "\n• Using the API URL of: ${apiURL}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API Username
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIusername() {

	if [[ -z "${apiUser}" ]]; then
		ScriptLog "API username is blank; attempt to read from JAMF plist ..."
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

	ScriptLog "Using the API Username of: ${apiUser}"
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

	if [[ ${debug} ==  "true" ]]; then
		ScriptLog "Using the API Password of: ${apiPassword}"
		printf "\n• Using the API Password of: ${apiPassword}\n"
	else
		printf "\n• Using the supplied API password\n"
	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate API Connection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateAPIConnection() {

	if [[ ${debug} ==  "true" ]]; then
		result=$( /usr/bin/curl -w " %{http_code}" -m 10 -u "${apiUser}":"${apiPassword}" "${apiURL}/JSSResource/computers" -X GET -H "Accept: application/xml" )
		statusCode=$( echo ${result} | /usr/bin/awk '{print $NF}' )
		if [[ ${statusCode} = "401" ]]; then
	 		printf "\nERROR: API Connection Settings Incorrect; exiting.\n\nConsider trying again with your administrative Jamf Pro credentials.\n\nIf that works, double-check the permissions for the \"${apiUser}\" Jamf Pro account.\n\n"
			echo "API URL:      ${apiURL}"
			echo "API User:     ${apiUser}"
			echo "API Password: ${apiPassword}"
			echo "Status Code:  ${statusCode}"
	 		exit 1
		fi
	else
		result=$( /usr/bin/curl -w " %{http_code}" -m 10 -sku "${apiUser}":"${apiPassword}" "${apiURL}/JSSResource/computers" -X GET -H "Accept: application/xml" )
		statusCode=$( echo ${result} | /usr/bin/awk '{print $NF}' )
		if [[ ${statusCode} = "401" ]]; then
	 		printf "\nERROR: API Connection Settings Incorrect; exiting\n\n"
			echo "Status Code: ${statusCode}"
	 		exit 1
		fi
	fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Select Policy to Update (Thanks, mm2270!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selectPolicy() {

	# Reset Variables
	ScriptLog "Reset variables ..."
	unset policyNames policyIDs policyName policyNamesArray policyID policyIDsArray policyChoice

	printf "\n-------------------------------------------------------------------------------------------------------"
	printf "\n\n###\n"
	echo "# Step 2 of 6: Select Policy to Update"
	printf "###\n\n"

	# Build two lists via the API: One for Policy names; the other for their respective IDs.
	ScriptLog "Build list of policy names via API ..."
	policyNames=$( /usr/bin/curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/policies" | xmllint --format - | awk -F'>|<' '/<name>/{print $3}')

	# Exit if API connection settings are incorrect
	if [[ -z ${policyNames} ]]; then
		ScriptLog "ERROR: API connection settings incorrect; exiting"
		printf "\n\nERROR: API connection settings incorrect; exiting\n\n"
		exit 1
	fi

	ScriptLog "Build list of policy IDs via API ..."
	policyIDs=$( /usr/bin/curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/policies" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}')

	# Create array for Policy names
	ScriptLog "Create array for Policy names ..."
	while read policyName; do
		policyNamesArray+=("$policyName")
	done < <( printf '%s\n' "$policyNames" )

	# Create array for Policy IDs
	ScriptLog "Create array for Policy IDs ..."
	while read policyID; do
		policyIDsArray+=("$policyID")
	done < <( printf '%s\n' "$policyIDs" )

	# Display Policy names with index labels
	ScriptLog "Display Policy names with index labels ..."
	for i in "${!policyNamesArray[@]}"; do
		if [[ -z ${policyNameSearchString} ]]; then
			printf "%s\t%s\n" "[$i]" "${policyNamesArray[$i]}"
		else
			ScriptLog "Limit to policy names containing ${policyNameSearchString} ..."
			printf "%s\t%s\n" "[$i]" "${policyNamesArray[$i]}" | /usr/bin/grep -i ${policyNameSearchString}
		fi
	done
	ScriptLog "Prompting user to select policy ..."

	echo "
	Choose the Policy to update by entering its index number:"

	read -r -p "`echo $'\n> '`" policyChoice

	if [ "${policyChoice}" -eq "${policyChoice}" ] 2>/dev/null; then
		ScriptLog "Policy index: ${policyChoice}"
	else
		printf "\n\nERROR: \"${policyChoice}\" is not an index number; exiting.\n\n"
		ScriptLog "ERROR: \"${policyChoice}\" is not an index number; exiting."
		exit 1
	fi

	echo " "
	echo "Policy Name: ${policyNamesArray[$policyChoice]}"
	echo "  Policy ID: ${policyIDsArray[$policyChoice]}"
	echo " "

	# Assign Policy ID to variable
	policyID="${policyIDsArray[$policyChoice]}"
	ScriptLog "User selected: Policy ID ${policyID} ${policyNamesArray[$policyChoice]}"

	promptToContinue

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Download and backup the Policy XML
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function downloadBackupXML() {

	printf "\n\n\n-------------------------------------------------------------------------------------------------------"
	printf "\n\n###\n"
	echo "# Step 3 of 6: Download and Backup Policy XML"
	printf "###\n\n"

	echo "• Downloading XML for Policy ID ${policyID} ..."
	ScriptLog "Downloading XML for Policy ID ${policyID} ..."

	# Backup Directory
	backupDirectory="${workingDirectory}/Backups/${timestamp}"

	# Ensure Backup Directory exists
	if [[ ! -d ${backupDirectory} ]]; then
		/bin/mkdir -p ${backupDirectory}
		ScriptLog "Created backup directory: ${backupDirectory}"
	fi

	# Updates Directory
	updatesDirectory="${workingDirectory}/Updates/${timestamp}"

	# Ensure Update Directory exists
	if [[ ! -d ${updatesDirectory} ]]; then
		/bin/mkdir -p ${updatesDirectory}
		ScriptLog "Created update directory: ${updatesDirectory}"
	fi

	# Download policy XML
	if [[ ${debug} ==  "true" ]]; then
		ScriptLog "Debug mode enabled; displaying output of curl command to user ..."
		/usr/bin/curl -u "$apiUser":"$apiPassword" $apiURL/JSSResource/policies/id/${policyID} -H "Accept: application/xml" -X GET -o ${backupDirectory}/policy-${policyID}.xml
	else
		/usr/bin/curl -s -u "$apiUser":"$apiPassword" $apiURL/JSSResource/policies/id/${policyID} -H "Accept: application/xml" -X GET -o ${backupDirectory}/policy-${policyID}.xml
	fi
	echo "• Downloaded to: ${backupDirectory}/policy-${policyID}.xml ..."
	ScriptLog "Downloaded to: ${backupDirectory}/policy-${policyID}.xml"

	# Copy downloaded XML to Updates directory
	echo "• Copying ../Backups/policy-${policyID}.xml to ../Updates/policy-${policyID}.xml"
	ScriptLog "Copying ../Backups/policy-${policyID}.xml to ../Updates/policy-${policyID}.xml"
	if [[ ${debug} ==  "true" ]]; then
		ScriptLog "Debug mode enabled; displaying output of cp command to user ..."
		/bin/cp -v ${backupDirectory}/policy-${policyID}.xml ${updatesDirectory}/policy-${policyID}.xml
	else
		/bin/cp ${backupDirectory}/policy-${policyID}.xml ${updatesDirectory}/policy-${policyID}.xml
	fi
	echo "• Copied to ../Updates/policy-${policyID}.xml"
	ScriptLog "Copied to ../Updates/policy-${policyID}.xml"

	# Exit if update file does not exist
	if [[ ! -f "${updatesDirectory}/policy-${policyID}.xml" ]]; then
		echo "ERROR: Policy file \"../Updates/policy-${policyID}.xml\" does NOT exist; exiting"
		ScriptLog "ERROR: Policy file \"../Updates/policy-${policyID}.xml\" does NOT exist; exiting"
		exit 1
	fi

	printf "\n-------------------------------------------------------------------------------------------------------\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt the user for the new version number
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptNewVersion() {

	printf "\n###\n"
	echo "# Step 4 of 6: Specify new version number"
	printf "###\n\n"

	# Lookup policy name
	policyName=$( /usr/bin/xmllint --xpath "/policy/general/name/text()" ${updatesDirectory}/policy-${policyID}.xml )
	printf "• Policy Name: ${policyName}\n"
	ScriptLog "Policy Name: ${policyName}"

	# Determine current version
	currentVersion=$( echo $policyName | /usr/bin/awk -F"[()]" '{print $2}' )
	if [[ -z ${currentVersion} ]]; then
		currentPackageName=$( /usr/bin/xmllint --xpath "/policy/package_configuration/packages/package/name/text()"  ${updatesDirectory}/policy-${policyID}.xml )
		# Prompt user for current version
		printf "• Current version: UNKOWN\n"
		printf "• Current Package Name: ${currentPackageName}\n\n"

		read -p "Please specify the current version number: `echo $'\n> '`" currentVersion
		ScriptLog "Current version number: ${currentVersion}"
		if [[ -z ${currentVersion} ]]; then
			ScriptLog "User did not enter a current version"
			printf "\n\n• ERROR: Current version can not be blank\n\n"
			promptNewVersion
		fi

	fi

	printf "\n• Current version: ${currentVersion}\n\n"
	ScriptLog "Current version: ${currentVersion}"

	ScriptLog "Prompting user for new version number ..."

	read -p "Please specify the new version number: `echo $'\n> '`" newVersion
	ScriptLog "New version number: ${newVersion}"
	echo " "
	if [[ -z ${newVersion} ]]; then
		ScriptLog "User did not enter a new version"
		printf "\n\n• ERROR: New version can not be blank"
		promptNewVersion
	fi

	read -n 1 -r -p "Are you sure you want to update version \"${currentVersion}\" to version \"${newVersion}\"? [y]es, [n]o or e[x]it: `echo $'\n> '`" confirmUpdate
	ScriptLog "Are you sure you want to update version \"${currentVersion}\" to version \"${newVersion}\"?: ${confirmUpdate}"

	case "${confirmUpdate}" in

		y|Y )

			updatePolicyVersion

			updatePackageID

			;;

		n|N )

			ScriptLog "Prompt user for new version ..."

			/usr/bin/clear

			promptNewVersion

			;;

		x|X)

			ScriptLog "Exiting. Goodbye!"
			printf "\n\nExiting. Goodbye!\n\n"
			exit 0
			;;

		*)

			printf "\n\nERROR: Did not recognize response: ${confirmUpdate}; exiting.\n\n"
			exit 1
			;;

	esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Policy Version
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updatePolicyVersion() {

	printf "\n\n-------------------------------------------------------------------------------------------------------\n"
	printf "\n###\n"
	echo "# Step 5 of 6: Update Policy"
	printf "###\n\n"

	echo "• Replacing \"${currentVersion}\" with \"${newVersion}\" ..."
	ScriptLog "Replacing \"${currentVersion}\" with \"${newVersion}\" ..."
	/usr/bin/sed -i.bak1 "s|${currentVersion}|${newVersion}|g" ${updatesDirectory}/policy-${policyID}.xml

	echo "• Done."

	newpolicyName=$( /usr/bin/xmllint --xpath "/policy/general/name/text()" ${updatesDirectory}/policy-${policyID}.xml )
	printf "• Updated Policy name: ${newpolicyName}\n"
	ScriptLog "Updated Policy name: ${newpolicyName}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Package ID
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updatePackageID() {

	echo "• Updating Package ID for \"${newpolicyName}\" ..."
	ScriptLog "Updating Package ID for  \"${newpolicyName}\" ..."

	currentPackageID=$( /usr/bin/xmllint --xpath "/policy/package_configuration/packages/package/id/text()"  ${updatesDirectory}/policy-${policyID}.xml )
	echo "• The \"${policyName}\" policy has a Package ID of: ${currentPackageID}"

	newPackageName=$( /usr/bin/xmllint --xpath "/policy/package_configuration/packages/package/name/text()"  ${updatesDirectory}/policy-${policyID}.xml )
	echo "• Determining Package ID for \"${newPackageName}\" ..."

	newPackageNameScrubbed=$( echo ${newPackageName} | sed 's| |%20|g' )

	newPackageID=$( /usr/bin/curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/packages/name/${newPackageNameScrubbed}" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}')

	echo "• Package \"${newPackageName}\" has an ID of: ${newPackageID} ..."

	echo "• Updating Package ID from \"${currentPackageID}\" to \"${newPackageID}\" ..."

	/usr/bin/sed -i.bak2 "s|<package><id>${currentPackageID}|<package><id>${newPackageID}|" ${updatesDirectory}/policy-${policyID}.xml

	echo "• Done."

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt Upload New Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptUploadNewPolicy() {

	unset uploadChoice

	printf "\n-------------------------------------------------------------------------------------------------------\n"
	printf "\n###\n"
	echo "# Step 6 of 6: Upload New Policy"
	printf "###\n\n"

	printf "• New Policy Name: ${newpolicyName}\n\n"

	# Prompt user for permission to proceed
	read -n 1 -r -p "Would you like to upload this policy? [y]es or [n]o: `echo $'\n> '`" uploadChoice
	ScriptLog "Would you like to upload this policy?: ${uploadChoice}"

	case "${uploadChoice}" in

		y|Y )

			uploadNewPolicy
			;;

		n|N )

			ScriptLog "Upload canceled; exiting."
			printf "\n\nUpload canceled; exiting.\n\n"
			exit 0
			;;

		*)

			ScriptLog "ERROR: Did not recognize response: $choice; exiting."
			printf "\nERROR: Did not recognize response: $choice; exiting."
			exit 1
			;;

	esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Upload New Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function uploadNewPolicy() {

	ScriptLog "Uploading ${newpolicyName} ..."
	printf "\n\n• Uploading \"${newpolicyName}\" ...\n"

	if [[ ${debug} ==  "true" ]]; then
		ScriptLog "Debug mode enabled; displaying output of curl command to user ..."
		/usr/bin/curl -u "$apiUser":"$apiPassword" $apiURL/JSSResource/policies/id/${policyID} -H "Content-Type: application/xml" -X PUT -T ${updatesDirectory}/policy-${policyID}.xml
	else
		/usr/bin/curl -s -u "$apiUser":"$apiPassword" $apiURL/JSSResource/policies/id/${policyID} -H "Content-Type: application/xml" -X PUT -T ${updatesDirectory}/policy-${policyID}.xml
	fi

	ScriptLog "Uploaded ${newpolicyName} ..."
	printf "\n• Uploaded \"${newpolicyName}\" ...\n\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# View New Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function viewNewPolicy() {

	printf "\n-------------------------------------------------------------------------------------------------------\n"
	printf "\n###\n"
	echo "# Complete: View New Policy"
	printf "###\n\n"

	ScriptLog "Launching browser to view \"${newpolicyName}\" policy ..."
	printf "\n• Launching browser to view \"${newpolicyName}\" policy ...\n"
	/usr/bin/open $apiURL/policies.html?id=${policyID}

	printf "• Policy ID \"${policyID}\" has been updated to \"${newpolicyName}.\"\n\nTo revert Policy ID \"${policyID}\" to \"${policyName},\" use the following Terminal command:\n\n\t"
	if [[ ${debug} ==  "true" ]]; then
		ScriptLog "Debug mode enabled; displaying API password ..."
		echo "/usr/bin/curl -k -u ${apiUser}:${apiPassword} ${apiURL}/JSSResource/policies/id/${policyID} -H \"Content-Type: application/xml\" -X PUT -T ${backupDirectory}/policy-${policyID}.xml ; /usr/bin/open $apiURL/policies.html?id=${policyID}"
	else
		echo "/usr/bin/curl -k -u ${apiUser}:API_PASSWORD_GOES_HERE ${apiURL}/JSSResource/policies/id/${policyID} -H \"Content-Type: application/xml\" -X PUT -T ${backupDirectory}/policy-${policyID}.xml"
	fi

	ScriptLog "Policy updated"
	printf "\n\n\n***************************************** Policy Updated *****************************************\n\n\n"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt to Continue
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptToContinue(){

	unset choice

	ScriptLog "Prompting user to confirm selection ..."

	# Prompt user for permission to proceed
	read -n 1 -r -p "Would you like to update this policy? [y]es or [n]o: `echo $'\n> '`" choice
	ScriptLog "Would you like to update this policy?: ${choice}"

	case "${choice}" in

		y|Y )

			ScriptLog "Updating policy ..."

			downloadBackupXML				# Download and backup the XML

			promptNewVersion				# Prompt the user for the new version

			promptUploadNewPolicy		# Prompt to upload the new policy using the supplied API password

			;;

		n|N )

			ScriptLog "Prompting user to select a different policy ..."
			/usr/bin/clear
			selectPolicy
			;;

		*)

			ScriptLog "ERROR: Did not recognize response: $choice; exiting."
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

createWorkingDirectory

echo "#####################################"
echo "# Jamf Pro Policy Editor Lite, v1.4 #"
echo "#####################################"
echo " "
echo "This script updates a selected policy's version number. For example, the policy for
\"Adobe Prelude CC 2018 (7.1.1)\" would be updated to: \"Adobe Prelude CC 2018 (7.1.2).\"
"

if [[ ${debug} ==  "true" ]]; then
	printf "###\n# DEBUG MODE ENABLED\n###\n\n"
	ScriptLog "DEBUG MODE ENABLED"
	/usr/bin/open "${logFile}"
	/usr/bin/osascript -e 'tell application "Console" to activate'
fi

if [[ -z ${apiURL} && -z ${apiUser} && -z ${apiPassword} ]]; then
	ScriptLog "API credentials blank; prompt user to select lane ..."
	laneSelection
fi

apiConnectionSettings

validateAPIConnection

selectPolicy

viewNewPolicy

exit 0
