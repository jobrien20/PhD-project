#!/usr/bin/bash

#Script is given a study
# Script needs to
# Download SRA files and FastQ files
# Obtain metadata for these files
# Verify success

Input_study=${1}
Output_folder=${2}

esearch -db sra -query ${Input_study} | efetch --format runinfo | cut -d ',' -f 1 | grep SRR > ${Output_folder}/SRRlist.txt
esearch -db sra -query ${Input_study} | efetch --format runinfo > ${Output_folder}/SRRmetadata.txt


while read -u3 SRR
do

	fasterq-dump --include-technical -e 12 --outdir ${Output_folder} ${SRR}


done 3< ${Output_folder}/SRRlist.txt

