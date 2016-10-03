#!/bin/bash
set -e

#echo "Running $0"
OUTFILE="$1"
#echo "Concatenated arguments produced by $0:" >> "$OUTFILE"
shift
OUTSTRING=""
for var in "$@"; do
  [[ "$OUTSTRING" = "" ]] && delim="" || delim="_"
  OUTSTRING="$OUTSTRING""$delim""$var"
done
echo "$OUTSTRING" >> "$OUTFILE"

# EOF

