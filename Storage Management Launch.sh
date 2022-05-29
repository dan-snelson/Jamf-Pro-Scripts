#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Launch Storage Management.app
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0.0, 24-May-2018, Dan K. Snelson
#       Original version
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="1.0.0"
scriptResult="Version ${scriptVersion}; "
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Launch Storage Management.app (${scriptVersion})"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Launch Storage Management.app as the currently logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

/usr/bin/su \- "${loggedInUser}" -c "/usr/bin/open '/System/Library/CoreServices/Applications/Storage Management.app'"

scriptResult+="Launched Storage Management.app as ${loggedInUser}; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="End-of-line"
echo ${scriptResult}

exit 0        ## Success
exit 1        ## Failure