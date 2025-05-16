#!/bin/bash

# Directories to remove
dirs_to_remove=(
    "./cache"
    "./artifacts"
    "./ignition/deployments"
)

# Loop through and remove each directory if it exists
for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        echo "Removing directory: $dir"
        rm -rf "$dir"
    else
        echo "Directory not found: $dir"
    fi
done

echo "Cleanup complete."