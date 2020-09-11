#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Set a computer's Extension Attribute via the API
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 30-Jul-2016, Dan K. Snelson
#		Original
#	Version 1.1, 17-Oct-2016, Dan K. Snelson
#		Updated to leverage an encyrpted API password
#
####################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Functions
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

decryptPassword() {
	/bin/echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Variables
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

apiURL="https://jamfpro.company.com/" 		# JSS API URL with trailing forward slash
apiUsername="${4}"				# API Username
apiPasswordEncrypted="${5}"			# API Encrypted Password
eaName="${6}"					# Name of Extension Attribute (i.e., "Testing Level")
eaValue="${7}"					# Value for Extension Attribute (i.e., "Gamma" or "None")
Salt="1234567890"				# Salt (generated from Encrypt Password)
Passphrase="abcdefghijklmnopqrstuvwxyz"		# Passphrase (generated from Encrypt Password)
computerUDID=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Program
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Set a computer's Extension Attribute via the API"

echo "• Validate a value has been specified for all parameters ..."

if [ ! -z "${apiUsername}" ] && [ ! -z "${apiPasswordEncrypted}" ] && [ ! -z "${eaName}" ] && [ ! -z "${eaValue}" ]; then
	# All script parameters have been specified, proceeding ...
	echo "• All script parameters have been specified, proceeding ..."
	apiPassword=$(decryptPassword ${apiPasswordEncrypted} ${Salt} ${Passphrase})
	echo "• Extension Attribute Name: ${eaName}"
	echo "• Extension Attribute New Value: ${eaValue}"

	if [ ${eaValue} = "None" ]; then
		echo "• Extension Attribute Value is 'None'; remove value ${eaName}"
		eaValue=""
	fi

	# Read current value ...
	apiRead=`curl -H "Accept: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID}/subset/extension_attributes | xmllint --format - | grep -A3 "<name>${eaName}</name>" | awk -F'>|<' '/value/{print $3}'`

	echo "• Extension Attribute ${eaName}'s Current Value: ${apiRead}"

	# Construct the API data ...
	apiData="<computer><extension_attributes><extension_attribute><name>${eaName}</name><value>${eaValue}</value></extension_attribute></extension_attributes></computer>"

	apiPost=`curl -H "Content-Type: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID} -d "${apiData}" -X PUT`

	/bin/echo ${apiPost}

	# Read the new value ...
	apiRead=`curl -H "Accept: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID}/subset/extension_attributes | xmllint --format - | grep -A3 "<name>${eaName}</name>" | awk -F'>|<' '/value/{print $3}'`

	echo "• Extension Attribute ${eaName}'s New Value: ${apiRead}"

else

	echo "Error: Parameters 4, 5, 6 and 7 not populated; exiting."
	exit 1

fi



exit 0
