#!/bin/bash
# length: 250000
# sbatch -a 1-1 /gpfs0/home/pothmann/bioprint/03_code/src/02_intensification_adjust_aoh.sh /data/bioprint/00_data/97_slurm/intensification_adjust_aoh-slurm.txt

#SBATCH --job-name=02_intensification_adjust_aoh
#SBATCH --chdir=/work/pothmann/bioprint
#SBATCH --output=/gpfs1/work/pothmann/bioprint/02_intensification_adjust_aoh/%x-%A-%a.out
#SBATCH --time=00-3:00:00
#SBATCH --mem-per-cpu=25G
#SBATCH --mail-user=peter.pothmann@idiv.de
#SBATCH --mail-type=BEGIN,END

module load foss/2020b R/4.0.4-2

# get list of input files from first argument
aohFileS1="$1"

# get the specific input file for this task
# this is the n-th (where n is current task ID) line of the file
aohFileS1=$(awk "NR==$SLURM_ARRAY_TASK_ID" "$aohFileS1")

# use input file with app
Rscript --vanilla /home/pothmann/bioprint/03_code/bin/build_bioprint.R \
--line="$SLURM_ARRAY_TASK_ID" \
--verbose \
"$aohFileS1" \
