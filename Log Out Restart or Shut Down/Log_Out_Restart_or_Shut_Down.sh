#!/bin/bash
####################################################################################################
#
# ABOUT
#
#   Log Out, Restart or Shut Down, based on Parameter 4
#   https://snelson.us/2022/07/log-out-restart-shut-down
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0, 08-Nov-2017, Dan K. Snelson (@dan-snelson)
#   Original version
# Version 1.0.1, 02-Jul-2022, Dan K. Snelson (@dan-snelson)
#   Updates for public GitHub release
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="1.0.1"
scriptResult="Version ${scriptVersion}; "
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )

# If Parameter 4 is blank, use "Log Out Confirm" as the default value
if [[ "${4}" != "" ]] && [[ "${option}" == "" ]]; then

    option="${4}" # Option (i.e., "Log Out Confirm" | "Log Out" | "Restart Confirm" | "Restart" | "Shut Down Confirm" | "Shut Down")
    scriptResult+="Using \"${option}\" as the option; "

else

    scriptResult+="Parameter 4 is blank; using \"Log out Confirm\" as the default option; "
    option="Log Out Confirm"

fi



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Close Self Service Policy Description (i.e., simulate the Escape key) Thanks, Kyle Flater!
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function closeSelfServicePolicyDescription() {

    /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell application \"Self Service\" to activate' -e 'tell application \"System Events\" to key code 53' "

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Close Self Service Policy Description, which can interupt restart
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

closeSelfServicePolicyDescription



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logout, Restart or Shutdown
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${option} in
    
            "Shut Down" )    
                # Shut down without showing a confirmation dialog:
                scriptResult+="Shut down without showing a confirmation dialog; "
                /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"System Events\" to shut down'"
                # /sbin/shutdown -h +1 &
                ;;

            "Shut Down Confirm" )
                # Shut down after showing a confirmation dialog:
                scriptResult+="Shut down after showing a confirmation dialog; "
                /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'"
                ;;

            "Restart" )
                # Restart without showing a confirmation dialog:
                scriptResult+="Restart without showing a confirmation dialog; "
                /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"System Events\" to restart'"
                # /sbin/shutdown -r +1 &
                ;;

            "Restart Confirm" )
                # Restart after showing a confirmation dialog:
                scriptResult+="Restart after showing a confirmation dialog; "
                /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'"
                ;;

            "Log Out" )
                # Log out without showing a confirmation dialog:
                scriptResult+="Log out without showing a confirmation dialog; "
                /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"loginwindow\" to «event aevtrlgo»'"
                # /bin/launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Confirm" )
                #Log out after showing a confirmation dialog:
                scriptResult+="Log out after showing a confirmation dialog; "
                /usr/bin/su - "${loggedInUser}" -c "/usr/bin/osascript -e 'tell app \"System Events\" to log out'"
                ;;

            * )
                # None of the expected options was entered; exit with an error
                scriptResult+="ERROR: Parameter 4 set to \"${option}\" instead of one of the following: \"Log Out Confirm\", \"Log Out\", \"Restart Confirm\", \"Restart\", \"Shut Down Confirm\", or \"Shut Down\"; exiting."
                exit 1
                
esac

scriptResult+="Used \"${option}\" as the option; Goodbye!"

echo "${scriptResult}"

exit 0