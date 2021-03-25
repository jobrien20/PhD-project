#!/usr/bin/bash

#Script is given a study
# Script needs to
# Download FastQ files
# Obtain metadata for these files
# Verify success
. /opt/gridware/depots/54e7fb3c/el7/pkg/apps/anaconda3/5.2.0/bin/etc/profile.d/conda.sh 
conda activate downloader
Input_study=${1}
Output_folder=${2}

enaGroupGet -m -d ${Output_folder} -f fastq ${Input_study}
