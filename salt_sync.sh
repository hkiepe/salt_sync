#!/bin/bash

# The project folder needs to contain two files:
#   - settings.conf (A file with the initial project settings. See the sample settings in project repository.)
#   - files.txt (A file with the file paths to the state and pillar files.)
# 1st argument to run the script should be the relative or absolute project folder path,
#   where the settings.conf file and the files.txt file for the project are located.
################################################################################################################################

# Function to read filenames from a file and save them to another file
prepare_files() {
    project_folder="$1"
    input_file="$2"
    project_name="$3"
    local_prefix="$4"

    location=$(pwd)

    # Read filenames from the input file and save them to the output file
    while IFS= read -r filename; do
        # Use sed to remove the prefix
        result=$(echo "$filename" | sed "s|$local_prefix||")

        echo "$result" >> "$project_folder/$project_name.tmp"
    done < "$project_folder/$input_file"

    echo "File names of the files to be transferred are saved to: $project_folder/$project_name.tmp"
}

transfer_files() {
    transfer_file="$1"
    local_prefix="$2"
    remote_host="$3"
    project_name="$4"

    # "$output_filename" "$local_prefix" "$remote_host" "$project_name"

    # Check if the temporary transfer_file file exists
    if [ ! -f "$transfer_file" ]; then
        echo "Error: Transfer file not found."
        exit 1
    fi
    
    # Read filenames from the input file and transfer them to the remote server
    while IFS= read -r filename; do
        echo "PROJECT: ~/$project_name$filename"
        # create_directory_remote "$filename" "$remote_host"
        rsync -av -e ssh --rsync-path="mkdir -p $(dirname "~/$project_name$filename") && rsync" "$local_prefix$filename" "$remote_host:~/$project_name$filename"
    done < "$transfer_file"

    # Transfer the temporary file with filenames to the remote host
    scp "$transfer_file" "$remote_host:~/$project_name/$output_filename"

    # Create the script folders
    ssh "$remote_host" "mkdir -p ~/$project_name/resources/remote/"

    # Transfer the remote script to the remote host
    scp "./resources/remote/remote_script.sh" "$remote_host:~/$project_name/resources/remote/remote_script.sh"
    ssh "$remote_host" "chmod +x ~/$project_name/resources/remote/remote_script.sh"

    # Transfer the settings.conf to the remote host
    scp "./settings.conf" "$remote_host:~/$project_name/resources/settings.conf"

    # Delete the temporary file
    rm -rf ./"$transfer_file"

    echo "Processing complete. Files saved to: $remote_host"

}

run_remote_script() {
    remote_host="$1"
    project_name="$2"
    decrypted_password=$(gpg --quiet --decrypt encrypted_password.asc)
    
    ssh -tt "$remote_host" "echo $decrypted_password | sudo -S -v && sudo ~/$project_name/resources/remote/remote_script.sh"
}

# Main script
###################################################################################################################

# Check if the project directory exists
project_folder="$1"

# Check if script was executed with any arguments
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided while excuting the script."
    exit 1
fi

# Check if $project_folder path ends with a slash
    if [[ "$project_folder" == */ ]]; then
        # Remove the trailing slash
        project_folder="${project_folder%/}"
    fi

# Check if $project_folder exists
if [ ! -d "$project_folder" ]; then
    echo "Failed! The project directory \"$project_folder\" does not exist."
    echo "Check whether the folder path was specified correctly as the first argument."
    exit 1
fi

# Check if settings.conf exists
if [ ! -f "$project_folder/settings.conf" ]; then
    echo "Error: Configuration file \"$project_folder/settings.conf\" not found."
    exit 1
fi

# Read the the configuration file variables from settings.conf
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
prepare_files "$project_folder" "$input_file" "$project_name" "$local_prefix"

# Call the function to transfer files and to create the file structure on remote
transfer_files "$project_folder/$project_name.tmp" "$local_prefix" "$remote_host" "$project_name"

# Call the function to run the script on remote
# run_remote_script "$remote_host" "$project_name"

echo "The script has been finished"