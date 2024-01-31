#!/bin/bash

# Reads the filemap from the json file and return a file list
read_json() {
    file_map=$(cat "$1")

    # Parse JSON using jq (make sure jq is installed on the local machine)
    file_map=$(echo "$file_map" | jq -r '.[] | "source=\(.source) target=\(.target)"')
    echo "$file_map"
}

# Iterate through the file map copy files to archive and prepare new file map
copy_source_files_to_archive(){
    file_map="$1"
    project_folder="$2"
    archive_name="$3"
    output_filemap_file="$4"

    # Get source file
    initial_file_map=$(read_json "$project_folder/$file_map")

    touch "$project_folder/$archive_name/$output_filemap_file"
    counter=1
    while IFS= read -r initial_line; do
        source_file=$(echo "$initial_line" | grep -oP 'source=\K[^ ]+')
        target_file=$(echo "$initial_line" | grep -oP 'target=\K[^ ]+')
        
        # Cut the filepath out and create new name for the source file with counter
        new_source_filename="$counter$(basename $source_file)"

        # Copy file to archive folder and rename
        cp "$source_file" "$project_folder/$archive_name/$new_source_filename"

        # Concatenate entry to output file
        echo "source=$new_source_filename target=$target_file" >> "$project_folder/$archive_name/$output_filemap_file"

        ((counter++))
    done <<< "$initial_file_map"
}

# Coppy all files which are needed to a temporary folder in the project directory.
# While coppying the source files, rename them and map the new names to the target.
prepare_archive() {
    project_folder="$1"
    archive_name="$2"
    file_map="$3"
    remote_script="$4"
    project_settings_file="$5"
    output_filemap_file="$6"

    # Create the archive folder
    mkdir -p "$project_folder/$archive_name"

    # Coppy the source file to the archive and create new mapping
    copy_source_files_to_archive "$file_map" "$project_folder" "$archive_name" "$output_filemap_file"

    # Copy remote script file into archive folder
    cp "$project_folder/$remote_script" "$project_folder/$archive_name/$remote_script"

    # Copy settings.conf file into archive folder
    cp "$project_folder/$project_settings_file" "$project_folder/$archive_name/$settings_file"

    echo "[salt_sync] Archive prepared"
}

run_remote_script() {
    encrypted_password="$1"
    remote_host="$2"
    project_name="$3"
    remote_script="$4"
    archive_name="$5"

    # decrypted_password=$(gpg --quiet --decrypt $encrypted_password)
    decrypted_password=$(gpg --decrypt $encrypted_password 2>/dev/null)
    
    # Run the remote script
    ssh -tt "$remote_host" "echo $decrypted_password | sudo -S -v && sudo ~/$project_name/$archive_name/$remote_script"
}