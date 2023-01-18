# Actionable messages with Jamf Helper

> For older macOS versions when `swiftDialog` isn’t an option, leverage Jamf Helper to provide your users actionable messages

## Background

For computers running macOS Big Sur 11 or later, `swiftDialog` is our go-to tool for displaying end-user messages.

For the less than double-digit stragglers we still have running macOS Catalina, a fresh deployment of Nudge-Python seemed overkill, so we turned to our old friend `jamfHelper` and added some new racing stripes:

- Auto-terminate `fullscreen` mode (after a configurable duration)
- Auto-execute the specified `action` (when in `fullscreen` mode)

![Jamf Helper Fullscreen](images/fs.png)
| ![Jamf Helper Fullscreen](images/utility.png) | ![Jamf Helper Fullscreen](images/hud.png) |
|---|---|

[Continue reading …](https://snelson.us/2023/01/jamf-helper)

## Script
- [Actionable-message-with-Jamf-Helper.bash](Actionable-message-with-Jamf-Helper.bash)
