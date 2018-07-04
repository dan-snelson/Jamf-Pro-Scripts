#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Creates a Launch Daemon to run a Recon at next Reboot
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 10-Nov-2016, Dan K. Snelson
#
####################################################################################################
# Import client-side functions
# See: https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Client-side%20Functions
source /path/to/client-side/functions.sh
####################################################################################################

# Variables
plistDomain="com.company.division"										# Hard-coded domain name (i.e., "com.company.division")
plistLabel="reconAtReboot"														# Unique label for this plist (i.e., "reconAtReboot")
plistLabel="$plistDomain.$plistLabel"									# Prepend domain to label
scriptPath="/usr/local/companyname/reconAtReboot.sh"

ScriptLog "##############################"
ScriptLog "### Recon at Reboot Create ###"
ScriptLog "##############################"


# Create launchd plist to call a shell script
ScriptLog "* Create the LaunchDaemon ..."

/bin/echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
	<dict>
		<key>Label</key>
		<string>${plistLabel}</string>
		<key>ProgramArguments</key>
		<array>
			<string>sh</string>
			<string>${scriptPath}</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>" > /Library/LaunchDaemons/${plistLabel}.plist



# Set the permission on the file
ScriptLog "* Set LaunchDaemon file permissions ..."

/usr/sbin/chown root:wheel /Library/LaunchDaemons/${plistLabel}.plist
/bin/chmod 644 /Library/LaunchDaemons/${plistLabel}.plist
/bin/chmod +x /Library/LaunchDaemons/${plistLabel}.plist



# Create reboot script
ScriptLog "* Create the script ..."
/bin/echo "#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Recon at Reboot
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 10-Nov-2016, Dan K. Snelson
#	Version 1.1, 08-Nov-2017, Dan K. Snelson
#		Quit Self Service
#
####################################################################################################
# Import client-side functions
# See: https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Client-side%20Functions
source /path/to/client-side/functions.sh
####################################################################################################


ScriptLog \"### Recon at Reboot ###\"

ScriptLog \" \" # Blank line for readability

# Sleeping for 25 seconds for auto-launched applications to start
ScriptLog \"* Pausing Recon at Reboot for 25 seconds for auto-launched applications to start ...\"
/bin/sleep 25

# Quit Self Service
ScriptLog \"Quit Self Service\" # Self Service may have been running when the computer was restarted
/usr/bin/pkill -l -U \"`/usr/bin/stat -f%Su /dev/console`\" \"Self Service\"

# Sleeping for 10 minutes (600 seconds) to give Wi-Fi time to come online.
ScriptLog \"* Pausing Recon at Reboot for 10 minutes to allow Wi-Fi and DNS to come online ...\"
/bin/sleep 600
ScriptLog \"* Resuming Recon at Reboot ...\"

ScriptLog \"* Updating inventory ...\"
/usr/local/bin/jamf recon

# Delete launchd plist
ScriptLog \"* Delete $plistLabel.plist ...\"
/bin/rm -fv /Library/LaunchDaemons/$plistLabel.plist

# Delete script
ScriptLog \"* Delete script ...\"
/bin/rm -fv ${scriptPath}

exit 0" > ${scriptPath}

# Set the permission on the file
ScriptLog "* Set script file permissions ..."
/usr/sbin/chown root:wheel ${scriptPath}
/bin/chmod 644 ${scriptPath}
/bin/chmod +x ${scriptPath}

jssLog "* LaunchDaemon and Script created."

exit 0
