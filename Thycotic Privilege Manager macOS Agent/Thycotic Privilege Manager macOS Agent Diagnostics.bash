#!/bin/bash
####################################################################################################
#
#	Thycotic Privilege Manager macOS Agent Diagnostics for your Help Desk
#
#	Purpose: Diagnose the Thycotic Privilege Manager macOS Agent
#
#	Jamf Pro Script Parameter 4: Number of Kickstart Checks
#	Jamf Pro Script Parameter 5: Thycotic Agent Install Code
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 05-May-2020, Dan K. Snelson
#		Original Version
#
#	Version 1.0.1, 08-May-2020, Dan K. Snelson
#		Started updates for POSIX compliance
#		Added kickstart command for when agent reports "Unable to connect to update client items."
#
####################################################################################################



###
# Exit with error if Thycotic Privilege Manager macOS Agent is NOT installed
###

if [ ! -d "/usr/local/thycotic" ] ; then
	echo "Thycotic Privilege Manager macOS Agent NOT installed; exiting."
	exit 1
fi



####################################################################################################
#
# Define the Variables
#
####################################################################################################

thycoticURL="https://company.privilegemanagercloud.com/Tms/" # Include trailing forward slash
privilegeManagerURL="${thycoticURL}PrivilegeManager/#"
agentRegistrationURL="${thycoticURL}Agent/AgentRegistration4.svc"
jamfProURL=$( /usr/bin/defaults read "/Library/Preferences/com.jamfsoftware.jamf.plist" jss_url | /usr/bin/sed 's|/$||'	)
case $jamfProURL in
	*"beta"*	)	jamfProAdminURL="https://jamfpro-beta.company.com" ;;
	*			)	jamfProAdminURL="https://jamfpro.company.com" ;;
esac

############################## No edits needed below this line ##############################

# Number of times to kickstart the agent (defaults to 3)
kickstartChecks="${4}"
# Check for a specified value for Kickstart Checks (Parameter 4)
if [ "${kickstartChecks}" = "" ]; then
	# "Parameter 4 is blank; using \"3\" as the number of times to kickstart the agent."
	kickstartChecks="3"
else
	kickstartChecks="${4}"
fi

# Agent Install Code (exit if blank)
agentInstallCode="${5}"
# Check for a specified value for Agent Install Code (Parameter 5)
if [ "${agentInstallCode}" = "" ]; then
	# Parameter 5 is blank; exit with error
	echo "Parameter 5 is blank; exit with error."
	exit 1
fi

loggedInUser=$( /usr/bin/stat -f %Su "/dev/console" )
loggedInUserHome=$( /usr/bin/dscl . -read /Users/$loggedInUser NFSHomeDirectory | /usr/bin/awk '{print $NF}' ) # mm2270
timeStamp=$( /bin/date '+%Y-%m-%d-%H%M%S' )
outputFileName="$loggedInUserHome/Desktop/$loggedInUser-ThycoticManagementAgentInformation-${timeStamp}.html"
privilegemanagerguiVersion=$( /usr/bin/defaults read /Applications/Privilege\ Manager.app/Contents/Info.plist CFBundleVersion )
thycoticMachineID=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist machine_id )
serialNumber=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep "Serial Number" | /usr/bin/awk -F ": " '{ print $2 }' )



####################################################################################################
#
# Define the Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Generate HTML
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

generateHTML() {

	if [ -f ${outputFileName} ]; then

		# outputFileName exists; update it
		# echo "Update HTML file ..."
		/bin/echo "${1}" >> ${outputFileName}

	else

		# outputFileName does NOT exist; create it
		echo "Create HTML file ..."
		/bin/echo "<!DOCTYPE html>
<html>
<head>
	<title>Thycotic Privilege Manager macOS Agent Information for $loggedInUser, S/N $serialNumber, Machine ID $thycoticMachineID</title>
	<base target=\"_blank\">
	<style>
		body {
			font-family: Georgia, serif;
			font-size: larger;
			line-height: 1.4em;
		}
		a {
			text-decoration: none;
			padding: 4px;
		}
		a:hover {
			background-color: #DDD;
			padding: 4px;
		}
		.warning {
			color: red;
		}
</style>
</head>
<body>
	<h1>Thycotic Privilege Manager macOS Agent Diagnostics</h1>
	<hr />" > ${outputFileName}

	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Calls to agentUtil.sh
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

agentUtil() {
	agentUtilAction=$( /usr/local/thycotic/agent/agentUtil.sh ${1} )
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate access to a given URL (i.e., Thycotic servers)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

validateURLaccess(){

	echo " "
	echo "--- Validate Access to ${1} ...---"
	echo " "

	unset testURL

	case ${2} in
		"xml"				)	testURL=$( /usr/bin/curl -sIX GET "${1}" | /usr/bin/head -n 1 ) ;;
		"html" | *	)	testURL=$( /usr/bin/curl -Is "${1}" | /usr/bin/head -n 1 ) ;;
	esac

	case ${testURL} in
		*"200"*	) urlAccess="PASSED" ;;
		*				) urlAccess="FAILED" ;;
	esac

	case ${urlAccess} in

		"PASSED" )
				echo "URL Status: ${urlAccess} to ${1}; proceed ..."
				generateHTML "<li>Testing access to ${1} ... ${urlAccess}</li>"
				;;

		"FAILED" )
				echo "URL Status: ${urlAccess} to ${1}; exit"
				generateHTML "<li>Testing access to ${1} ... ${urlAccess}</li>"
				generateHTML "</ul><hr />"
				generateHTML "<h2 class=\"warning\">URL Status: ${urlAccess}</h2>"
				generateHTML "<p class=\"warning\">Failed to connect to ${1}</p>"
				generateHTML "<hr />"
				echo "Close HTML document ..."
				generateHTML "</body></html>"

				if [ -f ${outputFileName} ]; then	# Look
					echo "Open HTML document in Safari ..."
					/usr/bin/su - ${loggedInUser} -c "open -a safari ${outputFileName}"
				fi

				echo "Results saved to: ${outputFileName}"

				exit 1	# Failure
				;;

	esac

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test Agent Connection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

testAgentConnection() {

	echo " "
	echo "--- Test Agent Connection ---"
	echo " "

	agentUtil "updateclientitems"

	case ${agentUtilAction} in
		*"Updating client items"*	) connectionStatus="PASSED" ;;
		*"Unable to connect"*			) connectionStatus="FAILED" ;;
	esac

	echo "* Connection Status: ${connectionStatus}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kickstart Agent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

kickstartAgent(){

	echo " "
	echo "--- Kickstart Agent ---"
	echo " "

	agentUtil "enableverboselogging"
	echo "${agentUtilAction}"

	testAgentConnection

	counter=1

	while [ "${connectionStatus}" = "FAILED" ] && [ "${counter}" -le "${kickstartChecks}" ] ; do

		echo "--------------------------------------"
		echo "* Test ${counter} of ${kickstartChecks} ..."
		counter="$((counter+1))"

		echo "* Connection Status: ${connectionStatus}"
		echo "* kickstarting agent ..."

		agentUtil "settmsserver -serverUri ${thycoticURL} -installCode ${agentInstallCode}"
		echo "* Result: ${agentUtilAction}"
		echo "* Pause for 5 seconds ..."
		/bin/sleep 5

		echo "* Re-test agent connection ..."
		testAgentConnection

	done

	echo "* Final kickstart Agent Connection Status: ${connectionStatus}"

	case ${connectionStatus} in

		"PASSED" )
			agentUtil "disableverboselogging"
			echo "* Result: ${agentUtilAction}"
			echo "* Pause for 5 seconds ..."
			/bin/sleep 5
			kickstartAgentResult="Successful"
			;;

		"FAILED" )
			echo "* Result: ${agentUtilAction}"
			kickstartAgentResult="Failure"
			;;

	esac

}



####################################################################################################
#
# Program
#
####################################################################################################

echo " "
echo "###"
echo "# Thycotic Privilege Manager macOS Agent Information"
echo "###"
echo " "


###
# Create the inital HTML document
###

generateHTML



###
# Connection Tests
###

# Test Thycotic-related URLs
echo "Test access to URLs"
generateHTML "<h2>URL Status: ${urlAccess}</h2><ul>"
validateURLaccess "${privilegeManagerURL}" "html"
validateURLaccess "${agentRegistrationURL}" "xml"
generateHTML "</ul><hr />"



# Test Agent Connection
echo "Test Agent Connection ..."
testAgentConnection

case ${connectionStatus} in

	"PASSED" )
			echo "Connection Status: ${connectionStatus}; proceed ..."
			generateHTML "<h2>Connection Status:</h2>"
			generateHTML "<p>${connectionStatus}; ${agentUtilAction}; proceeding ...</p>"
			generateHTML "<hr />"
			unset kickstartAgentResult
			;;

	"FAILED" )
			echo "Connection Status: ${connectionStatus}; attempt to connect ..."
			generateHTML "<h2>Connection Status:</h2>"
			generateHTML "<p class=\"warning\">${connectionStatus}; ${agentUtilAction}; Attempting to establish connection ...</p>"
			kickstartAgent
			;;

esac

case ${kickstartAgentResult} in
	"Successful" )
		generateHTML "<hr />"
		generateHTML "<h2>Kickstart Agent Results: ${kickstartAgentResult}</h2>"
		generateHTML "<p>Successfully kickstarted agent; proceeding ..."
		generateHTML "<hr />"
		;;

	"Failure" )
		generateHTML "<hr />"
		generateHTML "<h2 class=\"warning\">Kickstart Agent Results: ${kickstartAgentResult}</h2>"
		generateHTML "<p class=\"warning\">Failed to connect after ${kickstartChecks} attempts.</p>"
		generateHTML "<p class=\"warning\">Last agentUtil result: ${agentUtilAction}</p>"
		generateHTML "<hr />"
		echo "Close HTML document ..."
		generateHTML "</body></html>"

		if [ -f ${outputFileName} ]; then	# Look
			echo "Open HTML document in Safari ..."
			/usr/bin/su - ${loggedInUser} -c "open -a safari ${outputFileName}"
		fi

		echo "Results saved to: ${outputFileName}"

		exit 1	# Failure

		;;

esac



###
# Computer Information
###

echo "Computer Information ..."

generateHTML "<h2>Computer Information</h2>"
generateHTML "<ul>"
generateHTML "<li><strong>Execution Date:</strong> `date '+%Y-%m-%d-%H%M%S'`</li>"
generateHTML "<li><strong>Username:</strong> ${loggedInUser}</li>"
generateHTML "<li><strong>Serial Number:</strong> <a href=\"${jamfProAdminURL}/computers.html?queryType=Computers&query=${serialNumber}\"\">${serialNumber}</a></li>"
generateHTML "<li><strong>Privilege Manager:</strong> ${privilegemanagerguiVersion}</li>"
generateHTML "<li><strong>Machine GUID:</strong> <a href=\"$privilegeManagerURL/search/${thycoticMachineID}\"\">${thycoticMachineID}</a></li>"
generateHTML "</ul>"
generateHTML "<hr />"



###
# Agent Commands
###

echo "Agent Commands ..."

generateHTML "<h2>Agent Commands</h2>"
generateHTML "<ul>"
agentUtil "register"
generateHTML "<li><strong>Register:</strong> ${agentUtilAction}</li>"
agentUtil "updateclientitems"

case ${agentUtilAction} in
	*"Unable to connect"*	)	kickstartAgent ;;
esac

generateHTML "<li><strong>Update Client Items:</strong> ${agentUtilAction}</li>"
thycoticLastUpdated=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist last_updated )
generateHTML "<li><strong>Last Updated:</strong> ${thycoticLastUpdated} UTC</li>"
generateHTML "</ul>"
generateHTML "<hr />"



###
# Enabled Policies
###

echo "Enabled Policies ..."

agentUtil "clientitemsummary"

generateHTML "<h2>Enabled Policies</h2>"
generateHTML "<ol>"
enabledPolicies=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist enabled_policies | /usr/bin/tr -d '(")[:space:]' )
IFS=',' read -r -a enabledPoliciesArray <<< "${enabledPolicies}"
echo "${enabledPoliciesArray[@]}"
for policy in "${enabledPoliciesArray[@]}"
do
	hyperlinkText=$( /bin/echo "${agentUtilAction}" | /usr/bin/grep "${policy}" | /usr/bin/sed "s/${policy}//g" )
	generateHTML "<li><a href=\"$privilegeManagerURL/search/${policy}\">${hyperlinkText}</a></li>"
done
unset IFS
generateHTML "</ol>"
generateHTML "<hr />"



###
# Client Item Summary
###

echo "Client Item Summary ..."

generateHTML "<h2>Client Item Summary</h2>"
generateHTML "<ul>"
IFS=$'\n'
for row in $( /bin/echo "$agentUtilAction" | /usr/bin/head -5 )
do
 	generateHTML "<li>$row</li>"
done
generateHTML "</ul>"
generateHTML "<ol>"
for row in $( /bin/echo "$agentUtilAction" | /usr/bin/tail +7 )
do
	guid=$( /bin/echo "${row}" | /usr/bin/awk '{ print $3 }' )
 	hyperlinkText=$( /bin/echo "${row}" | /usr/bin/awk '{$3=""; print $0}' )
 	generateHTML "<li><a href=\"$privilegeManagerURL/search/${guid}\">${hyperlinkText}</a></li>"
done
unset IFS
generateHTML "</ol>"
generateHTML "<hr />"



##
Close HTML document
##

echo "Close HTML document ..."

generateHTML "</body\></html>"



###
# Open HTML document in Safari
###

if [ -f ${outputFileName} ]; then	# Look
	echo "Open HTML document in Safari ..."
	/usr/bin/su - ${loggedInUser} -c "open -a safari ${outputFileName}"
fi

echo "Results saved to: ${outputFileName}"

exit 0
