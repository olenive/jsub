This directory contains integration tests for jsub.jl
Command to run all tests: bash run_all_integration_tests.sh <path to a local common header>
Where <path to a local common header> is a path to a file containing LSF options required to run jobs on the local cluster.  These may inclide grant codes, queuing options or any other #BSUB commands needed to successfully submit and run jobs.
This file is not essential to run the tests but some tests will fail if jobs can not be submittied to the LSF queuing system.

Test scripts found in subdirectories may also be run indivdually but may also require a file containing the LSF options for the system on which the tests are being run.