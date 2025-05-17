#!/bin/bash
set -euo pipefail

if [ ! -f DOJO_VERSION ]; then
    echo "DOJO_VERSION file does not exist"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "No arguments supplied"
    exit 1
fi

prev_version=$(<DOJO_VERSION)
next_version=$1

# Check that git commit is empty
#if ! git diff-index --quiet HEAD --; then
#    echo "There are uncommitted changes. Please commit or stash them before running this script."
#    exit 1
#fi


# Remove lockfile
rm -f contracts/Scarb.lock
rm -f pixelaw_testing/Scarb.lock

# Find all files containing the previous version
mapfile -t files < <(git grep -rl -- "$prev_version")

for file in "${files[@]}"; do
    echo "Processing file: $file"
    tmp_file=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" == *"$prev_version"* ]]; then
            echo "Found in $file:"
            echo "$line"
            # Ensure prompt reads from terminal and default to 'Y'
            read -r -p "Replace in $file? [Y/n]: " answer </dev/tty
            answer=${answer:-Y}
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                replaced_line="${line//"$prev_version"/"$next_version"}"
                echo "$replaced_line" >> "$tmp_file"
            else
                echo "$line" >> "$tmp_file"
            fi
        else
            echo "$line" >> "$tmp_file"
        fi
    done < "$file"
    mv "$tmp_file" "$file"
done

echo "$next_version" > DOJO_VERSION

# Install the new dojo
asdf install dojo "$next_version"

# Rebuild
cd contracts
sozo build

# git commands
git commit -am "Bump dojo to v$next_version"

echo "Done, don't forget to push!"
