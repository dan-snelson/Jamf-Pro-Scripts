#!/bin/sh
####################################################################################################
#
#	Thycotic Privilege Manager macOS Agent Kickstart
#
#	Purpose: Kickstart the Thycotic Privilege Manager macOS Agent when "Updating Client Items" fails.
#
#	Jamf Pro Script Parameter 4: Number of Kickstart Checks
#	Jamf Pro Script Parameter 5: Thycotic Agent Install Code
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 12-May-2020, Dan K. Snelson
#		Original Version
#
####################################################################################################



####################################################################################################
#
# Exit gracefully if Thycotic Privilege Manager macOS Agent is NOT installed
#
####################################################################################################

if [ ! -d "/usr/local/thycotic" ] ; then
	kickstartResult="Thycotic Privilege Manager macOS Agent NOT installed; exiting."
	echo "${kickstartResult}"
	exit 0
else
	kickstartResult="PASSED Install"
fi



####################################################################################################
#
# Define the Variables
#
####################################################################################################

thycoticURL="https://company.privilegemanagercloud.com/Tms/" # Include trailing forward slash

############################## No edits needed below this line ##############################

privilegeManagerURL="${thycoticURL}PrivilegeManager/#"
agentRegistrationURL="${thycoticURL}Agent/AgentRegistration4.svc"

# Number of times to kickstart the agent (defaults to 3)
kickstartChecks="${4}"
# Check for a specified value for kickstart checks (Parameter 4)
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



####################################################################################################
#
# Define the Functions
#
####################################################################################################

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
	echo "--- Validate Access to ${1} ... ---"

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
				echo "URL Status: ${urlAccess} to ${1}"
				kickstartResult="${kickstartResult}; PASSED URL"
				;;

		"FAILED" )
				echo "URL Status: ${urlAccess} to ${1}"
				kickstartResult="${kickstartResult}; FAILED URL ${1}"
				;;

	esac

	echo " "

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test Agent Connection
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

testAgentConnection() {

	echo " "
	echo "--- Test Agent Connection ---"

	agentUtil "updateclientitems"

	case ${agentUtilAction} in
		*"Updating client items"*	) connectionStatus="PASSED" ;;
		*"Unable to connect"*			) connectionStatus="FAILED" ;;
	esac

	case ${connectionStatus} in

		"PASSED" )
			echo "Update Client Items Status: ${agentUtilAction}"
			kickstartResult="${kickstartResult}; PASSED Update Client Items"
			;;

		"FAILED" )
			echo "Update Client Items Status: ${agentUtilAction}"
			kickstartResult="${kickstartResult}; FAILED Update Client Items Status: ${agentUtilAction}"
			;;

	esac

	echo " "

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

	echo "* Final Kickstart Agent Connection Status: ${connectionStatus}"

	case ${connectionStatus} in

		"PASSED" )
			agentUtil "disableverboselogging"
			kickstartAgentResult="Successful"
			kickstartResult="${kickstartResult}; PASSED Kickstart"
			echo "* Result: ${kickstartResult}"
			;;

		"FAILED" )
			kickstartAgentResult="Failure"
			kickstartResult="${kickstartResult}; FAILED Kickstart"
			echo "* Result: ${kickstartResult}"
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
echo "# Thycotic Privilege Manager macOS Agent Kickstart"
echo "###"
echo " "



###
# Connection Tests
###

# Test Thycotic-related URLs
echo "Test access to URLs ..."
validateURLaccess "${privilegeManagerURL}" "html"
validateURLaccess "${agentRegistrationURL}" "xml"



# Test Agent Connection
echo "Test Agent Connection ..."
testAgentConnection



# Kickstart Status
echo "Kickstart Status: ${kickstartResult}"
case ${kickstartResult} in

	*"FAILED"* )
			echo "Kickstart Status: ${kickstartResult}"
			kickstartAgent
			;;

esac

case ${kickstartAgentResult} in

	"Successful" )
		kickstartResult="${kickstartResult}; Successfully kickstarted agent"
		;;

	"Failure" )
		kickstartResult="${kickstartResult}; Failed to kickstart agent"
		;;

	"Not Required" )
		kickstartResult="${kickstartResult}; Kickstart Not Requred"
		;;

esac



thycoticLastUpdated=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist last_updated )

echo "Result: ${kickstartResult}; Last Updated: ${thycoticLastUpdated} UTC"



exit 0
