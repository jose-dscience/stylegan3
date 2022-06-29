#!/bin/bash
#SBATCH -N4
#SBATCH -n4
#SBATCH --time 01:30:00

IMAGES_DIR="$(pwd)/../eboy-images"
DATASETS_DIR="$(pwd)/../datasets"
DATASET_DIR="${DATASETS_DIR}/eboy"
RESULTS_DIR="$(pwd)/../results"

./ulysses_initial_settings.sh

python ../run_metrics.py --data-dir=$DATASETS_DIR --network=$RESULTS_DIR/00000-stylegan2-eboy-1gpu-config-f/submit_config.pkl --metrics=fid50k,ppl2_wend


