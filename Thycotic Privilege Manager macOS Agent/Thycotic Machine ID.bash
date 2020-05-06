#!/bin/bash

####################################################################################################
# Extension Attribute to determine the Thycotic Machine ID
####################################################################################################

# Set Result to "Not Installed"
result="Not Installed"

# If the thycotic binary is installed, return the version
if [[ -d "/usr/local/thycotic" ]] ; then

	result=$( /usr/bin/defaults read /Library/Application\ Support/Thycotic/Agent/acs-config.plist machine_id )

fi

echo "<result>${result}</result>"

exit 0
