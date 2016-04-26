#!/bin/bash

# Read arguments
arg1="$1"
arg2="$2"
arg3="$3"
arg4="$4"

echo "Pretending to process data for each sample. Output file contains the sample ID followed by the reference file."
echo "Unit test shell script - Running ut_process.sh "
echo "input sample ID: ""$arg1"
echo "input file: ""$arg2"
echo "input list: ""$arg3"
echo "output file: ""$arg4"

echo "Imaginary prcoessing of sample ""$arg1" > ${arg4}
echo "Using list of input data from: ${arg3}" >> ${arg4}
echo "Followd by the reference data: "
cat ${arg4}  ${arg2} > ${arg4}

echo "finished running $0" using inputs "



