#!/bin/bash

# Create dummy test files for each row in input file.

## INPUTS ##
LIST_SAMPLES="$1"
############

## SCRIPT ##
# Create dummy test files.
lnum=0
while read -r line || [[ -n "$line" ]]; do
  lnum=$((lnum+1))
  FILE_NAME="dummy_""$line"".txt"
  echo "# Dummy data for sample ID: ""$line" > "$FILE_NAME"
  echo "$lnum" >> "$FILE_NAME"
  echo ""  >> "$FILE_NAME"
done < "$LIST_SAMPLES"
