#!/bin/bash

if [ -z "$1" ]; then
    echo "Please specify an archive name."
    echo "Usage: ./release.sh <archive name> <version>"
    exit 1
fi
if [ -z "$2" ]; then
    echo "Please specify a version number."
    echo "Usage: ./release.sh <archive name> <version>"
    exit 1
fi

prefix="$1"
outfile="$PWD/$1_$2.zip"
temp_dir="$PWD/release_temp"
temp_zip="$PWD/temp.zip"

rm -rf "$temp_zip"
rm -rf "$temp_dir"
mkdir -p "$temp_dir"

git archive --format=zip --prefix "$prefix/" HEAD > "$temp_zip" && unzip "$temp_zip" -d "$temp_dir" && rm -rf "$temp_zip"
git submodule foreach --recursive " git archive --format=zip --prefix=\"$prefix/\$sm_path/\" HEAD > \"$temp_zip\" && unzip \"$temp_zip\" -d \"$temp_dir\" && rm -rf \"$temp_zip\" "

rm -rf "$outfile"
7z a "$outfile" "$temp_dir/$prefix"

# cleanup
rm -rf "$temp_zip"
rm -rf "$temp_dir"