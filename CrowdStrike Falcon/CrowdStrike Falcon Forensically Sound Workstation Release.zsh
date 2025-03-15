#!/bin/zsh

# macOS Forensically Sound Workstation Release (1.0.0)
# (Estimated Duration: 0h:0m:03s)

echo -e "\n\n\n###\n# macOS Forensically Sound Workstation Release (1.0.0)\n# (Estimated Duration: 0h:0m:03s)\n###"

# Initialize SECONDS
SECONDS="0"

####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        echo "Attempting to terminate the '$process' process …"
        echo "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            echo "ERROR: '$process' could not be terminated."
        fi
    else
        echo "The '$process' process isn't running."
    fi
}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Release the Forensically Sound Workstation Lockout
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Unload / Delete LaunchDaemon"
/bin/launchctl bootout system /Library/LaunchDaemons/org.churchofjesuschrist.fswl.plist
rm -fv /Library/LaunchDaemons/org.churchofjesuschrist.fswl.plist

echo "Remove Client-side Script"
rm -fv /usr/local/org.churchofjesuschrist/scripts/fswl.bash

echo "Kill Processes"
killall -v LockScreen
killall -v jamfHelper
killProcess "caffeinate"

echo -e "\nExecution Duration: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"