# Recon at Reboot

> Creates a self-destructing LaunchDaemon and Bash script to run a recon at next Reboot, after confirming your Jamf Pro server is available


## Background

With surprising frequency, updating a computer's inventory with the Jamf Pro server the _next_ time a computer reboots can be quite handy. For example:

- After upgrading the OS via [erase-install](https://github.com/grahampugh/erase-install/wiki)
- After completing [Setup Your Mac](https://snelson.us/2022/06/setup-your-mac-via-swiftdialog-1-2-1/)
- After running [Office Reset](https://office-reset.com)
- After FileVault-related policies

The self-destructing script below will create a LaunchDaemon and Bash script to run a `recon` at the next reboot, after confirming your Jamf Pro server is available.

[Continue reading …](https://snelson.us/2022/08/recon-at-reboot-1-0-1/)


## Script
- [Recon at Reboot](Recon%20at%20Reboot.sh)
