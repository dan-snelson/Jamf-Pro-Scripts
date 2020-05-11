# Thycotic Privilege Manager macOS Agent Information
## Overview
While troubleshooting new installations of the macOS Thycotic Privilege Manager agent, I found myself frequently having to leverage `agentUtil.sh` as `root` to see exactly which policies had been applied before realizing I had neglected to add the new test machine to my testing Resource group.

Jamf Pro Scripts:
* [Thycotic Privilege Manager macOS Agent Information](Thycotic%20Privilege%20Manager%20macOS%20Agent%20Information.bash)
* [Thycotic Privilege Manager macOS Agent Diagnostics](Thycotic%20Privilege%20Manager%20macOS%20Agent%20Diagnostics.bash)

Jamf Pro Extension Attributes
* [Thycotic Machine ID](Thycotic%20Machine%20ID.sh)
* [Thycotic Health Check](Thycotic%20Health%20Check.sh)


---

## Description
**For Support Personnel Only**

Queries the macOS Thycotic Management Agent for various settings, saves the results to the user's Desktop as an HTML file, which is then opened in Safari.

If the `testAgentConnection` function results in a failure, the `kickstartAgent` function executes `settmsserver -serverUri ${thycoticURL} -installCode ${agentInstallCode}` in an attempt to resolve the connection failure.

(The HTML file includes hyperlinks to the policies in the Thycotic Privilege Manager console.)

---

## Customization
Update the following variables for your environment:
* `thycoticURL`
* `jamfProAdminURL`
* `kickstartChecks` (Jamf Pro Script Parameter 4)
* `agentInstallCode` (Jamf Pro Script Parameter 5)

---
## Notes
At various stages, the script executes `/usr/local/thycotic/agent/agentUtil.sh` …
* `register`
*  `updateclientitems`
* `clientitemsummary`
* `enableverboselogging`
* `settmsserver -serverUri ${thycoticURL} -installCode ${agentInstallCode}`

(I'm interested to try the `restart` command, but have yet to double-check with Thycotic support.)
