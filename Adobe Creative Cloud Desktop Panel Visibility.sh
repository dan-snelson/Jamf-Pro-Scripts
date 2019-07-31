#!/bin/sh
####################################################################################################
#
# ABOUT
#
#	Adobe Creative Cloud Desktop Panel Visibility
#
#	See: https://helpx.adobe.com/in/creative-cloud/kb/apps-tab-missing.html
#	See: https://helpx.adobe.com/in/creative-cloud/kb/disable-updates-and-apps-panel-for-the-creative-cloud-products.html
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 12-Oct-2017, Dan K. Snelson
#		Original version
#
#	Version 1.1, 29-Jul-2019, Dan K. Snelson
#		Updated for Creative Cloud Desktop app 4.9.0.504
#
####################################################################################################



### Variables
loggedInUser=$( /usr/bin/stat -f%Su /dev/console )	# Currently logged in user

### Functions
killProcess(){
	echo "Quit Adobe-related process: \"${1}\" ..."
	/usr/bin/pkill -l -U ${loggedInUser} ${1}
}


echo "### Adobe Creative Cloud Desktop: Panel Visibility ###"


# If Parameter 4 is blank, use "false" as the default value ...
if [[ "${4}" != "" ]] && [[ "${AppsPanelVisibility}" == "" ]]; then

	AppsPanelVisibility="${4}"						# Apps Panel Visibility (i.e., "true" | "false")

else

	echo "Parameter 4 is blank; using \"false\" as the visibilty setting for the Adobe Creative Cloud Desktop Apps panel ..."
	AppsPanelVisibility="false"

fi



# Check for a valid value for Apps Panel Visibility (i.e., "true" or "false")
if [[ "${AppsPanelVisibility}" == "true" ]] || [[ "${AppsPanelVisibility}" == "false" ]]; then

	echo "Using \"${AppsPanelVisibility}\" as the visibilty setting for the Adobe Creative Cloud Desktop Apps panel ..."

	echo "Quit Adobe Creative Cloud Desktop App ..."
	killProcess "Creative Cloud"
	killProcess "CCLibrary"
	killProcess "Core Sync"
	killProcess "Core Sync Helper"
	killProcess "Adobe Desktop Service"
	killProcess "CCXProcess"


	if [[ "${AppsPanelVisibility}" == "false" ]]; then

		echo "Disabling Apps Panel Visibility ..."
		/bin/echo "<config>
  <panel>
    <name>AppsPanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>FilesPanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>MarketPanel</name>
    <masked>false</masked>
  </panel>
  <panel>
    <name>StockPanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>BehancePanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>FontsPanel</name>
    <visible>false</visible>
  </panel>
  <feature>
    <name>SelfServeInstalls</name>
    <enabled>false</enabled>
  </feature>
</config>" > /Library/Application\ Support/Adobe/OOBE/Configs/ServiceConfig.xml

	elif [[ "${AppsPanelVisibility}" == "true" ]]; then

		echo "Enabling Apps Panel Visibility ..."
		/bin/echo "<config>
  <panel>
    <name>AppsPanel</name>
    <visible>true</visible>
  </panel>
  <panel>
    <name>FilesPanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>MarketPanel</name>
    <masked>false</masked>
  </panel>
  <panel>
    <name>StockPanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>BehancePanel</name>
    <visible>false</visible>
  </panel>
  <panel>
    <name>FontsPanel</name>
    <visible>false</visible>
  </panel>
  <feature>
    <name>SelfServeInstalls</name>
    <enabled>false</enabled>
  </feature>
</config>" > /Library/Application\ Support/Adobe/OOBE/Configs/ServiceConfig.xml

	fi

	# Reload preferences
	echo "Reload preferences for ${loggedInUser} ..."
	/usr/bin/pkill -l -U "${loggedInUser}" cfprefsd

	# Launch Adobe Creative Cloud Desktop App
	#echo "Launch Adobe Creative Cloud Desktop App as \"${loggedInUser}\" ..."
	#/usr/bin/su \- "${loggedInUser}" -c "/usr/bin/open '/Applications/Utilities/Adobe Creative Cloud/ACC/Creative Cloud.app'"

else

	echo "ERROR: Parameter 4 set to \"${AppsPanelVisibility}\" instead of either \"true\" or \"false\"; exiting."
	exit 1

fi



# Record result to JSS
echo "Set Adobe Creative Cloud Desktop Apps Panel Visibility to \"${AppsPanelVisibility}\"."

exit 0
