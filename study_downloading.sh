#!/usr/bin/bash
#SBATCH --job-name=${SLURMJOB_ID}Mass_study_downloading
#SBATCH --output=mass_downloading.out
#SBATCH -error=SRA_downloading_test.error
#SBATCH --mail-user=jobrien20@qub.ac.uk
#SBATCH --mail-type=FAIL
#SBATCH --partition=k2-medpri
#SBATCH --time=24:00:00
#SBATCH --ntasks=16

# THIS SCRIPT HAS SLURM COMMANDS ADDED.
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
	echo "Heey" $is_data
	if [[ ${is_data} == "Data" ]]                                               # Checks each respective column to find one that is titles "Data"
	then
		sed -i 1d ${Output_dir}/Files_by_database/${2}project_datas.txt
		field_count=0
	else
		echo "Fail" > fail.txt
		rm ${Output_dir}/Files_by_database/${2}project_datas.txt
	fi

done

}

# Running of this
extracting_data_list_func ${Output_dir}/Files_by_database/end_studies.txt end_studies
extracting_data_list_func ${Output_dir}/Files_by_database/ncbi_studies.txt ncbi_studies
cp ${Output_dir}/Files_by_databse/ncbi_studiesproject_datas.txt pj.txt
# Removes any speech marks from this column
cat ${Output_dir}/Files_by_database/ncbi_studiesproject_datas.txt | tr -d '"' > ${Output_dir}/Files_by_database/ncbi_studiesproject_datas2.txt
cat ${Output_dir}/Files_by_database/end_studiesproject_datas.txt | tr -d '"' > ${Output_dir}/Files_by_database/end_studiesproject_datas2.txt



# Loop for NCBI database. 
while read study
do
	echo ${study} > ${Output_dir}/temp_folder/project_in_q.txt
	head -n1 ${Output_dir}/temp_folder/project_in_q.txt | tr -d ' ' | tr 'and' '\n' > ${Output_dir}/temp_folder/project_in_q.txt
	proj_count=$(wc -l > ${Output_dir}/temp_folder/project_in_q.txt)
	mkdir ${Output_dir}/${study}
	if [[ $proj_count == 2 ]]     # Some studies have two project accessions. This checks for that.
	then
		proj_1=$(sed -i 1p ${Output_dir}/temp_folder/project_in_q.txt)
		proj_2=$(sed -i 2p ${Output_dir}/temp_folder/project_in_q.txt)
		srun --input none ncbi_script.sh ${proj_1} ${Output_dir}/${study}     # Running of ncbi_script.sh containing sra extraction and fasterq-dump
		srun --input none ncbi_script.sh ${proj_2} ${Output_dir}/${study}  
	else	
		srun --input none ncbi_script.sh ${study} ${Output_dir}/${study}
	fi
	grep ${study} ${1} > ${Output_dir}/temp_folder/study.txt
	
	for (( x = 1 ; x <= ${field_count2} ; x += 1 ))
	do
		cut -d ',' -f ${x} ${Output_dir}/temp_folder/study.txt >> ${Output_dir}/${study}/readme.txt    # Generation of readme based on initial table
	done

done < ${Output_dir}/Files_by_database/ncbi_studiesproject_datas2.txt


# Lopo for ena database, follows same general principle.
while read study
do
	echo ${study} > ${Output_dir}/temp_folder/project_in_q.txt
	head -n1 ${Output_dir}/temp_folder/project_in_q.txt | tr -d ' ' | tr 'and' '\n' > ${Output_dir}/temp_folder/project_in_q.txt
	proj_count=$(wc -l > ${Output_dir}/temp_folder/project_in_q.txt)
	mkdir ${Output_dir}/${study}
	if [[ ${proj_count} == 2 ]]
	then
		proj_1=$(sed -i 1p ${Output_dir}/temp_folder/project_in_q.txt)
		proj_2=$(sed -i 2p ${Output_dir}/temp_folder/project_in_q.txt)


		srun --input none emd_script.sh ${proj_1} ${Output_dir}                 #This script is the only difference. 
		srun --input none emd_script.sh ${proj_2} ${Output_dir}
	else	
		srun --input none emd_script.sh ${study} ${Output_dir}
	fi	
	grep ${study} ${1} > ${Output_dir}/temp_folder/study.txt
	
	for (( x = 1 ; x <= ${field_count2} ; x += 1 ))
	do	
		cut -d ',' -f${x} ${Output_dir}/temp_folder/study.txt > ${Output_dir}/${study}/readme.txt

	done

done < ${Output_dir}/Files_by_database/end_studiesproject_datas2.txt
