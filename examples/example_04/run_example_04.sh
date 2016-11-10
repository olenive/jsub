#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
$jsub --protocol echo03.protocol \
     --header-from-file "../my_job_header.txt" \
     --vars vars02.vars \
     --fvars fvars03.fvars \
     --summary-prefix "summaries/sumpre_" \
     --job-prefix "jobs/jobpre_" \
     --prefix-lsf-out "lsf_out/lsf_" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/"
