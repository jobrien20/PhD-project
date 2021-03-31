#!/usr/bin/bash
dir_in_q=${1}
#SBATCH --error=fastqc_analyser.error
#SBATCH --out=fastqc_analyser.out
#SBATCH --ntasks=20 

. /opt/gridware/depots/54e7fb3c/el7/pkg/apps/anaconda3/5.2.0/bin/etc/profile.d/conda.sh
conda activate 16s_pipe
mkdir ${dir_in_q}/fastqc_results

fastqc -t 20 ${dir_in_q}/*.fastq -outdir ${dir_in_q}/fastqc_results


export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8


mkdir $dir_in_q/multiqc
multiqc $dir_in_q -o $dir_in_q/multiqc_results
