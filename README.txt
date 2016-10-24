

For quick reference
Input file formats:

Variables File
The .vars file is a tab delimited file of two columns only.
The left column contains the name of the variable (without a dollar sign) which matches the variable in the .protocol file (including dollar sign).
The right column (everything to the right of the first tab character) is the value of the variable and will be substituted into the protocol file (this can contain spaces tabs and just about anything else but is made with short non-whitespace strings in mind).
# Can contain comment lines starting with "#" or " 	#" but no comments following data in a signle row.

Variables from list file
The .fvars file indicates that the value of a variable should be taken from a list.
This file is tab delimited with exactly three columns: variable name, column in the list file, path to the list file. 
Currently all lists are expected to be the same length with a one-to-one mapping between each row of each list.
# Can contain comment lines starting with "#" or " 	#" but no comments following data in a signle row.

Protocol File
Whitespace delimited file with an arbitrary number of entries in each row.
# Can contain comment lines starting with "#" or " 	#".  Comment lines and comments after data will be inserted into the job file so it is up to the user to maintain syntax that shell can process.  When in doubt do not put comments on the same line as the data (protocol instrucitons).


Outline:


STAGE 1 INPUTS
  
  The following options are used to generate a "process name"
    --protocol "dir/protocolFile"
    --vars     "dir/varsFile"
    --fvars    "dir/fvarsFile"
      OR
    --process-name "processName"
  
  --summary-prefix "dir/sp_"


STAGE 1 OUTPUTS
  
  File listing summary files: "dir/sp_processName.list-summaries"
      
  The *.list-summaries file contains a list of paths:
                      "dir/sp_processName_1.summary"
                      "dir/sp_processName_2.summary"
                      .
                      .
                      .
    OR
    if "#JSUB<summary-name> summaryName" is declared in the protocol file "dir/sp_summaryName.summary"
                      "dir/sp_summaryName_1.summary"
                      "dir/sp_summaryName_2.summary"
                      .
                      .
                      .

STAGE 2 INPUTS

  --list-summaries "dir/sp_processName.list-summaries"

  --job-prefix "dir/jp_"

  Prefixes for *.output, *.error, *.completed and *.incomplete files.

STAGE 2 OUTPUTS

  File listing job files: "dir/jp_sp_processName.list-jobs"

  Paths to job files: 
    "dir/jp_sp_summaryName_1_groupA.lsf"
    "dir/jp_sp_summaryName_1_groupB.lsf"
    ...
    "dir/jp_sp_summaryName_2_groupA.lsf"
    "dir/jp_sp_summaryName_2_groupB.lsf"
    ...
    .
    .
    .

STAGE 3 INPUTS

  --list-jobs "dir/jp_sp_processName.list-jobs"



