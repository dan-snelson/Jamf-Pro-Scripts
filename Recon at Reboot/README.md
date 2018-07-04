# Recon at Reboot

## Overview

The script below will create a LaunchDaemon and Bash script to run Recon at the next reboot.

We've found this helpful with OS upgrade policies which tend to ignore (or fail) when "Maintenance > Update Inventory" is included.

---

## Background

We use [Deploying an OS X Upgrade](http://docs.jamf.com/technical-papers/casper-suite/deploying-osx/Deploying_an_OS_X_Upgrade.html) as a guide for our users to upgrade their operating system via Self Service.

After the installer is cached, in a separate policy, we prompt users to visit Self Service and actually run the OS upgrade. The policy then updates inventory.

Including "Maintenance > Update Inventory" in the OS installation policy proved problematic and after a sucessful OS upgrade via Self Service, the JSS would have stale inventory data and end-users would be again prompted to install the OS upgrade they ran the day before.

---

## Scripts
- [Recon at Reboot](https://github.com/dan-snelson/Jamf-Pro-Scripts/blob/master/Recon%20at%20Reboot/Recon%20at%20Reboot.sh)
- [Client-side Functions](https://github.com/dan-snelson/Jamf-Pro-Scripts/tree/master/Client-side%20Functions)
