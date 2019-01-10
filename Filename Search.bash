#!/bin/bash
####################################################################################################
#
# ABOUT
#
#	Filename Search
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0, 14-Nov-2018, Dan K. Snelson
#		Original version
#
####################################################################################################

echo " "
echo "***********************"
echo "*** Filename Search ***"
echo "***********************"
echo " "

authorizationKey="${4}"
# Check for a specified value in Parameter 4
if [[ "${authorizationKey}" != "]"Iy9;;A)nV{KDl[WHj[VE*-Cs{" ]]; then

	echo "Error: Incorrect Authorization Key; exiting."
	exit 1

else

	echo "Correct Authorization Key; proceeding …"

fi



declare -a files=("UBF8T346G9.OneDriveSyncClientSuite"
"File I don't want to Security to find.rtf"
"Nothing to worry about.txt"
"Marketing Budget 2019.xlsx"
)

#set -x

for file in "${files[@]}"
do
	printf "\nSearching for: \"$file\" ...\n"
	IFS='%'
	testFile=( `/usr/bin/mdfind -name "${file}"` )
	# testFile=( `/usr/bin/mdfind -interpret "${file}"` )	 # Search for contents of file; see man mdfind
	if [[ -z "${testFile}" ]]; then
		echo "\"$file\" NOT found"
	else
		printf "Found: \"$file\"; printing metadata for "${testFile}" ...\n\n"
		/usr/bin/mdls "${testFile}"
	fi
	printf "\n============================================================\n"
	unset IFS
done

#set +x

exit 0
