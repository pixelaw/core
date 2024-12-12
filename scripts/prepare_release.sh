#!/bin/bash
set -euo pipefail

if [ ! -f VERSION ]; then
    echo "VERSION file does not exist"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "No arguments supplied"
    exit 1
fi

# Check that git commit is empty
if ! git diff-index --quiet HEAD --; then
    echo "There are uncommitted changes. Please commit or stash them before running this script."
    exit 1
fi


prev_version=$(cat VERSION)
next_version=$1

find . -type f -name "*.toml" -exec sed -i'' -e "s/version = \"$prev_version\"/version = \"$next_version\"/g" {} \;

echo $1 > VERSION

# git commands
git commit -am "Prepare v$1"
git tag -a "v$1" -m "Version $1"

echo "Done, don't forget to push!"
