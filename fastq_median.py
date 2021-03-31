#!/usr/bin/env python

import os
import sys
# Median function generation
# Provide an ordered list of integers to it
def median_calc(a):
	sorted_a = sorted(a)    #Sorts file
	is_total = len(sorted_a) / 2
	odd_or_even = isinstance(is_total, int)   #Checks if dividing by 2 is an integer, so if its odd or a median value
	if odd_or_even == True: # Calculates median assuming there is no 'exact' middle (when the list has an even number length)
		lower_med = is_total
		higher_med = is_total + 1
		sum_med = sorted_a[higher_med] - sorted_a[lower_med]
		median = sorted_a[lower_med] + sum_med

	if odd_or_even == False:   # For an odd middle value, adds 0.5 and we get the 'middle' value
		print(is_total)
		odd = int(is_total + 0.5)  # Add 0.5
		median = sorted_a[odd]

	return median

# Generation of list of fastq files
# First argument is the directory (where the specific study is stored)
directory=str(sys.argv[1])
list_of_files=os.listdir(sys.argv[1])
fastq_substring=".fastq"
# Creation of necessary lists for code to work
file_and_locat_list=[]
fastq_file_list=[]
median_sequence_list=[]
lowest_lp_list=[]
highest_hp_list=[]
median_phred_list=[]
number_of_seq_list=[]
# Creates the final file with summary info
Total_file_place=directory + "/" + "study_qual_info.txt"

# Generates list of fastq files found in directory
for file in list_of_files:
	if fastq_substring in file:
		file_and_locat= directory + "/" + file
		file_and_locat_list.append(file_and_locat)
		fastq_file_list.append(file)
# Work out how to extract specific lines containing sequence
for file, fastq in zip(file_and_locat_list, fastq_file_list):
	x = 0
	fastq_list=[]
	number_of_seq = 0
	fastq_len_list=[]
	fastq_phred_list=[]
# Reading of fastq file in question
	with open(file, 'rt') as myfile:
		for myline in myfile:

			split_line = myline.split()
			x = x + 1
			stringed_line=str(split_line)
			corrected_split_line = stringed_line[2:-2]
			if x == 2:
				num = len(corrected_split_line)    #finds length of this line to add to sequences
				fastq_len_list.append(num) 	#Adds length to list
				fastq_list.append(corrected_split_line)
			elif x == 4:                   # 4 means phred score
				fastq_phred_list.append(corrected_split_line)     # Creates phred scores list
				x = 0
				number_of_seq = number_of_seq + 1    # To find number of sequences in sample
# This part generates the number of sequences to a list, so can find out final number of reads
	number_of_seq_list.append(number_of_seq)
# This part generates the median length of sequence
	len(fastq_len_list)
	median_sequence_length = median_calc(fastq_len_list)
	median_sequence_list.append(median_sequence_length)
# Generation of sample phred quality score range
# Phred dictionary table
	phred_dict= {r"!" : 0, r'"' : 1, r'#' : 2, r"$" : 3, r"%" : 4, "&" : 5, 
				r"'" : 6, r"(" : 7, r")" : 8, r"*" : 9 , r"+" : 10, r"," : 11,
				r"-" : 12, r"." : 13, r"/" : 14, r"0" : 15, r"1" : 16, r"2" : 17,
				r"3" : 18, r"4" : 19, r"5" : 20, r"6" : 21, r"7" : 22, r"8" : 23,
				r"9" : 24, r":" : 25, r";" : 26, r"<" : 27, r"=" : 28, r">" : 29,
				r"?" : 30, r"@" : 31, r"A" : 32, r"B" : 33, r"C" : 34, r"D" : 35,
				r"E" : 36, r"F" : 37, r"G" : 38, r"H" : 39, r"I" : 40, r"J" : 41,
				r'K' : 42 }

# Need to take the phred list and make list out of each phred score list

	len_of_phred_list=len(fastq_phred_list)
	specific_phred_list=[]
	fastq_phred_hp_score_list=[]
	fastq_phred_lp_score_list=[]
	median_phred_score_list=[]
# This part runs each sequence to identify the highest phred in each sequence, as well as the lowest phred in each sequence. 
	for phred_seq in fastq_phred_list:
		print(phred_seq)
		seq_in_q=str(phred_seq)
		for letter in phred_seq:
			specific_phred_list.append(phred_dict[letter])
			median_phred_score_list.append(phred_dict[letter])  # This will be used later for median phred score for study
		highest_p_score=specific_phred_list[0]
		lowest_p_score=specific_phred_list[0]
		for item in specific_phred_list:
			if item > highest_p_score:
				highest_p_score = item
			elif item < lowest_p_score:
				lowest_p_score = item
		fastq_phred_hp_score_list.append(highest_p_score)
		fastq_phred_lp_score_list.append(lowest_p_score)
		specific_phred_list.clear()

# Runs through each list to definitively find out the lowest and highest q score of all the sequences in study.
	highest_hp=fastq_phred_hp_score_list[0]
	lowest_lp=fastq_phred_lp_score_list[0]
	for item in fastq_phred_hp_score_list:
		if item > highest_hp:
			highest_hp = item
			print(highest_hp)
		if item < lowest_lp:
			lowest_lp = item
			print(lowest_lp)
# So these are the two most important here for phred score
	print("range is between ")
	lowest_lp_list.append(lowest_lp)
	highest_hp_list.append(highest_hp)

#Generation of median phred score
	median_phred_score = median_calc(median_phred_score_list)
	median_phred_list.append(median_phred_score)


# Writing of data from each study to document
	qual_info_locat= directory + "/" + "qual_info.txt"
	Quality_info_file=open(qual_info_locat, "a")
	Quality_info_file.write(fastq)
	Quality_info_file.write("\t")
	Quality_info_file.write(str(number_of_seq))
	Quality_info_file.write("\t")
	Quality_info_file.write(str(median_sequence_length))
	Quality_info_file.write("\t")
	Quality_info_file.write(str(lowest_lp))
	Quality_info_file.write("-")
	Quality_info_file.write(str(highest_hp))
	Quality_info_file.write("\t")
	Quality_info_file.write(str(median_phred_score))
	Quality_info_file.write("\n")
	Quality_info_file.close()

# Takes all the samples from study and generates an overall
median_reads = median_calc(number_of_seq_list)
total_median_length = median_calc(median_sequence_list)
lowest_study_lp = lowest_lp_list[0]
highest_study_hp = highest_hp_list[0]

for p in lowest_lp_list:
	if p < lowest_study_lp:
		lowest_study_lp = p
	
for p in highest_hp_list:	
	if p > highest_study_hp:
		highest_study_hp = p

total_median_phred = median_calc(median_phred_list)

Total_file = open(Total_file_place, "w")
Total_file.write(directory)
Total_file.write("\t")
Total_file.write(str(len(fastq_file_list)))
Total_file.write("\t")
Total_file.write(str(median_reads))
Total_file.write("\t")
Total_file.write(str(total_median_length))
Total_file.write("\t")
Total_file.write(str(lowest_study_lp))
Total_file.write("-")
Total_file.write(str(highest_study_hp))
Total_file.write("\t")
Total_file.write(str(total_median_phred))

