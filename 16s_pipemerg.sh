#!/usr/bin/bash
#SBATCH --error=16s_pipe.error
#SBATCH --ntasks-per-node=20
# Generate list of studies based on input directory
# NEEDS not gunzipped fastqs!!!
Input_dir=$1
# Activates conda for pipeline
. /opt/gridware/depots/54e7fb3c/el7/pkg/apps/anaconda3/5.2.0/bin/etc/profile.d/conda.sh

conda activate 16s_pipe

# Generation of folder for pipeline stuff

mkdir ${Input_dir}/pipeline_folder

# Lists every file in input directory
ls ${Input_dir} > ${Input_dir}/pipeline_folder/list_of_files.txt


# Checking for directory and whether it is a fastq directory
while read dirornot
do
	fastq_count=0
	if [[ -d ${Input_dir}/${dirornot} ]]
	then

			ls ${Input_dir}/${dirornot} > ${Input_dir}/pipeline_folder/directorycheck.txt
			fastq_count=0
			while read file2
			do
				echo ${file2} > ${Input_dir}/pipeline_folder/isfastqornot.txt
				seded=$(sed 's/.fastq//g' ${Input_dir}/pipeline_folder/isfastqornot.txt)
				if [[ ${file2} != ${seded} ]]
				then
					
					fastq_count=$((fastq_count+1))
					
				fi
			
			done < ${Input_dir}/pipeline_folder/directorycheck.txt
	fi
	if [ ${fastq_count} -ge 1 ]  # If directory contains at least one fastq file
	then
		echo ${dirornot} >> ${Input_dir}/pipeline_folder/list_of_studys.txt     # This creates a list of study directories
		echo "${dironot},${fastq_count}" >> ${Input_dir}/pipeline_folder/study_pipe_information_fastqs   # Lists number of files in each directory
	fi
done < ${Input_dir}/pipeline_folder/list_of_files.txt
# Conversion of study list to array.


readarray -t study_array < ${Input_dir}/pipeline_folder/list_of_studys.txt


#fastQC + multiQC first
# Generation of directories
mkdir ${Input_dir}/Initial_QC_results
mkdir ${Input_dir}/Initial_QC_results/specific_study_qc_info_tables
mkdir ${Input_dir}/Initial_QC_results/multiqc
mkdir ${Input_dir}/Initial_QC_results/fastqc


# for the information obtaining. Runs fastqc/multiqc script for visualisation as well as python script to get some extra info

echo -e "Study\tMedian reads\tMedian sequence length\tPhred Score Range\tMedian Phred Score" > ${Input_dir}/Initial_QC_results/QCinfo_summary.txt
for study in "${study_array[@]}"
do

	srun fastqcanal_test.sh ${Input_dir}/${study}  # Runs fastQC and multiQC for visualisation
	mkdir ${Input_dir}/Initial_QC_results/fastqc/${study}
	mkdir ${Input_dir}/Initial_QC_results/multiqc/${study}
	mv ${Input_dir}/${study}/fastqc_results/* ${Input_dir}/Initial_QC_results/fastqc/${study}
	mv ${Input_dir}/${study}/multiqc_results/* ${Input_dir}/Initial_QC_results/multiqc/${study}
	
	# Running of python script to get extra fastq information about reads

	srun fastq_median.py ${Input_dir}/${study}      # Python script obtaining extra info: median, total reads etc
	head -n1 ${Input_dir}/${study}/study_qual_info.txt >> ${Input_dir}/Initial_QC_results/QCinfo_summary.txt
	echo -e "\n" >> ${Input_dir}/Initial_QC_results/QCinfo_summary.txt
	mv ${Input_dir}/${study}/qual_info.txt ${Input_dir}/Initial_QC_results/specific_study_qc_info_tables/${study}qual_info.txt

done
# Removes empty lines from QC info document produced by fastq_median.py
 
sed -i '/^$/d' ${Input_dir}/Initial_QC_results/QCinfo_summary.txt 

#Merging

#Testing for paired end
mkdir ${Input_dir}/Merged_QC_results
mkdir ${Input_dir}/mergedreads
${Input_dir}/Merged_QC_results/specific_study_qc_info_tables
for study in "${study_array[@]}"
do
	#Checking for paired
	ls ${Input_dir}/${study} > ${Input_dir}/pipeline_folder/mergecheck.txt
	check=$(head -n1 ${Input_dir}/pipeline_folder/mergecheck.txt)
	check_paired=$(head -n1 ${Input_dir}/pipeline_folder/mergecheck.txt | sed 's/_1.fastq.gz//g') 
	if [[ $check != $check_paired ]]
	# Merging files
		srun ngmerge5.sh ${Input_dir}/${study}
		mkdir ${Input_dir}/mergedreads/${study}
		mv ${Input_dir}/${study}/mergedfastqs5/*.fastq ${Input_dir}/mergedreads/${study}
	# Rechecking for QC
		srun fastqcanal_test.sh ${Input_dir}/mergedreads/${study}
		mkdir ${Input_dir}/Merged_QC_results/${study}
		mv ${Input_dir}/mergedreads/${study}/fastqc_results ${Input_dir}/Merged_QC_results/${study}
		mkdir ${Input_dir}/mergedreads/${study}/multiqc_results ${Input_dir}/Merged_QC_results/${study}
		srun fastq_median.py ${Input_dir}/mergedreads/${study}
		head -n1 ${Input_dir}/${study}/study_qual_info.txt >> ${Input_dir}/Initial_QC_results/QCinfo_summary.txt 
done
# Removal of low amount reads and trimming
mkdir ${Input_dir}/trimmedreads
for study in "${study_array[@]}"
do
	srun low_read.sh ${Input_dir}/Initial_QC_results/specific_study_qc_info_tables/${study}qual_info.txt ${Input_dir}/${study}    # low read removal script
	readarray -t specific_study_array < ${Input_dir}/${study}/sample_names.txt
	mkdir ${Input_dir}/trimmedreads/${study}
	for sample in "${specific_study_array[@]}"
	do
	# Running of trimmomatic to remove low read length and phred score of less than 30 
		trimmomatic SE ${Input_dir}/${study}/${sample} ${Input_dir}/trimmedreads/${study}/trimmed${sample} MINLEN:175 AVGQUAL:30
	done
	unset specific_study_array
done

# Final QC analysis
mkdir ${Input_dir}/Trimmed_QC_results ${Input_dir}/Trimmed_QC_results/fastqc ${Input_dir}/Trimmed_QC_results/multiqc
echo -e "Study\tMedian reads\tMedian sequence length\tPhred Score Range\tMedian Phred Score" > ${Input_dir}/Trimmed_QC_results/QCinfo_summary.txt 
for study in "${study_array[@]}"
do
	# Running of fastQC and multiQC
	srun fastqcanal_test.sh ${Input_dir}/trimmedreads/${study}
	mkdir ${Input_dir}/Trimmed_QC_results/fastqc/${study}
	mkdir ${Input_dir}/Trimmed_QC_results/multiqc/${study}
	# Moving of files generated from above script
	mv ${Input_dir}/trimmedreads/${study}/multiqc_results/* ${Input_dir}/Trimmed_QC_results/multiqc/${study}
	mv ${Input_dir}/trimmedreads/${study}/fastqc_results/* ${Input_dir}/Trimmed_QC_results/fastqc/${study}
	rm ${Input_dir}/trimmedreads/${study}/multiqc_results ${Input_dir}/trimmedreads/${study}/fastqc_results
	# Running python script to get extra QC info
	
	srun fastq_median.py ${Input_dir}/trimmedreads/${study}
	head -n1 ${Input_dir}/trimmedreads/${study}/study_qual_info.txt >> ${Input_dir}/Trimmed_QC_results/QCinfo_summary.txt
	echo -e "\n" >> ${Input_dir}/Trimmed_QC_results/QCinfo_summary.txt
	mv ${Input_dir}/trimmedreads/${study}/qual_info.txt ${Input_dir}/Trimmed_QC_results/specific_study_qc_info_tables/${study}qual_info.txt


done

sed -i '/^$/d' ${Input_dir}/Trimmed_QC_results/QCinfo_summary.txt 
# Bracken/kraken
# First generation of ideal read length for bracken by looking at median read lengths of trimmed studies and picking the lowest

cut -f4 ${Input_dir}/Trimmed_QC_results/QCinfo_summary.txt > ${Input_dir}/pipeline_folder/study_medians.txt
sed -i 1d ${Input_dir}/pipeline_folder/study_medians.txt

readarray -t study_medians_array < ${Input_dir}/pipeline_folder/study_medians.txt
lowest_med=${study_medians_array[0]}
for median in "${study_medians_array[@]}"
do
	if [ ${lowest_med} -gt ${median} ]
	then
		lowest_med=${median}     #this is the lowest median found after comparing studies
	fi
done
echo ${lowest_med} > lowest_median.txt
  
# Bracken/Kraken library construction
# Issue to be resolved: this takes 132 version silva library and not 138 version

kraken2-build --db ${Input_dir}/silva_krakbrak_database --threads 10 --special silva 

bracken-build -d ${Input_dir}/silva_krakbrak_database -t 10 -k 31 -l ${lowest_med}

mkdir ${Input_dir}/kraken_results ${Input_dir}/bracken_results ${Input_dir}/bracken_results/Genera ${Input_dir}/bracken_results/Species


for study in "${study_array[@]}"

do
	ls ${Input_dir}/trimmedreads/${study} > ${Input_dir}/pipeline_folder/trimmed_fastq_list.txt	
	readarray -t trimmed_study_array < ${Input_dir}/pipeline_folder/trimmed_fastq_list.txt
	mkdir ${Input_dir}/kraken_results/${study} ${Input_dir}/bracken_results/Genera/${study} ${Input_dir}/bracken_results/Species/${study}
	
	for sample in "${trimmed_study_array[@]}"
	do	
		# Running of kraken to determine taxonomy of reads
		
		kraken2 --db=${Input_dir}/silva_krakbrak_database --threads 10 --report ${Input_dir}/kraken_results/${study}/${sample}.kreport2 \
		${Input_dir}/trimmedreads/${study}/${sample} \
		> ${Input_dir}/${kraken_results}/${study}/${sample}kraken.kraken2
		
		# Running of bracken at a genera level to estimate taxonomy abundance
		
		bracken -d ${Input_dir}/silva_krakbrak_database -i ${Input_dir}/kraken_results/${study}/${sample}.kreport2 \
		-o ${Input_dir}/bracken_results/Genera/${study}/${sample}.bracken \
		-r ${lowest_med} -l 'G' -t 10
		
		# Running of bracken at a species level to estimate taxonomy abundance

		bracken -d ${Input_dir}/silva_krakbrak_database -i ${Input_dir}/kraken_results/${study}/${sample}.kreport2 \
		-o ${Input_dir}/bracken_results/Species/${study}/${sample}.bracken \
		-r ${lowest_med} -t 10
	
	done
done
