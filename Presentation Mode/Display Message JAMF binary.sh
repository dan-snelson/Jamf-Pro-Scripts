#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	For simple end-user messages 
# 	See: https://jamfnation.jamfsoftware.com/article.html?id=107
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 5-Nov-2014, Dan K. Snelson
#
####################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# JAMF Display Message
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfDisplayMessage() {
	echo "${1}"
	/usr/local/jamf/bin/jamf displayMessage -message "${1}" &
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Variables
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

message="${4}"			# Text of end-user message

if [ "${message}" == "" ]; then
	echo "Error: Parameter 4 is blank; please specify a message to be displayed."
	exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Program
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamfDisplayMessage "${message}"



exit 0