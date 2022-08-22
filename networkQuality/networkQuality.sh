#!/bin/sh
###############################################################################
# A script to determine the network quality of the Mac's Internet connection. #
###############################################################################

osProductVersion=$( /usr/bin/sw_vers -productVersion )

case "${osProductVersion}" in

    10* | 11* )
        echo "<result>N/A; macOS ${osProductVersion}</result>"
        ;;

    12* )
        networkQualityTest=$( /usr/bin/networkQuality -s -v )
        downloadCapacity=$( echo "${networkQualityTest}" | /usr/bin/awk '/Download capacity:/{print $3, $4}' )
        downloadResponsiveness=$( echo "${networkQualityTest}" | /usr/bin/awk '/Download Responsiveness:/{print $3, $4, $5}' )
        echo "<result>${downloadCapacity} | ${downloadResponsiveness}</result>"
        ;;

    13* )
        networkQualityTest=$( /usr/bin/networkQuality -s -v )
        downlinkCapacity=$( echo "${networkQualityTest}" | /usr/bin/awk '/Downlink capacity:/{print $3, $4}' )
        downlinkResponsiveness=$( echo "${networkQualityTest}" | /usr/bin/awk '/Downlink Responsiveness:/{print $3, $4, $5}' )
        echo "<result>${downlinkCapacity} | ${downlinkResponsiveness}</result>"
        ;;

esac

exit 0