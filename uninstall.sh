#!/bin/bash

# Check if script was executed with sudo rigthts
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo."
    exit 1
fi

# Get the locatiuon of the uninstall script
script_dir="$(dirname "$(readlink -f "$0")")"

# Read the configuration file variables from settings.conf
path_destination=$(grep "^path_destination=" "$script_dir/settings.conf" | cut -d "=" -f 2)
destination_dir=$(grep "^destination_dir=" "$script_dir/settings.conf" | cut -d "=" -f 2)

rm "-rf" "$path_destination"

# Check the exit status of the last command
if [ $? -eq 0 ]; then
    echo "Script PATH $path_destination was succesfully removed"
else
    echo "Error: Removal of script PATH failed with exit code $?"
fi

rm "-rf" "$destination_dir"

# Check the exit status of the last command
if [ $? -eq 0 ]; then
    echo "Script directory $destination_dir was succesfully removed"
else
    echo "Error: Removal of script directory $destination_dir failed with exit code $?"
fi

echo "Script finished"