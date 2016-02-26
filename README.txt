This tool, jsub, is intended as way of systematically running jobs on an lsf cluster.

Features:
- Automated logging of input and output commands.
- Automated generation of job files from protocol files.  The protocol file looks like a bash command but may contain variables which jsub will expand when generating the actual job file.
- Ability to resume from the last point of failiure in a given protocol without the need for a new protocol or re-running all of the original protocol.


