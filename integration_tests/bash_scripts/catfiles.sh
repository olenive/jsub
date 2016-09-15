#!/bin/bash
set -e

echo "Running $0"
OUTFILE="$1"
echo "Concatenated file contents produced by $0:" >> "$OUTFILE"
shift

cat $@ >> "$OUTFILE"

# EOF

