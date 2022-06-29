#!/bin/bash

# su - jfernand -c 'module load intelpython3/3.6.8'
# su - jfernand -c 'source activate tf_1.14'
# su - jfernand -c 'module load cuda/10.0'
# su - jfernand -c 'module load gnu7/7.3.1'

# su - jfernand -c 'module load singularity/3.4.1'

source activate tf_1.14

IMAGES_DIR="$(pwd)/../eboy-images"
DATASETS_DIR="$(pwd)/../datasets"
DATASET_DIR="${DATASETS_DIR}/eboy"
RESULTS_DIR="$(pwd)/../results" 
