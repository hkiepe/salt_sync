#!/bin/bash

# Make sure to fill settings in settings.conf
################################################

# Get the location fromn where this script is executed
working_directory=$(pwd)
script_dir="$(dirname "$(readlink -f "$0")")"

# import Script functions
source $script_dir/installer/functions.sh

# Check if script was executed with sudo rigthts
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo."
    exit 1
fi

# Check if the main configuration file "settings.conf" exists
if [ ! -f "$script_dir/settings.conf" ]; then
    echo "Error: Configuration file \"$script_dir/settings.conf\" not found."
    exit 1
fi

# Read the entries from main script "settings.conf" file
output_filemap_file=$(grep "^output_filemap_file=" "$script_dir/settings.conf" | cut -d "=" -f 2)
project_settings_file=$(grep "^project_settings_file=" "$script_dir/settings.conf" | cut -d "=" -f 2)

# Read the entries from installer script "settings.conf" file
exclude_files_and_folders=$(grep "^exclude_files_and_folders=" "$script_dir/installer/settings.conf" | cut -d "=" -f 2)
destination_dir=$(grep "^destination_dir=" "$script_dir/installer/settings.conf" | cut -d "=" -f 2)

# Convert the comma-separated values into an array
IFS=', ' read -r -a exclude_array <<< "$exclude_files_and_folders"

# Get all files to be transfered to the destination
output_files=""

# Start processing files from the specified directory
process_files "$script_dir"

# Create the destination folder if it doesn't exist
echo "destination_dir $destination_dir"
if [ ! -d "$destination_dir" ]; then
    mkdir -p "$destination_dir"
fi

# Iterate over each file in $output_files
for file in $output_files; do
    # Get the base file name
    filename=$(basename "$file")

    # echo "file: $file"
    filepath_without_prefix=$(echo "$file" | sed "s|^$script_dir||")
    # echo "filepath_without_prefix: $filepath_without_prefix"

    # Extract the directory path from the file
    dir_path=$(dirname "$destination_dir$filepath_without_prefix")

    # Create subdirectories if they don't exist
    mkdir -p "$dir_path"
    
    # Copy the file to the destination directory
    cp "$file" "$destination_dir$filepath_without_prefix"
    
    # Optional: Print a message for each file copied
    echo "Copied $filename to $dir_path"
done

echo "All files copied to $destination_dir"

# set rights and owner for the script files

# install the gpg key if user wants that

# create a sample project

# copy the gpg key to the project if requested