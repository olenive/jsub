#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
$jsub --protocol echo03.protocol \
     --header-from-file "../my_job_header.txt" \
     --vars vars02.vars \
     --fvars fvars03.fvars
