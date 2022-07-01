#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Pausing" initial Jamf Pro inventory collection
# https://snelson.us/2022/06/pausing-initial-jamf-pro-inventory-collection/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

secondsToWait="1800" # 1800 seconds is 30 minutes; 90061 seconds is 1 day, 1 hour, 1 minute and 1 second.
testFile="/var/db/.AppleSetupDone"
testFileSeconds=$( /bin/date -j -f "%s" "$(/usr/bin/stat -f "%m" $testFile)" +"%s" )
nowSeconds=$( /bin/date +"%s" )
ageInSeconds=$(( nowSeconds-testFileSeconds ))
secondsToWaitHumanReadable=$( printf '"%dd, %dh, %dm, %ds"\n' $((secondsToWait/86400)) $((secondsToWait%86400/3600)) $((secondsToWait%3600/60)) $((secondsToWait%60)) )
ageInSecondsHumanReadable=$( printf '"%dd, %dh, %dm, %ds"\n' $((ageInSeconds/86400)) $((ageInSeconds%86400/3600)) $((ageInSeconds%3600/60)) $((ageInSeconds%60)) )

if [[ ${ageInSeconds} -le ${secondsToWait} ]]; then
    echo "Set to wait ${secondsToWaitHumanReadable} and enrollment was ${ageInSecondsHumanReadable} ago; exiting."
    exit 0
else
    echo "Set to wait ${secondsToWaitHumanReadable} and enrollment was ${ageInSecondsHumanReadable} ago; proceeding …"
    /usr/local/bin/jamf recon
fi

exit 0