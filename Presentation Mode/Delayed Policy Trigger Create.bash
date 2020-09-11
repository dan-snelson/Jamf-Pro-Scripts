#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Execute a Jamf Pro policy via a custom trigger after a specified duration
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0.0, 24-Aug-2015, Dan K. Snelson
#		Original version
#		Inspired by Kyle Brockman (brockma9)
#		https://jamfnation.jamfsoftware.com/discussion.html?id=6990
#	Version 1.1.0, 02-Nov-2017, Dan K. Snelson
#		Updated log writing
#	Version 1.1.1, 17-Aug-2019, Dan K. Snelson
#		Updates for macOS Catalina
#
####################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Variables
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

plistDomain="com.company"				# Hard-coded domain name (i.e., "com.company")
plistLabel="$4"						# Unique Daemon Label (i.e., "presentationMode2")
plistFilename="$plistDomain.$plistLabel.plist"		# Prepend domain to label; append ".plist" to label
plistTrigger="$5"					# Name of Jamf Pro policy trigger
plistStartInterval="$6"					# Interval (in minutes)
plistStartInterval=$(( plistStartInterval * 60 ))	# Convert interval to seconds



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Program
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Execute a Jamf Pro policy via a custom trigger after a specified duration"
echo "• Filename: ${plistFilename}"
echo "• Start Interval: ${plistStartInterval}"



# Create launchd plist to call Jamf Pro policy

echo "• Create launchd plist to call Jamf Pro policy ..."
/bin/echo "<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict>
	<key>Disabled</key>
	<true/>
	<key>EnableTransactions</key>
	<true/>
	<key>Label</key> 
	<string>${plistDomain}.${plistLabel}</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/usr/local/jamf/bin/jamf</string>
		<string>policy</string>
		<string>-event</string>
		<string>${plistTrigger}</string>
		<string>-verbose</string>
	</array>
	<key>StartInterval</key>
	<integer>${plistStartInterval}</integer> 
</dict> 
</plist>" > /Library/LaunchDaemons/${plistFilename}



# Pause for 10 seconnds
echo "• Pause for 10 seconds ..."
/bin/sleep 10



# Set the permission on the file
echo "• Set permissions on launchd plist ..."
/usr/sbin/chown root:wheel /Library/LaunchDaemons/${plistFilename}
/bin/chmod 755 /Library/LaunchDaemons/${plistFilename}



# Pause for 10 seconnds
echo "• Pause for 10 seconds ..."
/bin/sleep 10



# Load the plist
echo "• Unload / Load the launchd plist ..."
/bin/launchctl unload -wF /Library/LaunchDaemons/${plistFilename}
/usr/bin/defaults write /Library/LaunchDaemons/${plistFilename} Disabled -bool false
/bin/launchctl load -wF /Library/LaunchDaemons/${plistFilename}



# Send result back to the Jamf Pro server
echo "• Loaded ${plistFilename}"

exit 0
