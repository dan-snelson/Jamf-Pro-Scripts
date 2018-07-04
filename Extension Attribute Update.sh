#!/bin/bash
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
# Import client-side functions
# See: https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Client-side%20Functions
source /path/to/client-side/functions.sh
####################################################################################################


ScriptLog "--- Set a computer's Extension Attribute via the API ---"


### Variables
apiURL="https://your.jamf-pro.server.com:8443"		# Jamf Pro URL without trailing forward slash
apiUsername="${4}"							    							# API Username
apiPasswordEncrypted="${5}"				# API Encrypted Password
eaName="${6}"								    									# Name of Extension Attribute (i.e., "Testing Level")
eaValue="${7}"							    									# Value for Extension Attribute (i.e., "Gamma" or "None")
Salt="Salt goes here"					# Salt (generated from Encrypt Password)
Passphrase="Passphrase goes here"		    	# Passphrase (generated from Encrypt Password)
computerUDID=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }' )


# Validate a value has been specified for Parameter 4  ...
if [ ! -z "${apiUsername}" ] && [ ! -z "${apiPasswordEncrypted}" ] && [ ! -z "${eaName}" ] && [ ! -z "${eaValue}" ]; then
	# All script parameters have been specified, proceeding ...
	ScriptLog "* All script parameters have been specified, proceeding ..."
	apiPassword=$(decryptPassword ${apiPasswordEncrypted} ${Salt} ${Passphrase})
	ScriptLog "* Extension Attribute Name: ${eaName}"
	ScriptLog "* Extension Attribute New Value: ${eaValue}"

	if [ ${eaValue} == "None" ]; then
	  ScriptLog "* Extension Attribute Value is 'None'; remove value ${eaName}"
	  eaValue=""
	fi

	# Read current value ...
	apiRead=`curl -H "Accept: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID}/subset/extension_attributes | xmllint --format - | grep -A3 "<name>${eaName}</name>" | awk -F'>|<' '/value/{print $3}'`

	ScriptLog "* Extension Attribute ${eaName}'s Current Value: ${apiRead}"

	# Construct the API data ...
	apiData="<computer><extension_attributes><extension_attribute><name>${eaName}</name><value>${eaValue}</value></extension_attribute></extension_attributes></computer>"

	apiPost=`curl -H "Content-Type: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID} -d "${apiData}" -X PUT`

	/bin/echo ${apiPost}

	# Read the new value ...
	apiRead=`curl -H "Accept: text/xml" -sfu ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID}/subset/extension_attributes | xmllint --format - | grep -A3 "<name>${eaName}</name>" | awk -F'>|<' '/value/{print $3}'`

	ScriptLog "* Extension Attribute ${eaName}'s New Value: ${apiRead}"

	ScriptLog "--- Completed setting a computer's Extension Attribute via the API ---"

	jssLog "${eaName} changed to ${eaValue}"

else

	jssLog "Error: Parameters 4, 5, 6 and 7 not populated; exiting."

	exit 1

fi



exit 0
