#!/usr/bin/bash

#Script is given a study
# Script needs to
# Download FastQ files
# Obtain metadata for these files
# Verify success

Input_study=${1}
Output_folder=${2}

enaGroupGet -m -d ${Output_folder} -f fastq ${Input_study}
