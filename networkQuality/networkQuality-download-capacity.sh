#!/bin/sh
#################################################################################
# A script to determine the download capacity of the Mac's Internet connection. #
#################################################################################

osProductVersion=$( /usr/bin/sw_vers -productVersion )

case "${osProductVersion}" in

    10* | 11* )
        echo "<result>N/A; macOS ${osProductVersion}</result>"
        ;;

    12* )
        downloadCapacity=$( /usr/bin/networkQuality | /usr/bin/awk '/Download capacity:/{print $3, $4}' )
        echo "<result>${downloadCapacity}</result>"
        ;;

    13* )
        downlinkCapacity=$( /usr/bin/networkQuality | /usr/bin/awk '/Downlink capacity:/{print $3, $4}' )
        echo "<result>${downlinkCapacity}</result>"
        ;;

esac

exit 0