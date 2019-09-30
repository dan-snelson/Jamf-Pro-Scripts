# Your Internal Beta Test Program: Opt-in / Opt-out via Self Service

## Scripts
- [Extension Attribute Update.bash](https://github.com/dan-snelson/Jamf-Pro-Scripts/blob/master/Extension%20Attribute%20Update.bash) 
- [Client-side Functions](https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Client-side%20Functions)

![Screenshot of Self Service policy](https://raw.githubusercontent.com/dan-snelson/Jamf-Pro-Scripts/master/Your%20Internal%20Beta%20Test%20Program/Screen%20Shot%202018-06-29%20at%2010.00.27%20PM.png)

---

## Background

Inspired by @elliotjordan's plea to obtain user feedback, we've been using a pop-up menu Computer Extension Attribute called "Testing Level" which has three options:
- Alpha (i.e., bleeding-edge test machines)
- Beta (i.e., direct team members)
- Gamma (i.e., opt-in testers from various teams)

![Screenshot of Testing Level Extenstion Attribute](https://raw.githubusercontent.com/dan-snelson/Jamf-Pro-Scripts/master/Your%20Internal%20Beta%20Test%20Program/Screen%20Shot%202018-06-29%20at%2010.03.06%20PM.png)

We then have Smart Computer Groups for each of the three levels and a fourth for "none" so we can more easily scope policies.
- Testing: Alpha Group
- Testing: Beta Group
- Testing: Gamma Group
- Testing: None

![Screenshot of Testing: None Smart Group](https://raw.githubusercontent.com/dan-snelson/Jamf-Pro-Scripts/master/Your%20Internal%20Beta%20Test%20Program/Screen%20Shot%202018-06-30%20at%205.07.54%20PM.png)

This has been working well, but has required a Jamf Pro administrator to manually edit each computer record and specify the desired Testing Level.

After being challenged by @mike.paul and @kenglish to leverage the API, a search revealed @seansb's [Updating Pop-Up Extension Attribute Value via API](https://www.jamf.com/jamf-nation/discussions/18307/) post and @mm2270's reply about [Results of single extension attribute via API](https://www.jamf.com/jamf-nation/discussions/15258/results-of-single-extension-attribute-via-api#responseChild93856) we had exactly what we needed.

---

## API Permissions for Computer Extension Attributes

In my rather frustated testing, the API read / write account needs (at least) the following Jamf Pro Objects "Read" and "Update" permissions:

- Computer Extension Attributes
- Computers
- User Extension Attributes
- Users

---

## Script: Extension Attribute Update

You'll need the [Client-side Functions](https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Client-side%20Functions) installed on each Mac and you'll need to update the "apiURL" in the [Extension Attribute Update.sh](https://github.com/dan-snelson/Jamf-Pro-Scripts/blob/master/Extension%20Attribute%20Update.sh) script which leverages parameters 4 though 7 for:

- API Username
- API Password
- EA Name (i.e., "Testing Level")
- EA Value (i.e., "Gamma" or "None")

![Screenshot of Extension Attribute Update.sh](https://raw.githubusercontent.com/dan-snelson/Jamf-Pro-Scripts/master/Your%20Internal%20Beta%20Test%20Program/Screen%20Shot%202018-06-30%20at%206.06.30%20PM.png)

---

## Opt-in Beta Test Program Self Service Policy

Create an ongoing Self Sevice policy, scoped to "Testing: None" which includes a single Scripts option of "Update Extension Attribute" and specify:
- API Username (Read / Write)
- API Password (Read / Write)
- EA Name (i.e., "Testing Level")
- EA Value (i.e., "Gamma" or "None")

---

## Opt-out Beta Test Program Self Service Policy

Clone your Opt-in policy and change EA Value to "None" to unset a computer's Testing Level; scope to your testing groups.
