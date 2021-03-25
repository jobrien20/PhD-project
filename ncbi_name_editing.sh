#!/usr/bin/bash
#SBATCH --error=name.error
set -uex

Output_dir=${1}
Study_name=${2}
if [[ ! -d ${Output_dir}/temp_name_finder_folder ]]
then
	mkdir ${Output_dir}/temp_name_finder_folder
fi

# Obtains the SRR file (10, but as a website link) and the sample name (12)
ls ${1}/*metadata.txt > ${Output_dir}/temp_name_finder_folder/SRRchecker.txt
# Checks for whether there are multiple SRRmetadatas, in situations where two ncbi projects.
s=$(cat ${Output_dir}/temp_name_finder_folder/SRRchecker.txt | wc -l)
f=${1}/*metadata.txt
if [[ ${s} -ge 2 ]]
	then
		for m in $f
		do
 			cat ${m} >> ${Output_dir}/SRRmetadata.txt
		done
fi

#Takes the sample name from the metadata 
cut -d ',' -f10-12 ${Output_dir}/SRRmetadata.txt > ${Output_dir}/temp_name_finder_folder/newtable.txt


# Generates list of files to test
ls ${Output_dir} > ${Output_dir}/temp_name_finder_folder/list.txt
while read file
do
	paired1=false
	paired2=false
	echo ${file} > ${Output_dir}/temp_name_finder_folder/file.txt
	rem=$(sed 's/.fastq//g' ${Output_dir}/temp_name_finder_folder/file.txt)
	echo $rem > ${Output_dir}/temp_name_finder_folder/rem.txt 
	if [[ ${file} != ${rem} ]]
	then
		pairedquestion=$(sed 's/_1//g' ${Output_dir}/temp_name_finder_folder/rem.txt)
		pairedquestion2=$(sed 's/_2//g' ${Output_dir}/temp_name_finder_folder/rem.txt)
		size_of_1=${#pairedquestion}
		size_of_2=${#pairedquestion2}
		size_of_rem=${#rem}
		if [[ ${size_of_rem} != ${size_of_1} ]] || [[ ${size_of_rem} != ${size_of_2} ]]
		then
			if [[ ${size_of_1} -le ${size_of_2} ]]
			then
				rem=${pairedquestion}
				paired1=true
			else
				rem=${pairedquestion2}
				paired2=true
			fi
		fi

		grep ${rem} ${Output_dir}/temp_name_finder_folder/newtable.txt > ${Output_dir}/temp_name_finder_folder/name.txt
		
		new_name=$(cut -d ',' -f3 ${Output_dir}/temp_name_finder_folder/name.txt)
		if [[ ${new_name} == "" ]]     # FOR CASES IN WHICH THERE IS NO NAME PROVIDED BY STUDY.
		then
			break
		elif [[ ${paired1} = true ]]
		then
			mv ${Output_dir}/${rem}_1.fastq ${Output_dir}/${new_name}_1.fastq
			paired1=false
		elif ${paired2} = true ]]
		then
			mv ${Output_dir}/${rem}_2.fastq ${Output_dir}/${new_name}_2.fastq
			paired2=false
		else
			mv ${Output_dir}/${rem}.fastq ${Output_dir}/${new_name}.fastq
		fi
	
	rm ${Output_dir}/temp_name_finder_folder/name.txt
	fi

done < ${Output_dir}/temp_name_finder_folder/list.txt

rm -r ${Output_dir}/temp_name_finder_folder

