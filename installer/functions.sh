#!/bin/bash

# Function to check if a file or folder is in the exclude list
is_excluded() {
    local file_or_folder="$1"

    for excluded_item in "${exclude_array[@]}"; do
        if [[ "$file_or_folder" == *"$excluded_item"* ]]; then
            return 0 # Excluded
        fi
    done

    return 1 # Not excluded
}

# Function to process files and folders recursively
process_files() {
    local current_directory="$1"

    for item in "$current_directory"/*; do
        if [ -d "$item" ]; then
            # It's a directory, recurse into it
            process_files "$item"
        elif [ -f "$item" ]; then
            # It's a file, check if it should be excluded
            if is_excluded "$item"; then
                echo "Excluded file: $item"
            else
                # Add the file to the output variable
                output_files+="$item"$'\n'
            fi
        fi
    done
}
