#!/bin/bash

# Function to read filenames from a file and save them to another file
prepare_files() {
    project_folder="$1"
    input_file="$2"
    project_name="$3"
    local_prefix="$4"

    # Read filenames from the input file and save them to the output file
    while IFS= read -r filename; do
        # Use sed to remove the prefix
        result=$(echo "$filename" | sed "s|$local_prefix||")

        echo "$result" >> "$project_folder/$project_name.tmp"
    done < "$project_folder/$input_file"

    echo "File names of the files to be transferred are saved to: $project_folder/$project_name.tmp"
}

transfer_files() {
    script_dir="$1"
    transfer_file="$2"
    local_prefix="$3"
    remote_host="$4"
    project_name="$5"
    remote_script="$6"
    project_folder="$7"

    # Check if the temporary transfer_file file exists
    if [ ! -f "$project_folder/$transfer_file" ]; then
        echo "Error: Transfer file not found."
        exit 1
    fi
    
    # Read filenames from the input file and transfer them to the remote server
    while IFS= read -r filename; do
        # create_directory_remote "$filename" "$remote_host"
        rsync -av -e ssh --rsync-path="mkdir -p $(dirname "~/$project_name$filename") && rsync" "$local_prefix$filename" "$remote_host:~/$project_name$filename"
    done < "$project_folder/$transfer_file"

    # Transfer the temporary file with filenames to the remote host
    scp "$project_folder/$transfer_file" "$remote_host:~/$project_name/$output_filename"

    # Transfer the remote script to the remote host
    scp "$script_dir/$remote_script" "$remote_host:~/$project_name/$remote_script"
    ssh "$remote_host" "chmod +x ~/$project_name/$remote_script"

    # Transfer the settings.conf from the project folder to the remote host
    scp "$project_folder/settings.conf" "$remote_host:~/$project_name/resources/settings.conf"

    # Delete the temporary file
    rm -rf "$project_folder/$transfer_file"

    echo "Processing complete. Files saved to: $remote_host"

}

run_remote_script() {
    script_dir="$1"
    encrypted_password="$2"
    remote_host="$3"
    project_name="$4"
    remote_script="$5"

    # decrypted_password=$(gpg --quiet --decrypt $encrypted_password)
    decrypted_password=$(gpg --decrypt $script_dir/$encrypted_password 2>/dev/null)
    
    # Run the remote script
    ssh -tt "$remote_host" "echo $decrypted_password | sudo -S -v && sudo ~/$project_name/$remote_script"
}