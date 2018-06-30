#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Standard functions which are imported into other scripts
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 30-Nov-2016, Dan K. Snelson
#		Original version
#	Version 1.1, 17-Mar-2017, Dan K. Snelson
#		Misc. updates
#	Version 1.2, 26-Apr-2017, Dan K. Snelson
#		Added Extension Attribute Execution Frequency & Results
#	Version 1.2.1, 10-May-2017, Dan K. Snelson
#		Tweaked jssLog function
#
####################################################################################################
#
#	USE
#
#	Search for "companyname" and replace with the name of your organization; install on each client
#
####################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# LOGGING
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



## Variables
logFile="/var/log/com.companyname.log"
alias now="/bin/date '+%Y-%m-%d %H:%M:%S'"


## Check for / create logFile
if [ ! -f "${logFile}" ]; then
	# logFile not found; Create logFile ...
	/usr/bin/touch "${logFile}"
	/bin/echo "`/bin/date +%Y-%m-%d\ %H:%M:%S`  *** Created log file via function ***" >>"${logFile}"
fi

## I/O Redirection to client-side log file
exec 3>&1 4>&2					# Save standard output (stdout) and standard error (stderr) to new file descriptors
exec 1>>"${logFile}"		# Redirect standard output, stdout, to logFile
exec 2>>"${logFile}"		# Redirect standard error, stderr, to logFile

function ScriptLog() { # Write to client-side log file ...
  /bin/echo "`/bin/date +%Y-%m-%d\ %H:%M:%S`  ${1}"
}

function jssLog() { # Write to Jamf Pro server ...
	ScriptLog "${1}"			# Write to the client-side log ...

	## I/O Redirection to Jamf Pro server
	exec 1>&3 2>&4				# Restore standard output (stdout) and standard error (stderr)
	/bin/echo "${1}"			# Record output in the JSS
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Pashua
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function pashua_run() {

  # Write config file
  local pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
  /bin/echo "$1" > "$pashua_configfile"

	pashuapath='/usr/local/companyname/Pashua.app/Contents/MacOS/Pashua'

  # Get result
  local result=$("$pashuapath" "$pashua_configfile")

  # Remove config file
  /bin/rm "$pashua_configfile"

  oldIFS="$IFS"
  IFS=$'\n'

  # Parse result
  for line in $result; do
    local name=$(/bin/echo $line | /usr/bin/sed 's/^\([^=]*\)=.*$/\1/')
    local value=$(/bin/echo $line | /usr/bin/sed 's/^[^=]*=\(.*\)$/\1/')
    eval $name='$value'
  done

  IFS="$oldIFS"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# JAMF Display Message
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfDisplayMessage() {
	ScriptLog "${1}"
	/usr/local/jamf/bin/jamf displayMessage -message "${1}" &
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Decrypt Password
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function decryptPassword() {
	/bin/echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Reveal File in Finder
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function revealMe() {
	/usr/bin/su \- "$( /bin/ls -l /dev/console | /usr/bin/cut -d " " -f4 )" -c "/usr/bin/open -R ${1}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Extension Attribute Execution Frequency
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function eaFrequency() {

	# Validate parameters
  if [ -z "$1" ] || [ -z "$2" ] ; then
    ScriptLog "Error calling \"eaFrequency\" function: One or more parameters are blank; exiting."
  	exit 1
  fi

	# Variables
	organizationalPlist="/usr/local/companyname/com.companyname.plist"
	plistKey="$1"															# Supplied plistKey
	frequency="$2"														# Supplied frequency in days
	frequencyInSeconds=$((frequency * 86400))	# There are 86,400 seconds in 1 day

	# Check for / create plist ...
	if [ ! -f "${organizationalPlist}" ]; then
		ScriptLog "The plist, \"${organizationalPlist}\", does NOT exist; create it ..."
		/usr/bin/touch "${organizationalPlist}"
		/usr/sbin/chown root:wheel "${organizationalPlist}"
		/bin/chmod 0600 "${organizationalPlist}"
	fi

	# Query for the given plistKey; suppress any error message, if key not found.
	plistKeyTest=$( /usr/libexec/PlistBuddy -c 'print "'"${plistKey} Epoch"'"' ${organizationalPlist} 2>/dev/null )

	# Capture the exit code, which indicates success v. failure
	exitCode=$?
	if [ "${exitCode}" != 0 ]; then
		ScriptLog "The key, \"${plistKey} Epoch\", does NOT exist; create it with a value of zero ..."
		/usr/bin/defaults write "${organizationalPlist}" "${plistKey} Epoch" "0"
	fi

	# Read the last execution time ...
	lastExecutionTime=$( /usr/bin/defaults read "${organizationalPlist}" "${plistKey} Epoch" )

	# Calculate the elapsed time since last execution ...
	elapsedTimeSinceLastExecution=$(( $(date +%s) - ${lastExecutionTime} ))

	# If the elapsed time is less than the frequency, read the previous result ...
	if [ "${elapsedTimeSinceLastExecution}" -lt "${frequencyInSeconds}" ]; then
		ScriptLog "Elapsed time since last execution for \"$plistKey\", $elapsedTimeSinceLastExecution, is less than $frequencyInSeconds; read previous result."
		eaExecution="No"
		eaResult "${plistKey}" # Obtain the current result
	else
		# If the elapsed time is less than the frequency, read the previous result ...
		ScriptLog "Elapsed time since last execution for \"$plistKey\", $elapsedTimeSinceLastExecution, is greater than $frequencyInSeconds; execute the Extension Attribute."
		/usr/bin/defaults write "${organizationalPlist}" "${plistKey} Epoch" "`/bin/date +%s`"
		eaExecution="Yes"
	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Extension Attribute Result
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function eaResult() {

	# Validate parameters
  if [ -z "$1" ] ; then
		ScriptLog "Error calling \"eaResult\" function: Parameter 1 is blank; exiting."
		exit 1
  fi

	# Variables
	organizationalPlist="/usr/local/companyname/com.companyname.plist"
	plistKey="$1"
	result="$2"

  if [ -z "$2" ] ; then
		# If the function is called with a single parameter, then just read the previously recorded result
		returnedResult=$( /usr/bin/defaults read "${organizationalPlist}" "${plistKey} Result" )
	else
		# If the function is called with two parameters, then write / read the new result
		/usr/bin/defaults write "${organizationalPlist}" "${plistKey} Result" "\"${result}"\"
		returnedResult=$( /usr/bin/defaults read "${organizationalPlist}" "${plistKey} Result" )
	fi

}
