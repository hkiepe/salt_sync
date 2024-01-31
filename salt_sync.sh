#!/bin/bash

# The project folder needs to contain two files:
#   - settings.conf (A file with the initial project settings. See the sample settings in project repository.)
#   - files.txt (A file with the file paths to the state and pillar files.)
# 1st argument to run the script should be the relative or absolute project folder path,
#   where the settings.conf file and the files.txt file for the project are located.
################################################################################################################################

# Get the location fromn where this script is executed
script_dir=$(dirname "$(realpath "$0")")

# import Script functions
source $script_dir/lib/functions.sh

# Check if the main configuration file "settings.conf" exists
if [ ! -f "$script_dir/settings.conf" ]; then
    echo "Error: Configuration file \"$script_dir/settings.conf\" not found."
    exit 1
fi

# Read the entries from main script "settings.conf" file
output_filemap_file=$(grep "^output_filemap_file=" "$script_dir/settings.conf" | cut -d "=" -f 2)
project_settings_file=$(grep "^project_settings_file=" "$script_dir/settings.conf" | cut -d "=" -f 2)

# Check if script was executed with any arguments
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided while excuting the script."
    exit 1
fi

# Check if $project_folder exists
project_folder="$1"
if [ ! -d "$project_folder" ]; then
    echo "Failed! The project directory \"$project_folder\" does not exist."
    echo "Check whether the folder path was specified correctly as the first argument."
    exit 1
fi

# Check if $project_folder path ends with a slash and delete it
    if [[ "$project_folder" == */ ]]; then
        # Remove the trailing slash
        project_folder="${project_folder%/}"
    fi

# Get the absolute path of the project directory
# project_folder=$(readlink -f "$project_folder")

# Check if the project configuration file "settings.conf" exists
if [ ! -f "$project_folder/$project_settings_file" ]; then
    echo "Error: Configuration file \"$project_folder/$project_settings_file\" not found."
    exit 1
fi

# Read the project configuration file variables from settings.conf
file_map=$(grep "^file_map=" "$project_folder/settings.conf" | cut -d "=" -f 2)
remote_host=$(grep "^remote_host=" "$project_folder/settings.conf" | cut -d "=" -f 2)
remote_script=$(grep "^remote_script=" "$project_folder/settings.conf" | cut -d "=" -f 2)
project_name=$(grep "^project_name=" "$project_folder/settings.conf" | cut -d "=" -f 2)
archive_name=$(grep "^archive_name=" "$project_folder/settings.conf" | cut -d "=" -f 2)
encrypted_password=$(grep "^encrypted_password=" "$project_folder/settings.conf" | cut -d "=" -f 2)

# Make remote script executable
chmod +x "project_folder/$remote_script"

# Check if $input_file exists
if [ ! -f "$project_folder/$file_map" ]; then
    echo "Error: The source file \"$project_folder/$file_map\" is missing."
    exit 1
fi

# Prepare the archive
prepare_archive "$project_folder" "$archive_name" "$file_map" "$remote_script" "$project_settings_file" "$output_filemap_file"

# Create the archive
tar -czvf "$project_folder/$archive_name.tar.gz" "$project_folder/$archive_name"

# Transfer archive to remote host
# rsync -av -e ssh --rsync-path="mkdir -p $(dirname "~/$project_name") && rsync" "$project_folder/$archive_name.tar.gz" "$remote_host:~/$project_name/"
rsync -avz -e ssh "$project_folder/$archive_name.tar.gz" "$remote_host:~/"

# unpack the archive on remote host
ssh "$remote_host" "tar -xzvf ~/$archive_name.tar.gz"

# Execute remote script
run_remote_script "$project_folder/$encrypted_password" "$remote_host" "$project_name" "$remote_script" "$archive_name"

# Clean up all temporary files
rm -rf "$project_folder/$archive_name"
rm -rf "$project_folder/$archive_name.tar.gz"
ssh "$remote_host" "rm -rf ~/$archive_name.tar.gz ~/$project_name"

exit 0
