# Thycotic Privilege Manager macOS Agent
### Description

Queries the macOS Thycotic Management Agent for various settings, saves the results to the user's Desktop as an HTML file, which is then opened in Safari.

If the `testAgentConnection` function results in a failure, the `kickstartAgent` function executes `settmsserver -serverUri ${thycoticURL} -installCode ${agentInstallCode}` in an attempt to resolve the connection failure.

---

### Jamf Pro Scripts
* [Thycotic Privilege Manager macOS Agent Information](Thycotic%20Privilege%20Manager%20macOS%20Agent%20Information.bash)
	* While troubleshooting new installations of the macOS Thycotic Privilege Manager agent, I found myself frequently having to leverage `agentUtil.sh` as `root` to see exactly which policies had been applied before realizing I had neglected to add the new test machine to my testing Resource group.
	* The HTML file includes hyperlinks to the policies in the Thycotic Privilege Manager console.
	* For Support Personnel Only
	* Reporting only (i.e., no diagnostics)
	* Customization
		* Update the `privilegeManagerURL` variable for your environment
		* Update the `jamfProAdminURL` variable for your environment

* [Thycotic Privilege Manager macOS Agent Diagnostics](Thycotic%20Privilege%20Manager%20macOS%20Agent%20Diagnostics.bash)
	* More robust version of _Thycotic Privilege Manager macOS Agent Information_
	* Leverages `settmsserver -serverUri ${thycoticURL} -installCode ${agentInstallCode}` to kickstart the agent
	* The HTML file includes hyperlinks to the policies in the Thycotic Privilege Manager console.
	* For Support Personnel Only
	* Customization
		* Update the `thycoticURL` variable for your environment
		* Update the `jamfProAdminURL` variable for your environment
		* Jamf Pro Script Parameter 4: Number of Kickstart Checks
		* Jamf Pro Script Parameter 5: Thycotic Agent Install Code

* [Thycotic Management Agent Kickstart](Thycotic%20Management%20Agent%20Kickstart.sh)
	* Simplified version of _Thycotic Privilege Manager macOS Agent Diagnostics_
	* No HTML output
	* Used as a remediation for _Thycotic Health Check_ Extension Attribute

---

### Jamf Pro Extension Attributes
* [Thycotic Machine ID](Thycotic%20Machine%20ID.sh)
	* Returns Thycotic Machine ID GUID
* [Thycotic Health Check](Thycotic%20Health%20Check.sh)
	* Validates access to `${thycoticURL}PrivilegeManager/#`
	* Validated access to `${thycoticURL}Agent/AgentRegistration4.svc`
	* Attempts to `updateclientitems`
	* Customization
		* Update the `thycoticURL` variable for your environment
		* Jamf Pro Smart Group Criteria
			* Thycotic Health Check
			* like
			* FAIL

---

### Notes
At various stages, the script executes `/usr/local/thycotic/agent/agentUtil.sh` …
* `register`
*  `updateclientitems`
* `clientitemsummary`
* `enableverboselogging`
* `settmsserver -serverUri ${thycoticURL} -installCode ${agentInstallCode}`
