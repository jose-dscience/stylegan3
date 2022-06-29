#!/bin/bash
#SBATCH -N2
#SBATCH -n8
#SBATCH --time 12:00:00
#SBATCH --gres=gpu:2
#SBATCH --mem 20000
#SBATCH	--mail-user="fernandez.fisica@gmail.com"
#SBATCH	--mail-type=ALL

SINGULARITY_IMAGE_PATH=/scratch/jfernand/container_pytorch.sif

DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512.zip"
RESULTS_DIR="/scratch/jfernand/blasphemous/results"
TRAINING_FLAGS=""
RESUME_KIMG=""
for arg in "$@"
do
        case $arg in
            -data-dir=*)
            DATASET_DIR="${arg#*=}"
            shift
            shift
            ;;
            -results-dir=*)
            RESULTS_DIR="${arg#*=}"
            shift
            shift
            ;;
            -transfer=*)
            TRANSFER_PKL_PATH="${arg#*=}"
            shift
            shift
            ;;
            -resume-kimg=*)
            RESUME_KIMG="${arg#*=}"
            shift
            shift
            ;;
            -training-flags=*)
            TRAINING_FLAGS="${arg#*=}"
            TRAINING_FLAGS="${TRAINING_FLAGS//¬/ }"
            shift
            shift
            ;;
            *)
            echo "[!] ERROR: Passed wrong argument \"${arg#*=}\" in check_training.sh."
            exit
            shift # Remove generic argument from processing
            ;;
        esac
done

if ! [ -z $RESUME_KIMG ]; then
    TRAINING_FLAGS="$TRAINING_FLAGS --resume_kimg=$RESUME_KIMG"
fi

CURRENT_DIR=$(pwd)
cd /scratch

if ! [ -z $TRANSFER_PKL_PATH ]; then
    TRAINING_FLAGS="$TRAINING_FLAGS --resume=$TRANSFER_PKL_PATH"
fi
echo singularity exec --nv $SINGULARITY_IMAGE_PATH python3 $CURRENT_DIR/../train.py --gpus=2 --outdir=$RESULTS_DIR --data=$DATASET_DIR $TRAINING_FLAGS --dry-run 
singularity exec --nv $SINGULARITY_IMAGE_PATH python3 $CURRENT_DIR/../train.py --gpus=2 --outdir=$RESULTS_DIR --data=$DATASET_DIR $TRAINING_FLAGS --dry-run 
