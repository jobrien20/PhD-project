#!/usr/bin/bash
#SBATCH --job-name=${SLURMJOB_ID}Mass_study_downloading
#SBATCH --output=mass_downloading.out
#SBATCH --error=SRA_downloading_test.error
#SBATCH --mail-user=jobrien20@qub.ac.uk
#SBATCH --mail-type=FAIL
#SBATCH --partition=k2-medpri
#SBATCH --ntasks=16

. /opt/gridware/depots/54e7fb3c/el7/pkg/apps/anaconda3/5.2.0/bin/etc/profile.d/conda.sh

conda activate downloader

# Assumes two maximum PRJE/PRJA/NCBI/whatever for each study

# So first input for script is the comma indented table
# Second input for script is output directory

Input_table=${1}
Output_dir=${2}

# Generates required directories
if [[ ! -d ${Output_dir} ]]
then
	mkdir ${Output_dir}
fi

if [[ ! -d ${Output_dir}/temp_folder ]]
then

	mkdir ${Output_dir}/temp_folder

fi

if [[ ! -d ${Output_dir}/Files_by_database ]]
then

	mkdir ${Output_dir}/Files_by_database
fi

# Generation of title to add to each study type list
head -n1 ${Input_table} > ${Output_dir}/temp_folder/titles.txt
head -n1 ${Output_dir}/temp_folder/titles.txt > ${Output_dir}/Files_by_database/end_studies.txt
head -n1 ${Output_dir}/temp_folder/titles.txt > ${Output_dir}/Files_by_database/ncbi_studies.txt
head -n1 ${Output_dir}/temp_folder/titles.txt > ${Output_dir}/Files_by_database/unknown_data.txt

# Copies table onto new 
cp ${Input_table} ${Output_dir}/temp_folder/input_table_cop
sed -i '1d' ${Output_dir}/temp_folder/input_table_cop

# Separates files into each study type
while read input_file
do
	case $input_file in
		*SRP[0-9]*)
			echo ${input_file} >> ${Output_dir}/Files_by_database/ncbi_studies.txt
		;;
		*SRR[0-9]*)
			echo ${input_file} >> ${Output_dir}/Files_by_database/ncbi_studies.txt
		;;
		*PRJNA*)
			echo ${input_file} >> ${Output_dir}/Files_by_database/ncbi_studies.txt
		;;
		*PRJE*)
			echo ${input_file} >> ${Output_dir}/Files_by_database/end_studies.txt
		;;
		*ERP[0-9]*)
			echo ${input_file} >> ${Output_dir}/Files_by_database/end_studies.txt
		;;
		*)
			echo ${input_file} >> ${Output_dir}/Files_by_database/unknown_data.txt
		;;
	esac
done < ${Output_dir}/temp_folder/input_table_cop


# Function to extract just the data from respective study
function extracting_data_list_func {
field=0
field_count=$(head -n1 ${Output_dir}/temp_folder/titles.txt | tr ',' '\n' | wc -l)
field_count2=${field_count}
while [[ $field_count -ne 0 ]]
do

	field_count=$((field_count-1))
	field=$((field+1))

	cut -d ',' -f${field} ${1} > ${Output_dir}/Files_by_database/${2}project_datas.txt
	is_data=$(head -n1 ${Output_dir}/Files_by_database/${2}project_datas.txt)
	if [[ ${is_data} == "Data" ]]
	then
		sed -i 1d ${Output_dir}/Files_by_database/${2}project_datas.txt
		field_count=0
	else

		rm ${Output_dir}/Files_by_database/${2}project_datas.txt

	fi

done

}

# Running of this
extracting_data_list_func ${Output_dir}/Files_by_database/end_studies.txt end_studies
extracting_data_list_func ${Output_dir}/Files_by_database/ncbi_studies.txt ncbi_studies
cat ${Output_dir}/Files_by_database/ncbi_studiesproject_datas.txt | tr -d '"' > ${Output_dir}/Files_by_database/ncbi_studiesproject_datas2.txt
cat ${Output_dir}/Files_by_database/end_studiesproject_datas.txt | tr -d '"' > ${Output_dir}/Files_by_database/end_studiesproject_datas2.txt
. /opt/gridware/depots/54e7fb3c/el7/pkg/apps/anaconda3/5.2.0/bin/etc/profile.d/conda.sh 

conda activate fasterq-dump-env

while read study
do


	ncbi_array+=("${study}")



done < ${Output_dir}/Files_by_database/ncbi_studiesproject_datas2.txt


while read study
do

	
	ena_array+=("${study}")


done < ${Output_dir}/Files_by_database/end_studiesproject_datas2.txt

for study in "${ncbi_array[@]}"  
do
	# Testing if there are two projects in the study
	echo ${study} > ${Output_dir}/temp_folder/project.txt
	head -n1 ${Output_dir}/temp_folder/project.txt | tr -d ' ' | tr 'and' '\n' > ${Output_dir}/temp_folder/project_in_q.txt
	sed -i '2,3d' ${Output_dir}/temp_folder/project_in_q.txt
	proj_count=$(cat ${Output_dir}/temp_folder/project_in_q.txt | wc -l )
	echo ${study} > ${Output_dir}/temp_folder/for_study.txt
	
	# Making name for directory forming

	cat ${Output_dir}/temp_folder/for_study.txt | tr -d ' ' > ${Output_dir}/temp_folder/for_2.txt
	study_val_for_dir=$(cat ${Output_dir}/temp_folder/for_2.txt)
	mkdir ${Output_dir}/${study_val_for_dir}
	
	Running of downloading and fastq converting scripts
	if [[ $proj_count == 2 ]]
	then
		
		proj_1=$(sed -n '1p' ${Output_dir}/temp_folder/project_in_q.txt)
		proj_2=$(sed -n '2p' ${Output_dir}/temp_folder/project_in_q.txt)
		mkdir ${Output_dir}/${proj_1}
		mkdir ${Output_dir}/${proj_2}
		srun --input none ncbi_script2.sh ${proj_1} ${Output_dir}/${proj_1}
		srun --input none ncbi_script2.sh ${proj_2} ${Output_dir}/${proj_2}
		srun ncbi_name_editing.sh ${Output_dir}/${proj_1} ${proj_1}
		srun ncbi_name_editing.sh ${Output_dir}/${proj_2} ${proj_2}
		mv ${Output_dir}/${proj_1}/* ${Output_dir}/${study_val_for_dir}
		mv ${Output_dir}/${proj_2}/* ${Output_dir}/${study_val_for_dir}
		rm -r ${Output_dir}/${proj_1}
		rm -r ${Output_dir}/${proj_2}
		
	else	
		
		srun --input none ncbi_script2.sh ${study} ${Output_dir}/${study_val_for_dir}
		srun ncbi_name_editing.sh ${Output_dir}/${study_val_for_dir} ${study} 
		
	fi
	grep ${study} ${1} > ${Output_dir}/temp_folder/study.txt
	
	for (( x = 1 ; x <= ${field_count2} ; x += 1 ))
	do
		cut -d ',' -f ${x} ${Output_dir}/temp_folder/study.txt >> ${Output_dir}/${study_val_for_dir}/readme.txt
	done

done
conda activate downloader

# Running of array for ena in loop one by one
for study in "${ena_array[@]}"
do
	# Checking project count
	
	echo ${study} > ${Output_dir}/temp_folder/project_in_q.txt
	head -n1 ${Output_dir}/temp_folder/project_in_q.txt | tr -d ' ' | tr 'and' '\n' > ${Output_dir}/temp_folder/project_in_q.txt
	sed -i '2,3d' ${Output_dir}/temp_folder/project_in_q.txt
	proj_count=$(cat ${Output_dir}/temp_folder/project_in_q.txt | wc -l )

	
	if [[ ${proj_count} == 2 ]]
	# For two values
	then
		# Creates variables for each study, then runs them in ena script
		proj_1=$(sed -n '1p' ${Output_dir}/temp_folder/project_in_q.txt)
		proj_2=$(sed -n '2p' ${Output_dir}/temp_folder/project_in_q.txt)
		srun --input none ena_script.sh ${proj_1} ${Output_dir}
		srun --input none ena_script.sh ${proj_2} ${Output_dir}
		
		#Moves the two projects into the same folder so all fastas from one study are together
		
		echo "${study}" > ${Output_dir}/temp_folder/study_val.txt
		study_val=$(cat ${Output_dir}/temp_folder/study_val.txt | tr -d ' ')
		mkdir ${Output_dir}/${study_val}
		mv ${Output_dir}/${proj_1}/* ${Output_dir}/${study_val}
		mv ${Output_dir}/${proj_2}/* ${Output_dir}/${study_val}
		#Generates variable containing all the files
		FILES=${Output_dir}/${study_val}/*
	else
		#Runs for one value. Runs the script then generates variable containing all the files	
		srun --input none ena_script.sh ${study} ${Output_dir}
		FILES=${Output_dir}/${study}/*
	
	fi
	# ENA creates folders for each sample it downloads. This moves the directories contents and deletes them. Standardizes output so there's not a bunch of folders
	for f in ${FILES}
	do	
	if [[ -d ${f} ]]
		then
			mv ${f}/* ${Output_dir}/${study}
			rm -r ${f}
	fi
	
	done	
	# Readme generation. Greps the exact study from the initial table datasets. 
	grep ${study} ${1} > ${Output_dir}/temp_folder/study.txt
	# Loops over each field (title, data etc) so that each is added to the readme. Uses the grep above so that it only uses fields from the exact study 
	for (( x = 1 ; x <= ${field_count2} ; x += 1 ))
	do	
		if [[ -z "${proj_1} ]] && [[ -z "${proj_2} ]]  # Checks if proj_1 or proj_2 variable exist so that it know where exactly to put readme.txt
			then
				cut -d ',' -f${x} ${Output_dir}/temp_folder/study.txt > ${Output_dir}/${study_val}/readme.txt
				srun ERPnamescript.sh ${Output_dir}/${study_val}
		
		else  
				
				cut -d ',' -f${x} ${Output_dir}/temp_folder/study.txt > ${Output_dir}/${study}/readme.txt
				srun ERPnamescript.sh ${Output_dir}/${study}			
		fi
	
	done
	
done
