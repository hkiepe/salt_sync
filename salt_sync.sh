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
remote_script=$(grep "^remote_script=" "$script_dir/settings.conf" | cut -d "=" -f 2)
encrypted_password=$(grep "^encrypted_password=" "$script_dir/settings.conf" | cut -d "=" -f 2)

# Check if script was executed with any arguments
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided while excuting the script."
    exit 1
fi

# Check if the project directory from script argument exists
project_folder="$1"

# Check if $project_folder exists
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

# Check if the project configuration file "settings.conf" exists exists
if [ ! -f "$project_folder/settings.conf" ]; then
    echo "Error: Configuration file \"$project_folder/settings.conf\" not found."
    exit 1
fi

# Read the project configuration file variables from settings.conf
input_file=$(grep "^input_file=" "$project_folder/settings.conf" | cut -d "=" -f 2)
local_prefix=$(grep "^local_prefix=" "$project_folder/settings.conf" | cut -d "=" -f 2)
remote_host=$(grep "^remote_host=" "$project_folder/settings.conf" | cut -d "=" -f 2)
project_name=$(grep "^project_name=" "$project_folder/settings.conf" | cut -d "=" -f 2)

# Check if $input_file exists
if [ ! -f "$project_folder/$input_file" ]; then
    echo "Error: The source file \"$project_folder/$input_file\" is missing."
    exit 1
fi

# Call the function to prepare files
# prepare_files "$project_folder" "$input_file" "$project_name" "$local_prefix"

# Call the function to transfer files and to create the file structure on remote
# transfer_files "$script_dir" "$project_name.tmp" "$local_prefix" "$remote_host" "$project_name" "$remote_script" "$project_folder"

# Call the function to run the script on remote
run_remote_script "$script_dir" "$encrypted_password" "$remote_host" "$project_name" "$remote_script"

echo "The script has been finished"

exit 0