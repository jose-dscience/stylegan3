#!/bin/bash
#SBATCH -n10
#SBATCH -N1
#SBATCH --time 08:00:00
#SBATCH --mail-user="fernandez.fisica@gmail.com"
#SBATCH --mail-type=ALL
#SBATCH -p wide1

DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512"
IMAGES_PATH="/scratch/jfernand/blasphemous/extended_512x512"
SINGULARITY_IMAGE_PATH="/scratch/jfernand/my_container_latest.sif"

for arg in "$@"
do
	case $arg in 
		-config=*)
		CONFIG="${arg#*=}"
		./other/configs.sh -config=$CONFIG
		shift # Remove argument name from processing
        	shift # Remove argument value from processing
        	;;
		-images-dir=*)
		IMAGES_PATH="${arg#*=}"
		shift
		shift
		;;
		*)
        	OTHER_ARGUMENTS+=("$1")
        	echo "[!] ERROR: Passed wrong argument \"${arg#*=}\"."
        	exit
        	shift # Remove generic argument from processing
        	;;
	esac
done


CURRENT_DIRECTORY=$(pwd)
cd /scratch
singularity exec $SINGULARITY_IMAGE_PATH python3 $CURRENT_DIRECTORY/../dataset_tool.py create_from_images $DATASET_DIR $IMAGES_PATH

