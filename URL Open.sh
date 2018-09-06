#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Open the URL specified in Parameter 4
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 11-Mar-2016, Dan K. Snelson
#		Original version
#	Version 1.1, 18-Oct-2016, Dan K. Snelson
#		Added parameter to specify which browser opens a given URL
#
####################################################################################################


### Variables
url="${4}"																					# URL to open
browser="${5}"																			# Browser to open URL
loggedInUser=$(/usr/bin/stat -f%Su /dev/console)		# Currently loggged-in user


# Ensure Parameter 4 is not blank ...
if [ "${url}" == "" ]; then
	echo "Error: Parameter 4 is blank; please specify a URL to open. Exiting ..."
	exit 1
fi


if [ "${browser}" == "" ]; then
  echo "* Preferred browser not specified; using Safari ..."
	browser="Safari"
fi

case ${browser} in
	Chrome		)	browserPath="/Applications/Google\ Chrome.app/" ;;
	Firefox		)	browserPath="/Applications/Firefox.app/" ;;
	Safari		)	browserPath="/Applications/Safari.app/" ;;
	*			)			browserPath="/Applications/Safari.app/" ;;
esac

echo "#### Open URL ####"
/usr/bin/su - $loggedInUser -c "/usr/bin/open -a ${browserPath} ${url}"

echo "Opened: ${url} with ${browserPath}"


exit 0
