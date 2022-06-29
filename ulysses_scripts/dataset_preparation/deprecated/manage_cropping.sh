#!/bin/bash

## UTILISATION
## when passing the flag -id=(int) it is roden the last image processed from slurm-(int).out

#SBATCH --mail-user="fernandez.fisica@gmail.com"
#SBATCH --mail-type=ALL

#Directories must be ABSOLUTE ONES
INPUT_DIR="/scratch/jfernand/blasphemous/raw_data_RGB"
OUTPUT_DIR="/scratch/jfernand/blasphemous/raw_data_RGB_uniformed"
SINGULARITY_IMAGE_PATH="/scratch/jfernand/my_container_latest.sif"

CONTINUE_FROM="3524270b9bf7b0884ff360cc3b5210ee.png"

LAUNCHING_DIR=$(pwd)
cd /scratch
singularity exec $SINGULARITY_IMAGE_PATH python3 $LAUNCHING_DIR/dataset_preparation/uniform_images.py --size=128 --input_data=$INPUT_DIR --images_dir=$OUTPUT_DIR --image_format=png --continue_from=$CONTINUE_FROM
