#!/bin/zsh --no-rcs 
# shellcheck shell=bash

####################################################################################################
#
# EA Execute
#
#   Purpose: Command-line script to execute a directory of Jamf Pro Script Extension Attributes
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0, 30-Sep-2025, Dan K. Snelson (@dan-snelson)
#   - First "official" version (tested with Jamf Pro 11.21.0)
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="1.0.0"

# Client-side Log
# scriptLog="org.churchofjesuschrist.log"
scriptLog="$(dirname "$1")/org.churchofjesuschrist.log"

# Log Level [ DEBUG, INFO, WARNING, ERROR ]
logLevel="DEBUG"

# Elapsed Time
SECONDS="0"


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Script Human-readabale Name
humanReadableScriptName="EA Execute"

# Organization's Script Name
organizationScriptName="EAX"

# Date Time Stamp
dateTimeStamp=$( date '+%Y-%m-%d-%H%M%S' )

# Array to store script durations
typeset -A SCRIPT_DURATIONS



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeScript() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    local start_time=$(date +%s%N)
    
    echo ""
    echo "----------------------------------"
    echo "▶ Executing: $script_name"
    echo "▶ Executing: $script_name" >> "${scriptLog}"

    # Log file for individual script
    local script_log="$LOG_DIR/${script_name}_${RUN_TIMESTAMP}.log"

    {
        echo "----- START: $(date) -----"
        echo "Script: $script_name"
        echo "--------------------------"
    } >> "$script_log"

    # Run the script and display + log output
    {
        zsh "$script_path"
    } 2>&1 | tee -a "$script_log" | tee -a "${scriptLog}"

    {
        echo "--------------------------"
        echo "------ END: $(date) ------"
    } >> "$script_log"

    local end_time=$(date +%s%N)
    local duration_ns=$((end_time - start_time))
    local duration_sec=$(bc <<< "scale=2; $duration_ns/1000000000")

    SCRIPT_DURATIONS[$script_name]="$duration_sec"

    echo "✅ $script_name  completed in ${duration_sec}s"
    echo "$script_name completed in ${duration_sec}s" >> "${scriptLog}"
    echo "" >> "${scriptLog}"
    echo "----------------------------------"
}



####################################################################################################
#
# Main Program
#
####################################################################################################

# Clear the screen
/usr/bin/clear

# Logging Preamble
echo "\n\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# https://snelson.us/audit\n#\n# Log Level: ${logLevel}\n###\n" | tee -a "${scriptLog}"

# Confirm script is running as root
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 1
fi

# Validate a directory was provided; if not, prompt the user
if [[ -z "$1" ]]; then
    echo "Usage: Drag and drop a folder of scripts into the Terminal window and press [Enter]."
    exit 1
fi

# Validate supplied directory is valid
SCRIPT_DIR="$1"
if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "Error: '$SCRIPT_DIR' is not a valid directory."
    exit 1
fi

# Directory to store logs
LOG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/executions"
mkdir -p "$LOG_DIR"

# Timestamp for this run
RUN_TIMESTAMP=$(date "+%Y-%m-%d-%H%M%S")

# Log Script Start
echo "Starting script batch run at $(date)" | tee -a "${scriptLog}"
echo "Script directory: $SCRIPT_DIR" | tee -a "${scriptLog}"
echo "Logging to: $LOG_DIR" | tee -a "${scriptLog}"
echo "--------------------------------------" | tee -a "${scriptLog}"

# Run All Executable Scripts
for script in "$SCRIPT_DIR"/*(.x); do
    if [[ -f "$script" ]]; then
        executeScript "$script"
    fi
done

# Output durations sorted from longest to shortest
echo "" | tee -a "${scriptLog}"
echo "" | tee -a "${scriptLog}"
echo "---------------------------------------" | tee -a "${scriptLog}"
echo "Execution Summary (Longest to Shortest)" | tee -a "${scriptLog}"
echo "---------------------------------------" | tee -a "${scriptLog}"
for entry in ${(k)SCRIPT_DURATIONS}; do
    echo "$entry: ${SCRIPT_DURATIONS[$entry]}s"
done | sort -t: -k2 -nr | tee -a "${scriptLog}"
echo "----------------------------------------" | tee -a "${scriptLog}"

echo "" | tee -a "${scriptLog}"
echo "" | tee -a "${scriptLog}"
echo "" | tee -a "${scriptLog}"
echo "Batch run complete at $(date)" | tee -a "${scriptLog}"
echo "Master log saved to: ${scriptLog}"
echo "Elapsed Time: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))" | tee -a "${scriptLog}"

# Set permissions for the log directory
chmod -R 777 "$LOG_DIR"

# Open the log directory in Finder
open -R "${scriptLog}"

# Exit
exit 0