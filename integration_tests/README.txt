This directory contains integration tests for jsub.jl

NOTE: The integration tests will submit jobs to the LSF queue.  Each individual
job should only take a few seconds but the whole process may take several
minutes.

Command to run all tests: bash run_all_integration_tests.sh <path to a local common header>
Where <path to a local common header> is a path to a file containing LSF options required to run jobs on the local cluster.  These may inclide grant codes, queuing options or any other #BSUB commands needed to successfully submit and run jobs.
This file is not essential to run the tests but some tests will fail if jobs can not be submittied to the LSF queue.

