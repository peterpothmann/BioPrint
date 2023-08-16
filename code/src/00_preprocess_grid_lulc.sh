#!/bin/bash

# sbatch -a 1-1 /gpfs0/home/pothmann/bioprint/03_code/src/00_preprocess_grid_lulc.sh /data/bioprint/00_data/97_slurm/lulc-files-in.txt

# mataatlantica needs 650G others less
# schauen ob stunden anzahl ausreicht, vorher 8 h

#SBATCH --job-name=00_preprocess_grid_lulc
#SBATCH --chdir=/work/pothmann/bioprint
#SBATCH --output=/gpfs1/work/pothmann/bioprint/00_preprocess_grid_lulc/%x-%A-%a.out
#SBATCH --time=00-02:30:00
#SBATCH --mem-per-cpu=350G
#SBATCH --mail-user=peter.pothmann@idiv.de
#SBATCH --mail-type=BEGIN,END

module load foss/2020b R/4.0.4-2

# get list of input files from first argument
lulcFile="$1"

# get the specific input file for this task
# this is the n-th (where n is current task ID) line of the file
lulcFile=$(awk "NR==$SLURM_ARRAY_TASK_ID" "$lulcFile")

# use input file with app
# comment every other script in build_bioprint.R except 00_preprocess_lulc.R
Rscript --vanilla /home/pothmann/bioprint/03_code/bin/build_bioprint.R \
--line="$SLURM_ARRAY_TASK_ID" \
--verbose \
"$lulcFile" \
