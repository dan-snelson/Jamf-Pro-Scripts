#!/bin/sh
#######################################################################################
# A script to determine the download responsiveness of the Mac's Internet connection. #
#######################################################################################

osProductVersion=$( /usr/bin/sw_vers -productVersion )

case "${osProductVersion}" in

    10* | 11* )
        echo "<result>N/A; macOS ${osProductVersion}</result>"
        ;;

    12* )
        downloadResponsiveness=$( /usr/bin/networkQuality -s -v | /usr/bin/awk '/Download Responsiveness:/{print $3, $4, $5}' )
        echo "<result>${downloadResponsiveness}</result>"
        ;;

    13* )
        downlinkResponsiveness=$( /usr/bin/networkQuality -s -v | /usr/bin/awk '/Downlink Responsiveness:/{print $3, $4, $5}' )
        echo "<result>${downlinkResponsiveness}</result>"
        ;;

esac

exit 0