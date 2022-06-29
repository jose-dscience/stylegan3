#!/bin/bash

#SBATCH -n8
#SBATCH -p gpu2	
#SBATCH --gres=gpu:2
#SBATCH --time 12:00:00
#SBATCH --mem 30000
#SBATCH --mail-user="fernandez.fisica@gmail.com"
#SBATCH --mail-type=ALL

SINGULARITY_IMAGE_PATH=/scratch/jfernand/container_pytorch.sif

RESULTS_DIR="/scratch/jfernand/blasphemous/results"
INPUT_DIR="$(pwd)/projection/input_images"
OUTPUT_DIR="$(pwd)/projection/output_images"

for arg in "$@"
do
        case $arg in
		-config=*)
		CONFIG="${arg#*=}"
		source other/configs.sh -config=$CONFIG
		shift
		shift
		;;
                -indir=*)
                INPUT_DIR="${arg#*=}"
                shift # Remove argument name from processing
                shift # Remove argument value from processing
                ;;
                -outdir=*)
                OUTPUT_DIR="${arg#*=}"
                shift
		shift
                ;;
                -results-dir=*)
                RESULTS_DIR="${arg#*=}"
                shift
                shift
                ;;
                *)
                echo "[!] ERROR: Passed wrong argument \"${arg#*=}\" in commit_projections.sh."
                exit
                OTHER_ARGUMENTS+=("$1")
                shift # Remove generic argument from processing
                ;;
        esac
done


i=1
LAST_PKL=""
while [ -z "$LAST_PKL" ]
do
	LAST_PKL_FOLDER="$(ls $RESULTS_DIR | tail -n $i | head -n 1)"
	LAST_PKL="$(ls $RESULTS_DIR/$LAST_PKL_FOLDER/ | grep network-snapshot | tail -n 1)"
	PKL_PATH="$RESULTS_DIR/$LAST_PKL_FOLDER/$LAST_PKL"
	((i++))
done

CURRENT_DIR=$(pwd)
cd /scratch

for INPUT_IMG in $INPUT_DIR/*
do
	echo "	[+] Working over $INPUT_IMG"
	INPUT_IMG=$(basename $INPUT_IMG)
	singularity exec --nv $SINGULARITY_IMAGE_PATH python3 $CURRENT_DIR/../projector.py --network $PKL_PATH --target $INPUT_DIR/$INPUT_IMG --outdir $OUTPUT_DIR/$INPUT_IMG
	echo "============================================================================="
done 

