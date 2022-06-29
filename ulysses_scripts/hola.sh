#!/bin/bash
#SBATCH -n10
#SBATCH -N1
#SBATCH -p gpu2
#SBATCH --time 08:00:00
#SBATCH --gres=gpu:1
#SBATCH --mail-user="fernandez.fisica@gmail.com"
#SBATCH --mail-type=ALL

DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512"
IMAGES_PATH="/scratch/jfernand/blasphemous/extended_512x512"
SINGULARITY_IMAGE_PATH="/scratch/jfernand/container_pytorch.sif"


CURRENT_DIRECTORY=$(pwd)
cd /scratch
singularity exec --nv $SINGULARITY_IMAGE_PATH python3 /home/jfernand/stylegan3/dataset_tool.py --source=/home/jfernand/tmp/dataset-unpacked --dest=/scratch/jfernand/blasphemous/datasets/extended_data_512.zip

