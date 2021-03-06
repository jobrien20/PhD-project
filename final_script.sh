#!/usr/bin/bash
#SBATCH --job-name=${SLURMJOB_ID}Sra_download
#SBATCH --output=SRA_downloading_test.out
#SBATCH --error=SRA_downloading_test.error
#SBATCH --mail-user=jobrien20@qub.ac.uk
#SBATCH --mail-type=FAIL
#SBATCH --partition=k2-medpri
#SBATCH --time=24:00:00
#SBATCH --ntasks=16


# Script utilises a .txt table with studies and their information to download data from the appropriate database (NCBI SRA or ENA)
# Requires the table to have "Data" as a heading, which contains the SRP, PRJ or ERP accession number
# CREATE AN IF THERE ISNT A CERTAIN TYPE OF DATA
#Adds date and author to readmes
date="24/02/2021"
Author="Jamie OBrien"


Input_file=$1
echo $Input_file
Output_folder=$2
echo $Output_folder
head -n1 ${Input_file} > titles.txt
title=$(head -n1 ${Input_file})
mkdir $Output_folder
mkdir $Output_folder/Original_file
mkdir $Output_folder/Files_by_database
cp $Input_file ${Output_folder}/Original_file/
Orig=${Output_folder}/Original_file/${Input_file}

cp $Input_file projectsinfo.txt
# Removes PNJ and ENP files and saves to new file because this only works for SRP

cat titles.txt > ${Output_folder}/Files_by_database/SRPandPRJ_files.txt
cat titles.txt > ${Output_folder}/Files_by_database/PRJEandERP_files.txt
cat titles.txt > ${Output_folder}/Files_by_database/unknown_database_files.txt
cp $Input_file Input_file_for_use.txt
sed -i 1d Input_file_for_use.txt
line_count=0   #counts which line being tested, gets added every while loop

while read input_file_line
do
	line_count=$((line_count+1))
	case $input_file_line in
	*SRP[0-9]*)
		echo $input_file_line >> ${Output_folder}/Files_by_database/SRPandPRJ_files.txt		
	;;
	*PRJNA*)
		echo $input_file_line >> ${Output_folder}/Files_by_database/SRPandPRJ_files.txt
	;;
	*PRJE*)
		echo $input_file_line >> ${Output_folder}/Files_by_database/PRJEandERP_files.txt
	;;
	*ERP*)
		echo $input_file_line >> ${Output_folder}/Files_by_database/PRJEandERP_files.txt
	;;
	*)
		echo $input_file_line >> ${Output_folder}/unknown_database_files.txt
	;;
	esac
done < Input_file_for_use.txt


  #For cut command for each field Xin input file






echo "empty" > project_datas.txt
# Function searches and extracts data list from the text indented file
function extracting_data_list_func { 
	field=0
	field_count=$(head -1 titles.txt | tr ',' '\n' | wc -l)
	echo $field_count
	sed -i "1s/^/${title}\n/" $1


# while loop searching for Data header

while [[ ${field_count} -ne 0 ]]
# Goes to 0 when Data heading found or ran out of headings to check. When found creates project_datas.txt with them
do
		field_count=$((field_count-1))     #goes down every loop to stop loop when fields read
		field=$((field+1))		#keeps track of loop
		cut -d ',' -f${field} ${1} > project_datas.txt      #generates list to test for Data table
		is_data=$(head -n1 project_datas.txt)  #creates variable 1st line
		echo $is_data
		if [[ ${is_data} == "Data" ]]
			then				# removes first line of file
				echo "Data list found"
			sed -i 1d project_datas.txt
			field_count=0
		else
			rm project_datas.txt
	fi
done
if [[ $field_count -ne 0 ]] # For if there's no Data heading
	then
		echo "No Data found ensure field heading has Data as a heading"

fi
}



# Function for if the research paper has more than one PRJ
function No_of_projects_returner {
echo $1 > no_of_proj.txt
head -n1 no_of_proj.txt | tr -d ' ' | tr 'and' '\n' > number_of_projects.txt
func_project_count=$(wc -l number_of_projects.txt | sed 's/.number_of_projects.txt//g')
echo $func_project_count
}
# Generates readme file
function readme_generator {
grep ${1} ${Input_file} > readmegen.txt
echo "downloaded by " ${Author} ${date} >> $2/${1}readme.txt
field_count=$(head -n1 titles.txt | sed 's/\t/\n/g' | wc -l)
for (( x=1 ; x<= ${field_count} ; x+=1 ))
do
	cut -f{x} readmegen.txt >> ${2}/${1}readme.txt
done

}


#For cases in which the files are empty as in no PRJNA files
extracting_data_list_func ${Output_folder}/Files_by_database/SRPandPRJ_files.txt
sed -i 1d project_datas.txt
x=$(cat project_datas.txt)

if [[ $x != "" ]] && [[ $x != "Data" ]]
then
# Looping of each PRJNA files
while read -u3 study
do
	echo $study
	project_count=$(No_of_projects_returner $study)
	#For if there is more than one SRP project, splits them then runs the process.
	if [[ $project_count -ne 1 ]]
	then
		echo $study > study.txt
		directory_name=$(head -n1 study.txt)
		mkdir ${Output_folder}/${directory_name}
		readme_generator ${study} ${Output_folder}/${directory_name}
		while read indi_study
		do
		#Runs esearch on all of these to generate metadata, fastq gz file and then again to find the fastq files to check how many worked


			mkdir ${Output_folder}/${directory_name}/${indi_study}
			esearch -db sra -query ${indi_study} | efetch --format runinfo | cut -d ',' -f 1 | grep SRR > ${Output_folder}/${directory_name}/${indi_study}/SRRlist.txt
			cp ${Output_folder}/${directory_name}/${indi_study}/SRRlist.txt ${Output_folder}/${directory_name}/${indi_study}/Failed_downloaded_files.txt
			esearch -db sra -query ${indi_study} | efetch --format runinfo > ${Output_folder}/${directory_name}/${indi_study}/SRRmetadata.txt
			readme_generator ${study} ${Output_folder}/${study}
			while read SRR
			do
				fasterq-dump  --include-technical --outdir ${Output_folder}/${directory_name}/${indi_study} ${SRR}
		
				if [[ -e ${Output_folder}/${directory_name}/${indi_study}/${SRR}.fastq.gz ]]
				then
					sed -i "s/${SRR}//g" ${Output_folder}/${directory_name}/${indi_study}/Failed_downloaded_files.txt
				fi
			done < ${Output_folder}/${directory_name}/${indi_study}/Failed_downloaded_files.txt
		done < number_of_projects.txt
	#For if there is one PRJNA file in the study
	else
		mkdir  ${Output_folder}/${study}
		esearch -db sra -query ${study} | efetch --format runinfo | cut -d ',' -f 1 | grep SRR > ${Output_folder}/${study}/SRRlist.txt
		cp ${Output_folder}/${study}/SRRlist.txt ${Output_folder}/${study}/Failed_downloaded_files.txt
		esearch -db sra -query ${study} | efetch --format runinfo > ${Output_folder}/${study}/SRRmetadata.txt
		readme_generator ${study} ${Output_folder}/{study}	
		while read SRR
		do
			fasterq-dump --include-technical --outdir ${Output_folder}/${study} ${SRR}
			if [[ -e ${Output_folder}/${study}/${SRR}.fastq.gz ]]
			then
				sed -i "s/${SRR}//g" ${Output_folder}/${study}/Failed_downloaded_files.txt
			fi	
		done < ${Output_folder}/${study}/Failed_downloaded_files.txt
	

	fi
done 3< project_datas.txt
###ENAGroupGet
fi

if [[ ! -e ${Output_folder}/Files_by_database/PRJEandERP_files.txt ]]
	then
		exit
fi
#Testing PRJE file list for empty
extracting_data_list_func ${Output_folder}/Files_by_database/PRJEandERP_files.txt
sed -i 1d project_datas.txt
x=$(cat project_datas.txt)
#Downloading of PRJE files
if [[ $x != "" ]] && [[ $x != "Data" ]]
then
#For multiple PRJE files in one study
while read -u3 PRJE_study
do
	project_count=$(No_of_projects_returner ${PRJE_study})
	echo $project_count
	if [[ $project_count -ne 1 ]]
		then
			echo $PRJE_study > study.txt
			directory_name=$(head -n1 study.txt)
			mkdir ${Output_folder}/${directory_name}
			while read indi_study
			do
				
				mkdir ${Output_folder}/${directory_name}/${indi_study}
				enaGroupGet -f fastq -d ${Output_folder}/${directory_name}/${indi_study} ${indi_study}
				readme_generator ${indi_study} ${Output_folder}/${directory_name}/${indi_study}

			done < number_of_projects.txt
	else
# For one PRJE file in study
		enaGroupGet -d ${Output_folder}/${PRJE_study}/ -f fastq ${PRJE_study}
		readme_generator ${PRJE_study} ${Output_folder}/${PRJE_study}
	
	fi

done 3< project_datas.txt
fi
