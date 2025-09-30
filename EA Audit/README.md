# EA Audit
> Tested with Jamf Pro 11.21.0

## EA-Download.zsh
The [EA-Download.zsh](./EA-Download.zsh) script is a command-line utility designed to _download_ **Script** Extension Attributes (EAs) from a Jamf Pro server into a time-stamped directory. (It supports both on-premises and cloud-hosted Jamf Pro instances.)

- Use `zsh EA-Download.zsh help` for first-time set up.
- Use `zsh EA-Download.zsh configuration` to review or update configuration settings.

---

## EA-Execute.zsh
The [EA-Execute.zsh](./EA-Execute.zsh) script is a command-line utility designed to _execute_ **Script** Extension Attributes (EAs) downloaded from a Jamf Pro server, running each EA and capturing the output to a file.

---

## Additional Information

- [Jamf Pro Performance Tuning: Extension Attribute Audit](https://snelson.us/2022/11/ea-audit/)