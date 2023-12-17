#!/bin/bash
set -euxo pipefail

if [ ! -f VERSION ]; then
    echo "VERSION file does not exist"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "No arguments supplied"
    exit 1
fi

prev_version=$(cat VERSION)
next_version=$1

find . -type f -name "*.toml" -exec sed -i'' -e "s/version = \"$prev_version\"/version = \"$next_version\"/g" {} \;
find . -type f -name "Makefile" -exec sed -i'' -e "s/CORE_VERSION = $prev_version/CORE_VERSION = $next_version/g" {} \;
find . -type f -name "package.json" -exec sed -i'' -e "s/\"version\": \"$prev_version\"/\"version\": \"$next_version\"/g" {} \;
find . -type f -name "Chart.yaml" -exec sed -i'' -e "s/appVersion: \"$prev_version\"/appVersion: \"$next_version\"/g" {} \;

echo $1 > VERSION

# Uncommented git commands
git commit -am "Prepare v$1"
git tag -a "v$1" -m "Version $1"

