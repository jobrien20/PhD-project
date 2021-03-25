#!/usr/bin/bash

#SBATCH --output=namescript.out                                                                                                                                       
#SBATCH --error=namescript.error 

set -uex
# Give output folder and metadata (an xml file)

Output_dir=${1}

mkdir ${Output_dir}/temp_name_finding_folder

#Obtain ERR files in list for metadata and fastq stuff 
ls ${Output_dir} > ${Output_dir}/temp_name_finding_folder/list_of_files.txt

while read file
do
	paired1=false
	paired2=false
	echo ${file} > ${Output_dir}/temp_name_finding_folder/testing.txt
	x=$(sed 's/.fastq.gz//g' ${Output_dir}/temp_name_finding_folder/testing.txt)
	if [[ ${x} != ${file} ]]
	then
		echo ${x} >> ${Output_dir}/original_fastq_names.txt
		# First checks if the data is paired. Through removal of _ which is in paired data.
		pairquestion=$(sed 's/_1.fastq.gz//g' ${Output_dir}/temp_name_finding_folder/testing.txt)
		pairquestion2=$(sed 's/_2.fastq.gz//g' ${Output_dir}/temp_name_finding_folder/testing.txt)

		fastq=${Output_dir}/"${x}".fastq.gz
		size_of_x=${#x}
		size_of_pair1=${#pairquestion}
		size_of_pair2=${#pairquestion2}
		if [[ ${size_of_x} != ${size_of_pair1} ]] || [[ ${size_of_x} != ${size_of_pair2} ]]
		then
			if [[ ${size_of_pair1} -le ${size_of_pair2} ]] # Then checks if its the first or second pair and uses whichever it is as the new x.
			then
				x=${pairquestion}
				paired1=true
			else
				x=${pairquestion2}
				paired2=true
			fi
		fi

		metadata=${Output_dir}/"${x}".xml
		
		#Extract ERX from ERR xml
		cat $metadata > metadatatest.txt
		sed -n '11p' ${metadata} | tr -d ' ' | tr -d '<PRIMARY_ID>/E' > ${Output_dir}/temp_name_finding_folder/ERXextractor.txt
		xno=$(head -n1 ${Output_dir}/temp_name_finding_folder/ERXextractor.txt)
		erx=$(echo "ER${xno}")
		curl "https://www.ebi.ac.uk/ena/browser/api/xml/${erx}?download=true" > ${Output_dir}/temp_name_finding_folder/erx.xml   

		# Extract SAMEA from ERX
		sed -n '20p' ${Output_dir}/temp_name_finding_folder/erx.xml | tr -d ' ' | tr -d '<EXTERNAL_IDnamespace="BioSample">M/' > ${Output_dir}/temp_name_finding_folder/SAMEAextractor.txt
		sameano=$(head -n1 ${Output_dir}/temp_name_finding_folder/SAMEAextractor.txt)
		samea=$(echo "SAMEA${sameano}")
		curl "https://www.ebi.ac.uk/ena/browser/api/xml/${samea}?download=true" > ${Output_dir}/temp_name_finding_folder/samea.xml

		# Extraction of sample name

		sed -n '3p' ${Output_dir}/temp_name_finding_folder/samea.xml > ${Output_dir}/temp_name_finding_folder/aliasextractor.txt 
		cut -d ' ' -f3 ${Output_dir}/temp_name_finding_folder/aliasextractor.txt > ${Output_dir}/temp_name_finding_folder/aliasblock.txt
		sed 's/alias=//' ${Output_dir}/temp_name_finding_folder/aliasblock.txt | tr -d '"' > ${Output_dir}/temp_name_finding_folder/sample_name.txt
		sample_name=$(head -n1 ${Output_dir}/temp_name_finding_folder/sample_name.txt)
		#Rename of file. Based on whether paired or not. value of paired1 and paired2 generated earlier when checking for paired.
		if [[ "${paired1}" = true ]]  
		then
			mv ${fastq} ${Output_dir}/"${sample_name}"_1.fastq.gz
		elif [[ "${paired2}" = true ]]
		then
			mv ${fastq} ${Output_dir}/"${sample_name}"_2.fastq.gz
		else
			mv ${fastq} ${Output_dir}/"${sample_name}".fastq.gz
		fi

		
	
	fi

done < ${Output_dir}/temp_name_finding_folder/list_of_files.txt

