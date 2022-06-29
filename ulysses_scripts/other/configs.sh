#!/bin/bash

for arg in "$@"
do
	case $arg in 
		-config=*)
		CONFIG="${arg#*=}"
		shift # Remove argument name from processing
        	shift # Remove argument value from processing
        	;;
		*)
                OTHER_ARGUMENTS+=("$1")
                echo "[!] ERROR: Passed wrong argument \"${arg#*=}\" in configs.sh."
                exit
                shift # Remove generic argument from processing
                ;;
	esac
done

case $CONFIG in
    "1")
	export NAME="st3_1_stylegan3-t"
    export DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512.zip"
    export RESULTS_DIR="/scratch/jfernand/blasphemous/results/$NAME"
    export DESTINATION_FOLDER="./resources/training_checkpoints/$NAME"
    export OUTPUT_DIR="$(pwd)/resources/projection/output_$NAME"
    export INPUT_DIR="$(pwd)/resources/projection/input_extended_data_512"
    export PREV_METRICS=""
    export TRANSFER_LEARNING="l"
    export RESUME_KIMG=""
    export LOG_PATH="$(pwd)/resources/slurm_logs/$NAME"
    export TRAINING_FLAGS="--cfg=stylegan3-t --mirror=1 --aug=ada --metrics=fid50k --snap=12 --batch=16 --gamma=8.2"
    ;;
    "2")
	export NAME="st3_2_stylegan3-t"
    export DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512.zip"
    export RESULTS_DIR="/scratch/jfernand/blasphemous/results/$NAME"
    export DESTINATION_FOLDER="./resources/training_checkpoints/$NAME"
    export OUTPUT_DIR="$(pwd)/resources/projection/output_$NAME"
    export INPUT_DIR="$(pwd)/resources/projection/input_extended_data_512"
    export PREV_METRICS=""
    export TRANSFER_LEARNING=""
    export RESUME_KIMG=""
    export LOG_PATH="$(pwd)/resources/slurm_logs/$NAME"
    export TRAINING_FLAGS="--cfg=stylegan3-r --mirror=1 --aug=ada --metrics=fid50k --snap=11 --batch=16 --gamma=8.2"
    ;;
    *)
    echo "[!] ERROR: Provided configuration \"$CONFIG\" does not exists. Check \"$(pwd)/other/configs.sh\" to see current configurations or create a new one."
esac

### Substitute "¬" character by spaces in training flags
export TRAINING_FLAGS="${TRAINING_FLAGS// /¬}"
echo "[+] Setting environment variables to config number $CONFIG with name $NAME."


