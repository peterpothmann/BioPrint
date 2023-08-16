#!/bin/bash

# length: 57
# sbatch -a 1-1 /gpfs0/home/pothmann/bioprint/03_code/src/00_preprocess_sum_yield_all.sh /data/bioprint/00_data/97_slurm/preprocess-sum-yield-all-slurm.txt


#SBATCH --job-name=00_preprocess_sum_yield_all
#SBATCH --chdir=/work/pothmann/bioprint
#SBATCH --output=/gpfs1/work/pothmann/bioprint/00_preprocess_sum_yield_all/%x-%A-%a.out
#SBATCH --time=00-05:00:00
#SBATCH --mem-per-cpu=50G
#SBATCH --mail-user=peter.pothmann@idiv.de
#SBATCH --mail-type=BEGIN,END

# i decreased memory usage from 50G to 20G, check if enough, should still be plenty
# check computation time

module load foss/2020b R/4.0.4-2

# get list of input files from first argument
yieldFileInd="$1"

# get the specific input file for this task
# this is the n-th (where n is current task ID) line of the file
yieldFileInd=$(awk "NR==$SLURM_ARRAY_TASK_ID" "$yieldFileInd")

# use input file with app
# comment every other script in build_bioprint.R except 00_preprocess_lulc.R maybe write one .sh script for everything (preprocess)
Rscript --vanilla /home/pothmann/bioprint/03_code/bin/build_bioprint.R \
--line="$SLURM_ARRAY_TASK_ID" \
--verbose \
"$yieldFileInd" \

