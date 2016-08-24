To run this integration test:

bash it_basic.sh <path to a text file containing header>

The argument to the script is optional but may be required by your queuing system.  It consists of a path to a file containing text that will be included in every job file via jsub's --common-header (-c) option.

