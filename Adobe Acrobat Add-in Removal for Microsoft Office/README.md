# Adobe Acrobat Add-in Removal for Microsoft 365

> User-friendly Adobe Acrobat Add-in Removal for Microsoft 365

![Adobe Acrobat Add-in Removal for Microsoft 365](images/Acrobat%20Add-in%20Removal%20Hero.png)

## Background

Each time Adobe Acrobat Pro is installed or updated, the Acrobat Add-in is silently added back to the Microsoft 365-related User Content Startup folders.

The Add-in relies on external dynamic libraries — which we purposely disable by setting DisableVisualBasicExternalDylibs to true — causing users to observe error messages in the following applications:
- Microsoft Excel
- Microsoft Word
- Microsoft PowerPoint

<img src="images/Error%20Excel.png" width="250"><img src="images/Error%20Word.png" width="250"><br />
<img src="images/Error%2032815.png" width="250">

[Continue reading …](https://snelson.us/2024/09/user-friendly-adobe-acrobat-add-in-removal-for-microsoft-365/)

## Scripts
- [Adobe Acrobat Add-in Removal for Microsoft 365.zsh](Adobe%20Acrobat%20Add-in%20Removal%20for%20Microsoft%20365.zsh)
- [Adobe Acrobat Add-in Removal for Microsoft Office.bash](Adobe%20Acrobat%20Add-in%20Removal%20for%20Microsoft%20Office.bash)