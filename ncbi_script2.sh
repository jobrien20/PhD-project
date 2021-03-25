#!/usr/bin/bash

#Script is given a study
# Script needs to
# Download SRA files and FastQ files
# Obtain metadata for these files
# Verify success
# Might be worth adding something in to stop the fasterq dump generation files being in the home directory temp
Input_study=${1}
Output_folder=${2}

esearch -db sra -api_key ac849254b88c5e657c4a8a1abf85e975e408  -query ${Input_study} | efetch -api_key ac849254b88c5e657c4a8a1abf85e975e408 --format runinfo | cut -d ',' -f 1 | grep SRR > ${Output_folder}/${Input_study}SRRlist.txt
esearch -db sra -api_key ac849254b88c5e657c4a8a1abf85e975e408 -query ${Input_study} | efetch -api_key ac849254b88c5e657c4a8a1abf85e975e408 --format runinfo > ${Output_folder}/${Input_study}SRRmetadata.txt


cat ${Output_folder}/${Input_study}SRRlist.txt | xargs fasterq-dump --include-technical -e 16 --outdir ${Output_folder}
