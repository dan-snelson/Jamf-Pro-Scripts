#!/bin/bash
#######################################################################
# A script to determine the user-selected delay for Jamf Pro policies #
#######################################################################

plist="/Library/Application Support/JAMF/.userdelay.plist"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

if [[ -f "${plist}" ]]; then
    deferredPolicies=$( plutil -p /Library/Application\ Support/JAMF/.userdelay.plist | sed 's/[\"\{\}=>]//g; s/ +0000//g; s/^ *//g; s/deferStartDate /S:/g; s/lastChosenDeferDate /E:/g; 1d' )
fi

if [[ -z "${deferredPolicies}" ]]; then
    deferredPolicies="None"
fi

echo "<result>${deferredPolicies}</result>"