# This mock job file is used for the unit test that asserts if initialise_job writes to a *.incomplete file as expected

initialise_job
#JSUB<begin-job>
# "Test line 1"
# "Test line 2"
#JSUB<finish-job>
# process_job (not called here because this test simulates a job that crashed or was terminated before the end)

# EOF
