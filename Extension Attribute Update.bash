#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Set a computer's Extension Attribute via the API
#	https://github.com/dan-snelson/Jamf-Pro-Scripts/blob/master/Extension%20Attribute%20Update.sh
#
#	See also: https://github.com/jamf/Encrypted-Script-Parameters
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 30-Jul-2016, Dan K. Snelson
#		Original
#	Version 1.1, 17-Oct-2016, Dan K. Snelson
#		Updated to leverage an encyrpted API password
#	Version 1.1.1, 30-Sep-2019, Dan K. Snelson
#		Improved readablity; self-contained functions, removing dependency for client-side functions
#
####################################################################################################



### Variables

apiURL="https://your.jamf-pro.server.com:8443"	# Jamf Pro URL without trailing forward slash
apiUsername="${4}"				# API Username
apiPasswordEncrypted="${5}"			# API Encrypted Password
eaName="${6}"					# Name of Extension Attribute (i.e., "Testing Level")
eaValue="${7}"					# Value for Extension Attribute (i.e., "Gamma" or "None")
Salt="Salt goes here"				# Salt, generated from Encrypt Password
Passphrase="Passphrase goes here"		# Passphrase, generated from Encrypt Password
computerUUID=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }' )

################################### No edits needed below this line ###################################

### Functions

# Decrypt Password

function decryptPassword() {
	/bin/echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}



### Command

/bin/echo "--- Set a computer's Extension Attribute via the API ---"

# Validate a value has been specified for Parameters 4, 5, 6 & 7  ...
if [[ ! -z "${apiUsername}" ]] && [[ ! -z "${apiPasswordEncrypted}" ]] && [[ ! -z "${eaName}" ]] && [[ ! -z "${eaValue}" ]]; then
	# All script parameters have been specified, proceeding ...
	/bin/echo "* All script parameters have been specified, proceeding ..."
	apiPassword=$( decryptPassword ${apiPasswordEncrypted} ${Salt} ${Passphrase} )
	/bin/echo "* Extension Attribute Name: ${eaName}"
	/bin/echo "* Extension Attribute New Value: ${eaValue}"

	if [[ ${eaValue} == "None" ]]; then
	  /bin/echo "* Extension Attribute Value is 'None'; remove value ${eaName}"
	  eaValue=""
	fi

	# Read current value ...
	apiRead=$( /usr/bin/curl -H "Accept: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUUID}/subset/extension_attributes | /usr/bin/xmllint --format - | /usr/bin/grep -A3 "<name>${eaName}</name>" | /usr/bin/awk -F'>|<' '/value/{getline;print $3}' )

	/bin/echo "* Extension Attribute ${eaName}'s Current Value: ${apiRead}"

	# Construct the API data ...
	apiData="<computer><extension_attributes><extension_attribute><name>${eaName}</name><value>${eaValue}</value></extension_attribute></extension_attributes></computer>"

	apiPost=$( /usr/bin/curl -H "Content-Type: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUUID} -d "${apiData}" -X PUT )

	/bin/echo ${apiPost}

	# Read the new value ...
	apiRead=$( /usr/bin/curl -H "Accept: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUUID}/subset/extension_attributes | /usr/bin/xmllint --format - | /usr/bin/grep -A3 "<name>${eaName}</name>" | /usr/bin/awk -F'>|<' '/value/{getline;print $3}' )

	/bin/echo "* Extension Attribute ${eaName}'s New Value: ${apiRead}"

	/bin/echo "--- Completed setting a computer's Extension Attribute via the API ---"

	/bin/echo "${eaName} changed to ${eaValue}"

else

	/bin/echo "Error: Parameters 4, 5, 6 and 7 not populated; exiting."

	exit 1

fi



exit 0
