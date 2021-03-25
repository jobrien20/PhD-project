#!/usr/bin/bash
#SBATCH --job-name=${SLURMJOB_ID}Sra_download
#SBATCH --output=fastqc.out
#SBATCH --error=fastqc.error
#SBATCH --mail-user=jobrien20@qub.ac.uk
#SBATCH --mail-type=FAIL
#SBATCH --partition=k2-hipri

. /opt/gridware/depots/54e7fb3c/el7/pkg/apps/anaconda3/5.2.0/bin/etc/profile.d/conda.sh                                                                                     
conda activate 16s      

#For gzipping fastq files. Provide a directory and it will search the directory and the directories within for fastq files to gzip. 
Output_dir=${1}
number_of_dir_fin_runs=0 #for keeping track of which function loop
# Production of necessary folders for output

mkdir ${Output_dir}/gunzip
mkdir ${Output_dir}/gunzip/temp
# Function which gunzips gz files. Recursive function, repeats itself if it finds a directory and searches that for fastqs to gunzip.
function directory_finder {
number_of_dir_fin_runs=$((number_of_dir_fin_runs+1)) # Counter outside function needed 

ls ${1} > ${Output_dir}/gunzip/temp/${number_of_dir_fin_runs}directory_files.txt 

gunzip_count=0 # Starting count for gunzip
while read file
do	
	
	
	if [[ -d ${1}/${file} ]] && [[ ${1}/${file} != ${1}/mergedfastqs ]]
	then
		directory_finder ${1}/${file} #For if it is a directory
	else
		echo $file > file.txt				#For if it is a fastq
		y=$(sed 's/.fastq.gz//g' file.txt)
		x=$(sed 's/.fastq//g' file.txt)		
		if [[ $x != $file ]] && [[ $y == $file ]]
		then
		
			gzip ${1}/${file}
			gunzip_count=$((gunzip_count+1))
		
		fi	
	fi


done < ${Output_dir}/gunzip/temp/${number_of_dir_fin_runs}directory_files.txt
}

# Runs the function

directory_finder ${Output_dir}

