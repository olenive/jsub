#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
$jsub --generate-summaries --generate-jobs \
     --protocol echo06.protocol \
     --vars vars06.vars \
     --fvars fvars06.fvars \
     --header-from-file "../my_job_header.txt" \
     --summary-prefix "summaries/" \
     --job-prefix "jobs/" \
     --prefix-lsf-out "lsf_out/" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/" 

$jsub --submit-jobs --list-jobs jobs/echo06_vars06_fvars06.list-jobs
