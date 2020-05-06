# Thycotic Privilege Manager macOS Agent Information
## Overview
While troubleshooting new installations of the macOS Thycotic Privilege Manager agent, I found myself frequently having to leverage `agentUtil.sh` as `root` to see exactly which policies had been applied before realizing I had neglected to add the new test machine to my testing Resource group.

Bash Scripts:
* [Jamf Pro Policy Script](https://github.com/dan-snelson/Jamf-Pro-Scripts/blob/master/Thycotic%20Privilege%20Manager%20macOS%20Agent/Thycotic%20Privilege%20Manager%20macOS%20Agent%20Information.bash)
* [Jamf Pro Extension Attribute](https://github.com/dan-snelson/Jamf-Pro-Scripts/blob/master/Thycotic%20Privilege%20Manager%20macOS%20Agent/Thycotic%20Machine%20ID.bash)

---

## Description
**For Support Personnel Only**

Queries the macOS Thycotic Management Agent for various settings, saves the results to the user's Desktop as an HTML file, which is then opened in Safari.

(The HTML file includes hyperlinks to the policies in the Thycotic Privilege Manager console.)

---

## Customization
Update lines 35 to 41 for your environments.

(We have a Stage lane Jamf Pro server, thus the different values for `jamfProAdminURL`.)

---
## Notes
At various stages, the script executes `/usr/local/thycotic/agent/agentUtil.sh` …
* `register`
*  `updateclientitems`
* `clientitemsummary`

(I'm interested to try the `restart` command, but have yet to double-check with Thycotic support.)
