#!/bin/bash

# sbatch -a 1-11382 /gpfs0/home/pothmann/bioprint/03_code/src/00_preprocess_aoh.sh /data/bioprint/00_data/97_slurm/preprocess-aoh-slurm.txt
# 1176 --> AoH-22712252_20180101_30arcSec.tif the largest file, 15 Gb should be planty, needs nearly nothing
# length : 11382

#SBATCH --job-name=00_preprocess_aoh
#SBATCH --chdir=/work/pothmann/bioprint
#SBATCH --output=/gpfs1/work/pothmann/bioprint/00_preprocess_aoh/%x-%A-%a.out
#SBATCH --time=00-02:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user=peter.pothmann@idiv.de
#SBATCH --mail-type=BEGIN,END

module load foss/2020b R/4.0.4-2

# get list of input files from first argument
submitInd="$1"

# get the specific input file for this task
# this is the n-th (where n is current task ID) line of the file
submitInd=$(awk "NR==$SLURM_ARRAY_TASK_ID" "$submitInd")

# use input file with app
# comment every other script in build_bioprint.R except 00_preprocess_aoh.R
Rscript --vanilla /home/pothmann/bioprint/03_code/bin/build_bioprint.R \
--line="$SLURM_ARRAY_TASK_ID" \
--verbose \
"$submitInd" \
