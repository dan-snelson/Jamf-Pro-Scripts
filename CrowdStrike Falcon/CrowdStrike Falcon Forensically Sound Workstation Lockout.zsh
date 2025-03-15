#!/bin/zsh

# macOS Forensically Sound Workstation Lockout (1.0.0)
# (Estimated Duration: 0h:0m:10s)

echo -e "\n\n\n###\n# macOS Forensically Sound Workstation Lockout  (1.0.0)\n# (Estimated Duration: 0h:0m:10s)\n###"

# Initialize SECONDS
SECONDS="0"

# Jamf binary-related Variables
jamfVersion=$( /usr/local/bin/jamf -version | cut -d "=" -f2 )
jamfPid=$( pgrep -a "jamf" | head -n 1 )
if [[ -n "${jamfPid}" ]]; then
    echo "• jamf ${jamfVersion} binary already running …"
    ps -p "${jamfPid}"
    echo "• Killing  ${jamfPid} …"
    kill "${jamfPid}"
fi

echo "• Executing Jamf Pro Policy Trigger …"
/usr/local/bin/jamf policy -trigger purpleMonkeyDishwasher -verbose

echo -e "\nExecution Duration: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"
