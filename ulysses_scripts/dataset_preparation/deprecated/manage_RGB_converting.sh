#!/bin/bash

## UTILISATION
## when passing the flag -id=(int) it is roden the last image processed from slurm-(int).out

#SBATCH --mail-user="fernandez.fisica@gmail.com"
#SBATCH --mail-type=ALL

#Directories must be ABSOLUTE ONES
IN_DIRECTORY="/scratch/jfernand/blasphemous/raw_data"
OUT_DIRECTORY="/scratch/jfernand/blasphemous/raw_data_RGB"
SINGULARITY_IMAGE_PATH="/scratch/jfernand/my_container_latest.sif"

#Default value of argument
PREVIOUS_JID=-1

for arg in "$@"
do
	case $arg in 
		-id=*)
		PREVIOUS_JID="${arg#*=}"
		shift # Remove argument name from processing
        	shift # Remove argument value from processing
        	;;
        	*)
        	OTHER_ARGUMENTS+=("$1")
        	shift # Remove generic argument from processing
        	;;
	esac
done

SLURM_LOG=slurm-$PREVIOUS_JID.out

START_FROM=0
if [ -r $SLURM_LOG ]
then
	NUMBERS=($(tail ./$SLURM_LOG | grep "Processing ../blasphemous_data_uniformed/" | tail -n 1 | grep -Eo '[0-9]{1,20}'))
	START_FROM=${NUMBERS[7]}
	cat ./$SLURM_LOG >> output.out
	rm ./$SLURM_LOG
fi

LAUNCHING_DIR=$(pwd)
cd /scratch
singularity exec $SINGULARITY_IMAGE_PATH python3 $LAUNCHING_DIR/dataset_preparation/RGBA_to_RGB.py --input_dir $IN_DIRECTORY --output_dir $OUT_DIRECTORY --start_from $START_FROM
