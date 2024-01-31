#!/bin/bash

# Make sure to fill settings in settings.conf
################################################

# Check if script was executed with sudo rigthts
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo."
    exit 1
fi

# Get the location fromn where this script is executed
script_dir="$(dirname "$(readlink -f "$0")")"


# Make script functions executable
chmod +x "$script_dir/installer/functions.sh"

# import Script functions
source $script_dir/installer/functions.sh

# check if all packages are installed: gpg jq,
if command -v gpg &> /dev/null; then
    echo "GPG is installed."
else
    echo "GPG is not installed. Please install it."
    exit 1
fi

if command -v jq &> /dev/null
then
    echo "jq is installed."
else
    echo "jq is not installed. Please install it."
    exit 1
fi

# Check if the main configuration file "settings.conf" exists
if [ ! -f "$script_dir/settings.conf" ]; then
    echo "Error: Configuration file \"$script_dir/settings.conf\" not found."
    exit 1
fi

# Read the entries from installer script "settings.conf" file
exclude_files_and_folders=$(grep "^exclude_files_and_folders=" "$script_dir/installer/settings.conf" | cut -d "=" -f 2)
destination_dir=$(grep "^destination_dir=" "$script_dir/installer/settings.conf" | cut -d "=" -f 2)
path_destination=$(grep "^path_destination=" "$script_dir/installer/settings.conf" | cut -d "=" -f 2)

# Remove trailing slash from file paths
destination_dir=$(remove_trailing_slash "$destination_dir")
path_destination=$(remove_trailing_slash "$path_destination")

# Convert the comma-separated values into an array
IFS=', ' read -r -a exclude_array <<< "$exclude_files_and_folders"

# Get all files to be transfered to the destination
output_files=""
# Start processing files from the specified directory
process_files "$script_dir"
# # Create the destination folder if it doesn't exist
# if [ ! -d "$destination_dir" ]; then
#     mkdir -p "$destination_dir"
# fi

# Iterate over each file in $output_files
for file in $output_files; do
    # Get the base file name
    filename=$(basename "$file")

    # echo "file: $file"
    filepath_without_prefix=$(echo "$file" | sed "s|^$script_dir||")
    filepath_without_prefix=$(echo "$filepath_without_prefix" | sed 's|^/||')

    # Extract the directory path from the file
    dir_path=$(dirname "$destination_dir/$filepath_without_prefix")

    # Create subdirectories if they don't exist
    mkdir -p "$dir_path"

    # Set the user rights for the directory
    chown 644 "$dir_path"
    
    # Copy the file to the destination directory
    cp "$file" "$destination_dir/$filepath_without_prefix"

    # Set the user rights for the file
    chown 755 "$destination_dir/$filepath_without_prefix"

    # Print a message for each file copied
    echo "Copied $filename to $dir_path"
done

config_file="settings.conf"
key="path_destination"
value="$path_destination"
# Check if the key already exists in the configuration file
if grep -q "^$key=" "$destination_dir/$config_file"; then
    echo "Key already exists. Skipping."
else
    # If the key doesn't exist, append the new entry to the configuration file
    echo -e "\n$key=$value" >> "$destination_dir/$config_file"
    echo "Entry added: $key=$value"
fi

key="destination_dir"
value="$destination_dir"
# Check if the key already exists in the configuration file
if grep -q "^$key=" "$destination_dir/$config_file"; then
    echo "Key already exists. Skipping."
else
    # If the key doesn't exist, append the new entry to the configuration file
    echo -e "$key=$value" >> "$destination_dir/$config_file"
    echo "Entry added: $key=$value"
fi

# Make script files executable
chmod +x "$destination_dir/salt_sync.sh"
chmod +x "$destination_dir/lib/functions.sh"
chmod +x "$destination_dir/uninstall.sh"

# make the script executable systemwide
ln -s "$destination_dir/salt_sync.sh" "$path_destination"

# install the gpg key if user wants that

# create a sample project

# copy the encryptecd gpg key to the project if requested

echo "Installation finished"