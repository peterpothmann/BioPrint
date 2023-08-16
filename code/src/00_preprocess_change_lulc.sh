#!/bin/bash
# length: 50
# sbatch -a 1-1 /gpfs0/home/pothmann/bioprint/03_code/src/00_preprocess_change_lulc.sh /data/bioprint/00_data/97_slurm/change-lulc-slurm.txt

#SBATCH --job-name=00_preprocess_change_lulc
#SBATCH --chdir=/work/pothmann/bioprint
#SBATCH --output=/gpfs1/work/pothmann/bioprint/00_preprocess_change_lulc/%x-%A-%a.out
#SBATCH --time=00-01:00:00
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
Rscript --vanilla /home/pothmann/bioprint/03_code/bin/build_bioprint.R \
--line="$SLURM_ARRAY_TASK_ID" \
--verbose \
"$submitInd" \
