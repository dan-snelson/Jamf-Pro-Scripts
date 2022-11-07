# Adobe Acrobat Add-in Removal for Microsoft Office

> Provide users with detailed feedback while removing Acrobat's Add-in from Microsoft Office

![Adobe Acrobat Add-in Removal for Microsoft Office Screenshot](images/Adobe%20Acrobat%20Add-in%20Removal%20for%20Microsoft%20Office%20Screenshot.png)

## Background

When we implemented Microsoft's recommended macro security in Office for Mac settings via a Configuration Profile some time ago, we also started offering users Paul Bowden's Office-Reset packages via Jamf Pro's Self Service.

However, each time Adobe Acrobat Pro is installed or updated, the Acrobat Add-in silently finds its way into the user's Microsoft Office apps, and the Add-in relies on external dynamic libraries — which we purposely disabled by setting DisableVisualBasicExternalDylibs to true — resulting in error messages being displayed to users in the following applications:

- Microsoft Word
- Microsoft Excel
- Microsoft PowerPoint

![Error 32815](images/Error%2032815.png)

[Continue reading …](https://snelson.us/2022/11/nuke-acrobat-Add-in)

## Script
[Adobe Acrobat Add-in Removal for Microsoft Office.bash](Adobe%20Acrobat%20Add-in%20Removal%20for%20Microsoft%20Office.bash)