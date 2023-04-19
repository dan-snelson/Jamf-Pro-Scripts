# Trigger Policy at Login or Reboot

> Run any Jamf Pro policy at the next user login or computer reboot

<img src="images/Trigger%20Policy%20at%20Login%20or%20Reboot.png" width="250">

## Background

Recently, we had a need to run a particular Jamf Pro policy the _next_ time the computer rebooted.

Having previously created [Recon at Reboot](https://snelson.us/2022/08/recon-at-reboot-1-0-1/), I started on a  modification for this one-off need. About a third of the way into the modifications, a heaven-inspired question came to mind:

> Why don't you write a script to execute _**any**_ Jamf Pro policy at the next reboot?


## Implementation

Here's a pair of scripts which will run any in-scope Jamf Pro policy — by trigger name or ID — when the computer is rebooted (or, via Self Service, when the user next logs in).

[Continue reading …](https://snelson.us/2023/04/trigger-policy-at-login-or-reboot)


### Scripts
- [Trigger Policy at Login or Reboot - Create.bash](Trigger%20Policy%20at%20Login%20or%20Reboot%20-%20Create.bash)
- [Trigger Policy at Login or Reboot - Delete.bash](Trigger%20Policy%20at%20Login%20or%20Reboot%20-%20Delete.bash)
