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


CURRENT_DIRECTORY=$(pwd)
cd /scratch
singularity exec --nv $SINGULARITY_IMAGE_PATH python3 /home/jfernand/eboy/eboygan/stylegan2-ada/dataset_tool.py unpack --tfrecord_dir=/scratch/jfernand/blasphemous/datasets/extended_data_512 --output_dir=/home/jfernand/tmp/dataset-unpacked

