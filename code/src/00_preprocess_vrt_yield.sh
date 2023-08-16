#!/bin/bash

# length: 2
# sbatch -a 1-1 /gpfs0/home/pothmann/bioprint/03_code/src/00_preprocess_vrt_yield.sh /data/bioprint/00_data/97_slurm/preprocess-vrt-yield-slurm.txt


#SBATCH --job-name=00_preprocess_vrt_yield
#SBATCH --chdir=/work/pothmann/bioprint
#SBATCH --output=/gpfs1/work/pothmann/bioprint/00_preprocess_vrt_yield/%x-%A-%a.out
#SBATCH --time=00-2:00:00
#SBATCH --mem-per-cpu=50G
#SBATCH --mail-user=peter.pothmann@idiv.de
#SBATCH --mail-type=BEGIN,END

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

