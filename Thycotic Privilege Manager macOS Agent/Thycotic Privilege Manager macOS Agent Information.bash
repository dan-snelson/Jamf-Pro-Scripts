#!/bin/bash
####################################################################################################
#
# Thycotic Privilege Manager macOS Agent Agent Information for your Help Desk
#
# Queries the macOS Thycotic Management Agent for various settings, saves the results to the user's
# Desktop as an HTML file, which is then opened in Safari.
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 05-May-2020, Dan K. Snelson
#		Original Version
#
####################################################################################################



###
# Exit with error if Thycotic Privilege Manager macOS Agent Agent is NOT installed
###

if [[ ! -d "/usr/local/thycotic" ]] ; then
	/bin/echo "Thycotic Privilege Manager macOS Agent Agent NOT installed; exiting."
	exit 1
fi



###
# Variables
###

privilegeManagerURL="https://companyname.privilegemanagercloud.com/Tms/PrivilegeManager/#"
jamfProURL=$( /usr/bin/defaults read "/Library/Preferences/com.jamfsoftware.jamf.plist" jss_url | /usr/bin/sed 's|/$||'  )
if [[ ${jamfProURL} == *"stage"* ]]; then
	jamfProAdminURL="https://jamfpro-stage.companyname.com"
else
	jamfProAdminURL="https://jamfpro.companyname.com"
fi

############################## No edits needed below this line ##############################

loggedInUser=$( /usr/bin/stat -f %Su "/dev/console" )
loggedInUserHome=$( /usr/bin/dscl . -read /Users/$loggedInUser NFSHomeDirectory | /usr/bin/awk '{print $NF}' ) # mm2270
timeStamp=$( /bin/date '+%Y-%m-%d-%H%M%S' )
outputFileName="$loggedInUserHome/Desktop/$loggedInUser-ThycoticManagementAgentInformation-${timeStamp}.html"
privilegemanagerguiVersion=$( /usr/bin/defaults read /Applications/Privilege\ Manager.app/Contents/Info.plist CFBundleVersion )
thycoticMachineID=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist machine_id )
serialNumber=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep "Serial Number" | /usr/bin/awk -F ": " '{ print $2 }' )



###
# Define Functions
###

agentUtil() {
	agentUtilAction=$( /usr/local/thycotic/agent/agentUtil.sh ${1} )
}



###
# Program
###

/bin/echo " "
/bin/echo "###"
/bin/echo "# Thycotic Privilege Manager macOS Agent Agent Information"
/bin/echo "###"
/bin/echo " "







###
# Create HTML document
###

/bin/echo "Create HTML document …"

/bin/echo "<!DOCTYPE html>
<html>
<head>
	<title>Thycotic Privilege Manager macOS Agent Agent Information for $loggedInUser, S/N $serialNumber, Machine ID $thycoticMachineID</title>
  <base target="_blank">
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
</style>
</head>
<body>


<h1>Thycotic Privilege Manager macOS Agent Agent</h1>
<hr />
<h2>Computer Information</h2>
<ul>" > ${outputFileName}



###
# Computer Information
###

/bin/echo "Computer Information …"

/bin/echo "<li><strong>Execution Date:</strong> `date '+%Y-%m-%d-%H%M%S'`</li>" >> ${outputFileName}
/bin/echo "<li><strong>Username:</strong> ${loggedInUser}</li>" >> ${outputFileName}
/bin/echo "<li><strong>Serial Number:</strong> <a href=\"${jamfProAdminURL}/computers.html?queryType=Computers&query="${serialNumber}"\">"${serialNumber}"</a></li>" >> ${outputFileName}
/bin/echo "<li><strong>Privilege Manager:</strong> ${privilegemanagerguiVersion}</li>" >> ${outputFileName}
/bin/echo "<li><strong>Machine GUID:</strong> <a href=\"$privilegeManagerURL/search/"${thycoticMachineID}"\">"${thycoticMachineID}"</a></li>" >> ${outputFileName}
/bin/echo "</ul>" >> ${outputFileName}
/bin/echo "<hr />" >> ${outputFileName}



###
# Agent Commands
###

/bin/echo "Agent Commands …"

/bin/echo "<h2>Agent Commands</h2>" >> ${outputFileName}
/bin/echo "<ul>" >> ${outputFileName}
agentUtil "register"
/bin/echo "<li><strong>Register:</strong> ${agentUtilAction}</li>" >> ${outputFileName}
agentUtil "updateclientitems"
/bin/echo "<li><strong>Update Client Items:</strong> ${agentUtilAction}</li>" >> ${outputFileName}
thycoticLastUpdated=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist last_updated )
/bin/echo "<li><strong>Last Updated:</strong> ${thycoticLastUpdated} UTC</li>" >> ${outputFileName}
/bin/echo "</ul>" >> ${outputFileName}
/bin/echo "<hr />" >> ${outputFileName}



###
# Enabled Policies
###

/bin/echo "Enabled Policies …"

agentUtil "clientitemsummary"

/bin/echo "<h2>Enabled Policies</h2>" >> ${outputFileName}
/bin/echo "<ol>" >> ${outputFileName}
enabledPolicies=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist enabled_policies | /usr/bin/tr -d '(")[:space:]' )
IFS=',' read -r -a enabledPoliciesArray <<< "${enabledPolicies}"
for policy in "${enabledPoliciesArray[@]}"
do
	hyperlinkText=$( /bin/echo "${agentUtilAction}" | /usr/bin/grep "${policy}" | /usr/bin/sed "s/${policy}//g" )
	/bin/echo "<li><a href=\"$privilegeManagerURL/search/"${policy}"\">"${hyperlinkText}"</a></li>" >> ${outputFileName}
done
unset IFS
/bin/echo "</ol>" >> ${outputFileName}
/bin/echo "<hr />" >> ${outputFileName}



###
# Client Item Summary
###

/bin/echo "Client Item Summary …"

/bin/echo "<h2>Client Item Summary</h2>" >> ${outputFileName}
/bin/echo "<ul>" >> ${outputFileName}
IFS=$'\n'
for row in $( /bin/echo "$agentUtilAction" | /usr/bin/head -5 )
do
 	/bin/echo "<li>"$row"</li>" >> ${outputFileName}
done
/bin/echo "</ul>" >> ${outputFileName}
/bin/echo "<ol>" >> ${outputFileName}
for row in $( /bin/echo "$agentUtilAction" | /usr/bin/tail +7)
do
	guid=$( /bin/echo "${row}" | /usr/bin/awk '{ print $3 }' )
 	hyperlinkText=$( /bin/echo "${row}" | /usr/bin/awk '{$3=""; print $0}' )
 	/bin/echo "<li><a href=\"$privilegeManagerURL/search/"${guid}"\">"${hyperlinkText}"</a></li>" >> ${outputFileName}
done
unset IFS
/bin/echo "</ol>" >> ${outputFileName}
/bin/echo "<hr />" >> ${outputFileName}



###
# Close HTML document
###

/bin/echo "Close HTML document …"

/bin/echo "</body>
</html>" >> ${outputFileName}



###
# Open HTML document in Safari
###

if [[ -f ${outputFileName} ]]; then
	/bin/echo "Open HTML document in Safari …"
	/usr/bin/su - ${loggedInUser} -c "open -a safari ${outputFileName}"
fi

/bin/echo "Results saved to: ${outputFileName}"

exit 0		## Success
