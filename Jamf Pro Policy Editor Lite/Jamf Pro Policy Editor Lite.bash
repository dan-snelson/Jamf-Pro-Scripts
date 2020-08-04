#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Jamf Pro Policy Editor Lite: Edit a policy's version number via the API
#
#	https://github.com/dan-snelson/Jamf-Pro-Scripts/
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
#		Limit policy names displayed by including a search string when calling the script (see "foundry" below)
#		./Jamf\ Pro\ Policy\ Editor\ Lite.sh foundry
#
#	Version 1.4, 10-Oct-2019, Dan K. Snelson
#		Enabled debug mode by default
#		Added more robust debug logging for failed API connections
#
#	Version 1.4.1, 27-Jul-2020, Dan K. Snelson
#		Updated URL open command for ZSH
#
#	Version 1.4.2, 01-Aug-2020, Dan K. Snelson
#		Greatly enhanced error-checking for missing packages
#		Row highlighting in policy list
#		General updates and performance improvements
#
#	Version 1.4.3, 04-Aug-2020, Dan K. Snelson
#		Added option to display package names when selecting the policy to update (inspired by Stew)
#		Formatting
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

scriptVersion="1.4.3"

# Values for API connection; if left blank, you will be prompted to interactively enter.
# If you have multiple lanes, fill-in variables in the "laneSelection" function below.
apiURL=""
apiUser=""
apiPassword=""

# Debug mode [ true | false ]
debug="true"

# ------------------------------ No edits required below this line --------------------------------

# String to match in policy name
args=("$@")
policyNameSearchString="${args[0]}"

# Divider Line
dividerLine="\n--------------------------------------------------------------------------------------------------------|\n"

# Any Colour You Like
red=$'\e[1;31m'
green=$'\e[1;32m'
yellow=$'\e[1;33m'
blue=$'\e[1;34m'
cyan=$'\e[1;36m'
resetColor=$'\e[0m'



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
	loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )

	# Time stamp for log file
	timestamp=$( date '+%Y-%m-%d-%H%M%S' )

	# Working Directory
	workingDirectory="/Users/${loggedInUser}/Documents/Jamf_Pro_Policy_Editor_Lite"
	logDirectory="${workingDirectory}/Logs/"
	logFile="${logDirectory}/Jamf_Pro_Policy_Editor_Lite-${timestamp}.log"

	# Ensure Working Directory exists
	if [[ ! -d ${workingDirectory} ]]; then
		mkdir -p ${workingDirectory}
	fi

	# Ensure Log Directory exists
	if [[ ! -d ${logDirectory} ]]; then
		mkdir -p ${logDirectory}
	fi

	# Ensure Log File exists
	if [[ ! -d ${logFile} ]]; then
		touch ${logFile}
		if [[ ${debug} == "true" ]]; then
			printf "###\n#\n# Jamf Pro Policy Editor Lite\n# Version: ${scriptVersion}\n#\n# Log file created on:\n# ${timestamp}\n#\n# Working Directory Filesize and Location\n# `du -sh ${workingDirectory}`\n#\n###\n\n" >> ${logFile}
		else
			printf "###\n#\n# Jamf Pro Policy Editor Lite\n# Version: ${scriptVersion}\n#\n# Log file created on:\n# ${timestamp}\n#\n###\n\n" >> ${logFile}
		fi
	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function ScriptLog() { # Re-direct logging to the log file ...

	NOW=`date +%Y-%m-%d\ %H:%M:%S`
	echo "${NOW}" " ${1}" >> "${logFile}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reveal File in Finder
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function revealMe() {

	open -R "${1}"

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

	SECONDS="0"

	read -n 1 -r -p "`echo $'\n> '`" lane
	ScriptLog "Please select a lane: ${lane}"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

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

		ScriptLog "ERROR: Did not recognize response: ${lane}; exiting."
		printf "\n${red}ERROR:${resetColor} Did not recognize response: ${lane}; exiting."
		exit 1
		;;

	esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# API Connection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function apiConnectionSettings() {

	printf "\n${dividerLine}"
	printf "\n###\n"
	echo "# Step 1 of 6: API Connection Settings"
	printf "###"

	SECONDS="0"

	promptAPIurl

	promptAPIusername

	promptAPIpassword

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API URL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIurl() {

	SECONDS="0"

	if [[ -z "${apiURL}" ]]; then
		ScriptLog "API URL is blank; attempt to read from JAMF plist ..."
		# read the API URL from the JAMF preferences
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

			case "${urlResponse}" in

				y|Y)

					apiURL="${apiURL}"
					;;

				n|N)

					printf "\n\nEnter the API URL:"
					read -r -p "`echo $'\n> '`" newURLResponse
					if [[ -z "${newURLResponse}" ]]; then
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
					printf "\n\n${red}ERROR:${resetColor} Invalid response; exiting.\n\n"
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

			case "${urlResponse}" in

				y|Y)

					printf "\n\nEnter the API URL:"
					read -r -p "`echo $'\n> '`"  userURLResponse
					if [[ -z "${userURLResponse}" ]]; then
						ScriptLog "No API URL provided; exiting."
						printf "\nNo API URL provided; exiting.\n\n"
						exit 0
					fi
					apiURL="${userURLResponse}"
					ScriptLog "API URL: ${apiURL}"
					;;

				n|N)

					ScriptLog "Exiting. Goodbye!"
					printf "\n\nExiting. Goodbye!\n\n"
					exit 0
					;;

				*)

					ScriptLog "ERROR: Invalid response ${urlResponse}; exiting."
					printf "\n\n${red}ERROR:${resetColor} Invalid response; exiting.\n\n"
					exit 1
					;;

			esac
		fi
	fi

	apiURL=$( echo "${apiURL}" | sed 's|/$||' )

	ScriptLog "Using the API URL of: ${apiURL}"
	printf "\n\n• Using the API URL of: ${apiURL}"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API Username
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIusername() {

	SECONDS="0"

	if [[ -z "${apiUser}" ]]; then
		ScriptLog "No API Username has been supplied. Enter it now?"
		printf "\n\nNo API Username has been supplied. Enter it now?

[y] Yes - Enter the Username at the next prompt
[n] No - Exit
"

		read -n 1 -r -p "`echo $'\n> '`" apiUsernameResponse

		case "${apiUsernameResponse}" in

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

				ScriptLog "Exiting. Goodbye!"
				printf "\n\nExiting. Goodbye!\n\n"
				exit 0
				;;

			*)

				printf "\n\n${red}ERROR:${resetColor} Invalid response! Please try again."
				ScriptLog "ERROR: Invalid response! Please try again."
				promptAPIusername
				;;

		esac

	fi

	ScriptLog "Using the API Username of: ${apiUser}"
	printf "\n• Using the API Username of: ${apiUser}"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user for API Password
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptAPIpassword() {

	SECONDS="0"

	if [[ -z "${apiPassword}" ]]; then
		ScriptLog "No API Password has been supplied. Enter it now?"
		printf "\n\nNo API Password has been supplied. Enter it now?

[y] Yes - Enter the password at the next prompt
[n] No - Exit
"

		read -n 1 -r -p "`echo $'\n> '`" apiPasswordEntryResponse

		case "${apiPasswordEntryResponse}" in

			y|Y)

				printf "\n\nAPI Password:\n>"
				read -s apiPasswordEntry
				if [[ -z "${apiPasswordEntry}" ]]; then
					ScriptLog "No API Password provided; exiting."
					printf "\nNo API Password provided; exiting.\n\n"
					exit 0
				fi
				apiPassword="${apiPasswordEntry}"
				;;

			n|N)

				ScriptLog "Exiting. Goodbye!"
				printf "\n\nExiting. Goodbye!\n\n"
				exit 0
				;;

			*)

				printf "\n\n${red}ERROR:${resetColor} Invalid response! Please try again."
				ScriptLog "ERROR: Invalid response! Please try again."
				promptAPIpassword
				;;

		esac

	fi

	if [[ ${debug} == "true" ]]; then
		ScriptLog "DEBUG MODE ENABLED: Displaying API Password ..."
		ScriptLog "Using the API Password of: ${apiPassword}"
		printf "\n• ${green}DEBUG MODE ENABLED:${resetColor} Displaying API Password ..."
		printf "\n• Using the API Password of: ${apiPassword}\n"
	else
		printf "\n• Using the supplied API password\n"
	fi

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate API Connection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateAPIConnection() {

	SECONDS="0"

	if [[ ${debug} == "true" ]]; then
		ScriptLog "DEBUG MODE ENABLED: Displaying curl command output ..."
		printf "• ${green}DEBUG MODE ENABLED:${resetColor} Displaying curl command output ...\n"
		result=$( curl -w " %{http_code}" -m 10 -u "${apiUser}":"${apiPassword}" "${apiURL}/JSSResource/computers" -X GET -H "Accept: application/xml" )
		statusCode=$( echo ${result} | awk '{print $NF}' )
		if [[ ${statusCode} = "401" ]]; then
			ScriptLog "DEBUG MODE ENABLED: Displaying API Connection Settings ..."
			ScriptLog "ERROR: API Connection Settings Incorrect; exiting."
			printf "\n${green}DEBUG MODE ENABLED:${resetColor} Displaying API Connection Settings ...\n"
	 		printf "\n${red}ERROR:${resetColor} API Connection Settings Incorrect; exiting.\n\nConsider trying again with your administrative Jamf Pro credentials.\n\nIf that works, double-check the permissions for the \"${apiUser}\" Jamf Pro account.\n\n"
			echo "API URL:      ${apiURL}"
			echo "API User:     ${apiUser}"
			echo "API Password: ${apiPassword}"
			echo "Status Code:  ${statusCode}"
	 		exit 1
		fi
	else
		result=$( curl -w " %{http_code}" -m 10 -sku "${apiUser}":"${apiPassword}" "${apiURL}/JSSResource/computers" -X GET -H "Accept: application/xml" )
		statusCode=$( echo ${result} | awk '{print $NF}' )
		if [[ ${statusCode} = "401" ]]; then
			ScriptLog "ERROR: API Connection Settings Incorrect; exiting."
	 		printf "\n${red}ERROR:${resetColor} API Connection Settings Incorrect; exiting\n\n"
			echo "Status Code: ${statusCode}"
	 		exit 1
		fi
	fi

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Select Policy to Update (Thanks, mm2270!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selectPolicy() {

	# Reset Variables
	ScriptLog "Reset variables ..."
	unset policyNames policyIDs policyName policyNamesArray policyID policyIDsArray policyChoice #SECONDS

	printf "${dividerLine}"
	printf "\n###\n"
	echo "# Step 2 of 6: Select Policy to Update"
	if [[ ! -z ${policyNameSearchString} ]]; then
		echo "# Limit to policy names containing \"${policyNameSearchString}\""
	fi
	printf "###\n\n"

	# Build two lists via the API: One for Policy names; the other for their respective IDs.
	ScriptLog "Building list of policy names via API ..."
	printf "Building list of policy names via API ...\n\n"

	SECONDS="0"

	policyNames=$( curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/policies" | xmllint --format - | awk -F'>|<' '/<name>/{print $3}')

	# Exit if API connection settings are incorrect
	if [[ -z ${policyNames} ]]; then
		ScriptLog "ERROR: API connection settings incorrect; exiting"
		printf "\n\n${red}ERROR:${resetColor} API connection settings incorrect; exiting\n\n"
		exit 1
	fi

	ScriptLog "Build list of policy IDs via API ..."
	policyIDs=$( curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/policies" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}')

	# Create array for Policy names
	ScriptLog "Create array for Policy names ..."
	while read policyName; do
		policyNamesArray+=( "${policyName}" )
	done < <( printf '%s\n' "${policyNames}" )

	# Create array for Policy IDs
	ScriptLog "Create array for Policy IDs ..."
	while read policyID; do
		policyIDsArray+=( "${policyID}" )
	done < <( printf '%s\n' "${policyIDs}" )

	# Display Policy names with index labels
	ScriptLog "Display Policy names with index labels ..."
	for i in "${!policyNamesArray[@]}"; do
		if [[ -z ${policyNameSearchString} ]]; then
			if [ $((i%2)) -eq 0 ]; then
				printf "%s\t%s\n" "${yellow}[$i] ${policyNamesArray[$i]}${resetColor}"
			else
				printf "%s\t%s\n" "[$i] ${policyNamesArray[$i]}"
			fi
		else
			ScriptLog "Limit to policy names containing ${policyNameSearchString} ..."
			if [ $((i%2)) -eq 0 ]; then
				printf "%s\t%s\n" "${cyan}[$i] ${policyNamesArray[$i]}${resetColor}" | grep -i ${policyNameSearchString}
			else
				printf "%s\t%s\n" "[$i] ${policyNamesArray[$i]}" | grep -i ${policyNameSearchString}
			fi
		fi
	done

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

	ScriptLog "Prompting user to select policy ..."

	SECONDS="0"

	printf "\nChoose the Policy to update by entering its index number, view all [p]ackages or e[x]it:"

	read -r -p "`echo $'\n> '`" policyChoice

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

	if [[ "${policyChoice}" == "p" ]]; then
		ScriptLog "Displaying a list of packages"
		packageNames=$( curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/packages" | xmllint --format - | awk -F'>|<' '/<name>/{print $3}')
		printf "\nPackage Names:\n\n"
		printf "${packageNames}"
		unset policyChoice
		printf "\n\nChoose the Policy to update by entering its index number or e[x]it:"
		read -r -p "`echo $'\n> '`" policyChoice
	fi

	if [[ "${policyChoice}" == "x" ]]; then
		ScriptLog "User entered \"${policyChoice}\"; exiting."
		ScriptLog "Exiting. Goodbye!"
		printf "\n\nExiting. Goodbye!\n\n"
		exit 0
	fi

	if [[ "${policyChoice}" -eq "${policyChoice}" ]] 2>/dev/null; then
		ScriptLog "Policy index: ${policyChoice}"
	else
		ScriptLog "ERROR: \"${policyChoice}\" is not an index number; exiting."
		printf "\n${red}ERROR:${resetColor} \"${policyChoice}\" is not an index number; exiting.\n\n\n"
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

	SECONDS="0"

	printf "\n${dividerLine}"
	printf "\n###\n"
	echo "# Step 3 of 6: Download and Backup Policy XML"
	printf "###\n\n"

	echo "• Downloading XML for Policy ID ${policyID} ..."
	ScriptLog "Downloading XML for Policy ID ${policyID} ..."

	# Backup Directory
	backupDirectory="${workingDirectory}/Backups/${timestamp}"

	# Ensure Backup Directory exists
	if [[ ! -d ${backupDirectory} ]]; then
		mkdir -p ${backupDirectory}
		ScriptLog "Created backup directory: ${backupDirectory}"
	fi

	# Updates Directory
	updatesDirectory="${workingDirectory}/Updates/${timestamp}"

	# Ensure Update Directory exists
	if [[ ! -d ${updatesDirectory} ]]; then
		mkdir -p ${updatesDirectory}
		ScriptLog "Created update directory: ${updatesDirectory}"
	fi

	# Download policy XML
	if [[ ${debug} == "true" ]]; then
		ScriptLog "DEBUG MODE ENABLED: Displaying curl command output ..."
		printf "\n\n${green}DEBUG MODE ENABLED:${resetColor} Displaying curl command output ...\n"
		curl -u "${apiUser}":"${apiPassword}" ${apiURL}/JSSResource/policies/id/${policyID} -H "Accept: application/xml" -X GET -o ${backupDirectory}/policy-${policyID}.xml
	else
		curl -s -u "${apiUser}":"${apiPassword}" ${apiURL}/JSSResource/policies/id/${policyID} -H "Accept: application/xml" -X GET -o ${backupDirectory}/policy-${policyID}.xml
	fi
	echo "• Downloaded to: ${backupDirectory}/policy-${policyID}.xml ..."
	ScriptLog "Downloaded to: ${backupDirectory}/policy-${policyID}.xml"

	# Copy downloaded XML to Updates directory
	echo "• Copying ../Backups/policy-${policyID}.xml to ../Updates/policy-${policyID}.xml"
	ScriptLog "Copying ../Backups/policy-${policyID}.xml to ../Updates/policy-${policyID}.xml"
	if [[ ${debug} ==  "true" ]]; then
		ScriptLog "DEBUG MODE ENABLED: Displaying cp command output ..."
		printf "\n\n${green}DEBUG MODE ENABLED:${resetColor} Displaying cp command output ...\n"
		cp -v ${backupDirectory}/policy-${policyID}.xml ${updatesDirectory}/policy-${policyID}.xml
	else
		cp ${backupDirectory}/policy-${policyID}.xml ${updatesDirectory}/policy-${policyID}.xml
	fi
	echo "• Copied to ../Updates/policy-${policyID}.xml"
	ScriptLog "Copied to ../Updates/policy-${policyID}.xml"

	# Exit if update file does not exist
	if [[ ! -f "${updatesDirectory}/policy-${policyID}.xml" ]]; then
		printf "${red}ERROR:${resetColor} Policy file \"../Updates/policy-${policyID}.xml\" does NOT exist; exiting"
		ScriptLog "ERROR: Policy file \"../Updates/policy-${policyID}.xml\" does NOT exist; exiting"
		exit 1
	fi

	printf "${dividerLine}"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt the user for the new version number
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptNewVersion() {

	SECONDS="0"

	printf "\n###\n"
	echo "# Step 4 of 6: Specify new version number"
	printf "###\n\n"

	# Lookup policy name
	policyName=$( xmllint --xpath "/policy/general/name/text()" ${updatesDirectory}/policy-${policyID}.xml )
	printf "• Policy Name: ${policyName}\n"
	ScriptLog "Policy Name: ${policyName}"

	# Determine current version
	currentVersion=$( echo ${policyName} | awk -F"[()]" '{print $2}' )	# For policy names where the version is inside parenthesis
	# currentVersion=$( echo ${policyName} | awk -F"[-]" '{print $2}' )	# For policy names where the version is after a dash
	if [[ -z ${currentVersion} ]]; then
		currentPackageName=$( xmllint --xpath "/policy/package_configuration/packages/package/name/text()" ${updatesDirectory}/policy-${policyID}.xml )

		if [[ -z ${currentPackageName} ]]; then
			printf "\n\n\n###\n#\n# ${red}ERROR:${resetColor} The policy \"${policyName}\" does NOT appear to include a package.\n# Please select a different policy.\n#\n###\n\n\n"
			ScriptLog "ERROR: The policy \"${policyName}\" does NOT appear to include a package."
			ScriptLog "Pause for 10 seconds"
			sleep 10
			selectPolicy
		fi

		# Prompt user for current version
		printf "• Current version: UNKOWN\n"
		printf "• Current Package Name: ${currentPackageName}\n\n"

		read -p "Please specify the current version number: (e[x]it)`echo $'\n> '`" currentVersion
		ScriptLog "Current version number: ${currentVersion}"

		if [[ -z ${currentVersion} ]]; then
			ScriptLog "User did not enter a current version"
			printf "\n\n• ${red}ERROR:${resetColor} Current version can not be blank\n\n"
			promptNewVersion
		fi

		if [[ ${currentVersion} == "x" ]]; then
			ScriptLog "ERROR: \"${currentVersion}\" entered for current version number; exiting."
			printf "\n${red}ERROR:${resetColor} \"${currentVersion}\" entered for current version number; exiting.\n\n\n"
			exit 0
		fi

	fi

	ScriptLog "Current version: ${currentVersion}"
	printf "• Current version: ${currentVersion}\n\n"

	ScriptLog "Prompting user for new version number ..."

	read -p "Please specify the new version number: (e[x]it)`echo $'\n> '`" newVersion
	ScriptLog "New version number: ${newVersion}"
	echo " "
	if [[ -z ${newVersion} ]]; then
		ScriptLog "User did not enter a new version"
		printf "\n\n• ${red}ERROR:${resetColor} New version can not be blank"
		promptNewVersion
	fi

	if [[ ${newVersion} == "x" ]]; then
		ScriptLog "ERROR: \"${newVersion}\" entered for new version number; exiting."
		printf "\n${red}ERROR:${resetColor} \"${newVersion}\" entered for new version number; exiting.\n\n\n"
		exit 0
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

			clear

			promptNewVersion

			;;

		x|X)

			ScriptLog "Exiting. Goodbye!"
			printf "\n\nExiting. Goodbye!\n\n"
			exit 0
			;;

		*)

			ScriptLog "ERROR: Did not recognize response: ${confirmUpdate}; exiting."
			printf "\n\n${red}ERROR:${resetColor} Did not recognize response: ${confirmUpdate}; exiting.\n\n"
			exit 1
			;;

	esac

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Policy Version
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updatePolicyVersion() {

	SECONDS="0"

	printf "\n${dividerLine}"
	printf "\n###\n"
	echo "# Step 5 of 6: Update Policy"
	printf "###\n\n"

	echo "• Replacing \"${currentVersion}\" with \"${newVersion}\" ..."
	ScriptLog "Replacing \"${currentVersion}\" with \"${newVersion}\" ..."
	sed -i.bak1 "s|${currentVersion}|${newVersion}|g" ${updatesDirectory}/policy-${policyID}.xml

	echo "• Done."

	updatedPolicyName=$( xmllint --xpath "/policy/general/name/text()" ${updatesDirectory}/policy-${policyID}.xml )
	printf "• Updated Policy name: ${updatedPolicyName}\n"
	ScriptLog "Updated Policy name: ${updatedPolicyName}"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Package ID
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updatePackageID() {

	SECONDS="0"

	echo "• Updating Package ID for \"${updatedPolicyName}\" ..."
	ScriptLog "Updating Package ID for  \"${updatedPolicyName}\" ..."

	currentPackageID=$( xmllint --xpath "/policy/package_configuration/packages/package/id/text()" ${updatesDirectory}/policy-${policyID}.xml )
	echo "• The \"${policyName}\" policy has a Package ID of: ${currentPackageID}"

	newPackageName=$( xmllint --xpath "/policy/package_configuration/packages/package/name/text()" ${updatesDirectory}/policy-${policyID}.xml )
	echo "• Determining Package ID for \"${newPackageName}\" ..."

	newPackageNameScrubbed=$( echo ${newPackageName} | sed 's| |%20|g' )

	newPackageID=$( curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPassword}" "${apiURL}/JSSResource/packages/name/${newPackageNameScrubbed}" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}')

	if [[ -z ${newPackageID} ]]; then
		printf "\n\n###\n#\n# ${red}ERROR:${resetColor} A package named \"${newPackageName}\" was NOT found!\n#\n# Please upload \"${newPackageName}\" before proceeding.\n#\n# Exiting.\n#\n###\n\n\n"
		ScriptLog "ERROR: \"${newPackageName}\" NOT found; please upload \"${newPackageName}\" before proceeding; exiting."
		exit 1
	fi

	echo "• Package \"${newPackageName}\" has an ID of: ${newPackageID} ..."

	echo "• Updating Package ID from \"${currentPackageID}\" to \"${newPackageID}\" ..."

	sed -i.bak2 "s|<package><id>${currentPackageID}|<package><id>${newPackageID}|" ${updatesDirectory}/policy-${policyID}.xml

	echo "• Done."

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt Upload New Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptUploadUpdatedPolicy() {

	SECONDS="0"

	unset uploadChoice

	printf "${dividerLine}"
	printf "\n###\n"
	echo "# Step 6 of 6: Upload Updated Policy"
	printf "###\n\n"

	printf "• Updated Policy Name: ${updatedPolicyName}\n\n"

	# Prompt user for permission to proceed
	read -n 1 -r -p "Would you like to upload this policy? [y]es or [n]o: `echo $'\n> '`" uploadChoice
	ScriptLog "Would you like to upload this policy?: ${uploadChoice}"

	case "${uploadChoice}" in

		y|Y )

			uploadUpdatedPolicy
			;;

		n|N )

			ScriptLog "Upload canceled; exiting."
			printf "\n\nUpload canceled; exiting.\n\n"
			exit 0
			;;

		*)

			ScriptLog "ERROR: Did not recognize response: ${uploadChoice}; exiting."
			printf "\n${red}ERROR:${resetColor} Did not recognize response: ${uploadChoice}; exiting."
			exit 1
			;;

	esac

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Upload New Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function uploadUpdatedPolicy() {

	SECONDS="0"

	ScriptLog "Uploading ${updatedPolicyName} ..."
	printf "\n\n• Uploading \"${updatedPolicyName}\" ...\n"

	if [[ ${debug} == "true" ]]; then
		ScriptLog "DEBUG MODE ENABLED: Displaying curl command output ..."
		printf "${green}DEBUG MODE ENABLED:${resetColor} Displaying curl command output ..."
		curl -u "${apiUser}":"${apiPassword}" ${apiURL}/JSSResource/policies/id/${policyID} -H "Content-Type: application/xml" -X PUT -T ${updatesDirectory}/policy-${policyID}.xml
	else
		curl -s -u "${apiUser}":"${apiPassword}" ${apiURL}/JSSResource/policies/id/${policyID} -H "Content-Type: application/xml" -X PUT -T ${updatesDirectory}/policy-${policyID}.xml
	fi

	ScriptLog "Uploaded ${updatedPolicyName} ..."
	printf "\n• Uploaded \"${updatedPolicyName}\" ...\n\n"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# View New Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function viewUpdatedPolicy() {

	SECONDS="0"

	printf "${dividerLine}"
	printf "\n###\n"
	echo "# Complete: View Updated Policy"
	printf "###\n\n"

	ScriptLog "Launching browser to view \"${updatedPolicyName}\" policy ..."
	printf "• Launching browser to view \"${updatedPolicyName}\" policy ...\n"
	open "${apiURL}/policies.html?id=${policyID}"

	printf "• Policy ID \"${policyID}\" has been updated to \"${updatedPolicyName}.\"\n\nTo revert Policy ID \"${policyID}\" to \"${policyName},\" copy-and-paste the following Terminal command:\n\n\t"
	if [[ ${debug} == "true" ]]; then
		ScriptLog "DEBUG MODE ENABLED: Displaying API password ..."
		printf "${green}DEBUG MODE ENABLED:${resetColor} Displaying API password ...\n\n\t"
		echo "curl -k -u ${apiUser}:${apiPassword} ${apiURL}/JSSResource/policies/id/${policyID} -H \"Content-Type: application/xml\" -X PUT -T ${backupDirectory}/policy-${policyID}.xml ; open '$apiURL/policies.html?id=${policyID}'"
	else
		echo "curl -k -u ${apiUser}:API_PASSWORD_GOES_HERE ${apiURL}/JSSResource/policies/id/${policyID} -H \"Content-Type: application/xml\" -X PUT -T ${backupDirectory}/policy-${policyID}.xml ; open '$apiURL/policies.html?id=${policyID}'"
	fi

	ScriptLog "Policy updated"
	printf "\n\n***************************************** Policy Updated *****************************************\n\n\n\n\n\n"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt to Continue
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptToContinue(){

	unset choice

	ScriptLog "Prompting user to confirm selection ..."

	SECONDS="0"

	# Prompt user for permission to proceed
	read -n 1 -r -p "Would you like to update this policy? [y]es, [n]o or e[x]it: `echo $'\n> '`" choice
	ScriptLog "Would you like to update this policy?: ${choice}"

	ScriptLog "Elapsed Time: ${SECONDS} seconds"
	ScriptLog ""

	case "${choice}" in

		y|Y )

			ScriptLog "Updating policy ..."

			downloadBackupXML		# Download and backup the XML

			promptNewVersion		# Prompt the user for the new version

			promptUploadUpdatedPolicy	# Prompt to upload the new policy using the supplied API password

			;;

		n|N )

			ScriptLog "Prompting user to select a different policy ..."
			clear
			selectPolicy
			;;

		*)

			ScriptLog "ERROR: Did not recognize response: ${choice}; exiting."
			printf "\n\n${red}ERROR:${resetColor} Did not recognize response: ${choice}; exiting.\n\n\n"
			exit 1
			;;

	esac

}



####################################################################################################
#
# Main Program
#
####################################################################################################

printf '\e[8;55;105t' ; printf '\e[3;10;10t' ; clear

echo "###"
printf "# Jamf Pro Policy Editor Lite, ${yellow}${scriptVersion}${resetColor}\n"
echo "###"
echo " "
echo "This script updates a selected policy's version number. For example, the policy for
\"Cloud Foundry Install (7.0.0)\" would be updated to: \"Cloud Foundry Install (7.0.1).\"
"

createWorkingDirectory

if [[ ${debug} == "true" ]]; then
	printf "###\n# ${green}DEBUG MODE ENABLED${resetColor}\n###\n\n"
	ScriptLog "DEBUG MODE ENABLED"
	open "${logFile}"
	osascript -e 'tell application "Console" to activate'
fi

if [[ -z ${apiURL} && -z ${apiUser} && -z ${apiPassword} ]]; then
	ScriptLog "API credentials blank; prompt user to select lane ..."
	laneSelection
fi

apiConnectionSettings

validateAPIConnection

selectPolicy

viewUpdatedPolicy

exit 0
