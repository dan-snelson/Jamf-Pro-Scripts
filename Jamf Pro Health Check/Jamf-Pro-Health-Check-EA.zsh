#!/bin/zsh --no-rcs
# shellcheck shell=bash
# shellcheck disable=SC2001

####################################################################################################
#
# ABOUT
#
#   A script which determines the status of Jamf Pro Health Check (https://snelson.us/jphc)
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 25-Jan-2024, Dan K. Snelson (@dan-snelson)
#       Original version
#
#   Version 0.0.2, 19-Mar-2024, Dan K. Snelson (@dan-snelson)
#       Added `--no-rcs` to the `#!/bin/zsh` shebang
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Script Version
scriptVersion="0.0.2"

# Organization's Reverse Domain Name Notation (i.e., com.company.division)
reverseDomainNameNotation="org.churchofjesuschrist"

# Script Human-readabale Name
humanReadableScriptName="Jamf Pro Health Check"

# Organization's Script Name
organizationScriptName="jphc"

# Property List File
plistFilepath="/Library/Preferences/${reverseDomainNameNotation}.${organizationScriptName}.plist"

# Property List "Key" for which the value will be set
key="${humanReadableScriptName}"



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Jamf Pro Health Check Installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f "${plistFilepath}" ]]; then

    RESULT=$( defaults read "${plistFilepath}" "${key}" 2>&1 )

else

    RESULT="Not Installed"

fi    

/bin/echo "<result>${RESULT}</result>"