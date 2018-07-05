#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Enterprise Connect Post-install
#
#   Leveraging a new feature of Enterprise Connect 1.9 (9), "prepopulatedUsername", started out as
#   entering a string of code in a policy's Files and Processes > Execute Command field.
#
#   As the string of code became longer and more complex, it warranted its own script.
#
#   Set Parameter 4 to "yes" to launch Enterprise Connect after its configured.
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0, 16-Apr-2018, Dan K. Snelson
#       Original
#   Version 1.1, 05-Jul-2018, Dan K. Snelson
#       Write to the preference domain; thanks, gda
#       See: https://www.jamf.com/jamf-nation/discussions/27835/enterprise-connect-1-9-9-prepopulatedusername#responseChild164568
#
####################################################################################################

echo " "
echo "###"
echo "# Enterprise Connect Post-install"
echo "###"
echo " "



###
# Variables
###

loggedInUser=$( /usr/bin/stat -f %Su "/dev/console" )   # Get the logged in users username

# Check for a specified "launchApp" setting (Parameter 4); defaults to "no"
if [[ "${4}" != "" ]] && [[ "${launchApp}" == "" ]]; then

  launchApp="${4}"
  echo "• Using ${launchApp} as \"launchApp\" value ..."

else

  launchApp="no"
  echo "• Parameter 4 is blank; using ${launchApp} as \"launchApp\" value ..."

fi



###
# Commands
###

# Set "prepopulatedUsername" to the current logged-in user name
echo "• Set \"prepopulatedUsername\" to \"${loggedInUser}\" ..."
/usr/bin/sudo -u "${loggedInUser}" /usr/bin/defaults write com.apple.Enterprise-Connect prepopulatedUsername -string ${loggedInUser}

# Create a link to the eccl script so it can be called like a regular CLI utility
echo "• Create a link to the \"eccl\" script so it can be called like a regular CLI utility ..."
/bin/ln -s /Applications/Enterprise\ Connect.app/Contents/SharedSupport/eccl /usr/local/bin/eccl

if [[ ${launchApp} == "yes" ]]; then
  echo "• Open Enterprise Connect ..."
  /usr/bin/su \- "${loggedInUser}" -c "/usr/bin/open '/Applications/Enterprise Connect.app'"
fi

echo "Enterprise Connect Post-install script results:"
echo "• prepopulatedUsername: `/usr/bin/defaults read /Users/${loggedInUser}/Library/Preferences/com.apple.Enterprise-Connect.plist prepopulatedUsername`"
echo "• Launch Enterprise Connect?: ${launchApp}"



exit 0
