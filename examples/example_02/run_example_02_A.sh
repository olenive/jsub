#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
$jsub --protocol echo02.protocol \
     --header-from-file "../my_job_header.txt" \
     --vars vars02_A.vars
