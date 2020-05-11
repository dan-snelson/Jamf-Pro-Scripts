#!/bin/sh

####################################################################################################
# Extension Attribute to determine the health of the Thycotic agent
#
#	Version 1.0.0, 11-May-2020, Dan K. Snelson
#		Original Version
#
####################################################################################################

####################################################################################################
#
# Define the Variables
#
####################################################################################################

thycoticURL="https://company.privilegemanagercloud.com/Tms/" # Include trailing forward slash

############################## No edits needed below this line ##############################

privilegeManagerURL="${thycoticURL}PrivilegeManager/#"
agentRegistrationURL="${thycoticURL}Agent/AgentRegistration4.svc"



# If the "/usr/local/thycotic" directory is NOT installed, report as such and exit gracefully

if [ ! -d "/usr/local/thycotic" ] ; then

	result="Not Installed"
	echo "<result>${result}</result>"
	exit 0

else

	# The "/usr/local/thycotic" directory is installed, perform health checks ...

	result="Installed"

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

		unset testURL

		case ${2} in
			"xml"				)	testURL=$( /usr/bin/curl -sIX GET "${1}" | /usr/bin/head -n 1 ) ;;
			"html" | *	)	testURL=$( /usr/bin/curl -Is "${1}" | /usr/bin/head -n 1 ) ;;
		esac

		case ${testURL} in
			*"200"*	)	result="${result}; Passed URL" ;; # *"200"*	)	result="${result}; Passed URL ${1}" ;;
			*				)	result="${result}; FAILED URL" ;; # *				)	result="${result}; FAILED URL ${1}" ;;
		esac

	}

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Test Agent Connection
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

	testAgentConnection() {

		agentUtil "updateclientitems"

		case ${agentUtilAction} in
			*"Updating client items"*	) result="${result}; Passed Updating Client Items" ;;
			*"Unable to connect"*			) result="${result}; FAILED Updating Client Items" ;;
		esac

	}



	####################################################################################################
	#
	# Program
	#
	####################################################################################################

	validateURLaccess "${privilegeManagerURL}" "html"
	validateURLaccess "${agentRegistrationURL}" "xml"
	testAgentConnection

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Report Results
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

	echo "<result>${result}</result>"

	exit 0

fi
