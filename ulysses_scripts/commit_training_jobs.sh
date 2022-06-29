#!/bin/bash

# INSTRUCTIONS: Write in the SCRIPT_PATH variable and the number of jobs to commit (minimum: 1)

RESUME_TRAINING=1
CHECK_PATH=./training/check_training.sh
START_PATH=./training/start_training.sh
CONTINUE_PATH=./training/continue_training.sh
NUMBER_JOBS=6
TIME=12:00:00
QUEUE=gpu2
EMAIL=fernandez.fisica@gmail.com
DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512.zip"
RESULTS_DIR="/scratch/jfernand/blasphemous/highres_results"
NAME=""
TRAINING_FLAGS=""
CANCEL=0
AFTER=""

for arg in "$@"
do
        case $arg in
            -config=*)
            CONFIG="${arg#*=}"
            source other/configs.sh -config=$CONFIG
            shift
            shift
            ;;
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
            -name=*)
            NAME="${arg#*=}"
            shift
            shift
            ;;
            -start)
            RESUME_TRAINING=0
            shift
            ;;
            -cancel)
            CANCEL=1
            shift
            ;;
            -n=*)
            NUMBER_JOBS="${arg#*=}"
            shift
            shift
            ;;
            -after=*)
            AFTER="${arg#*=}"
            shift
            shift
            ;;
            *)
            OTHER_ARGUMENTS+=("$1")
            echo "[!] ERROR: Passed wrong argument \"${arg#*=}\" in commit_training_jobs.sh."
            exit
            shift # Remove generic argument from processing
            ;;
        esac
done
echo "[+] Adding arguments to python."

### Add arguments to different sub-scripts
if ! [ -z $DATASET_DIR ]
then
	echo "	[-] Dataset's directory taken as \"$DATASET_DIR\""
	CHECK_PATH="$CHECK_PATH -data-dir=$DATASET_DIR"
	START_PATH="$START_PATH -data-dir=$DATASET_DIR"
	CONTINUE_PATH="$CONTINUE_PATH -data-dir=$DATASET_DIR"
fi

if ! [ -z $RESULTS_DIR ]
then
        echo "	[-] Results directory taken as \"$RESULTS_DIR\""
	CHECK_PATH="$CHECK_PATH -results-dir=$RESULTS_DIR"
        START_PATH="$START_PATH -results-dir=$RESULTS_DIR"
        CONTINUE_PATH="$CONTINUE_PATH -results-dir=$RESULTS_DIR"
fi
if ! [ -z "$NAME" ]
then
	CHECK_PATH="--job-name=chk_$NAME $CHECK_PATH"
	START_PATH="--job-name=strt_$NAME $START_PATH"
	CONTINUE_PATH="--job-name=cnt_$NAME $CONTINUE_PATH"
fi
if ! [ -z "$LOG_PATH" ]
then
    if ! [ -d "$LOG_PATH" ]; then
        mkdir $LOG_PATH
    fi
	CHECK_PATH="--output=$LOG_PATH/slurm-%j.out $CHECK_PATH"
	START_PATH="--output=$LOG_PATH/slurm-%j.out $START_PATH"
	CONTINUE_PATH="--output=$LOG_PATH/slurm-%j.out $CONTINUE_PATH"
fi

if ! [ -z "$TRAINING_FLAGS" ]
then
	CHECK_PATH="$CHECK_PATH -training-flags=$TRAINING_FLAGS"
	START_PATH="$START_PATH -training-flags=$TRAINING_FLAGS"
	CONTINUE_PATH="$CONTINUE_PATH -training-flags=$TRAINING_FLAGS"
fi
if ! [ -z $RESUME_KIMG ]
then
    CHECK_PATH="$CHECK_PATH -resume-kimg=$RESUME_KIMG"
	START_PATH="$START_PATH -resume-kimg=$RESUME_KIMG"
fi

### Cancel if requested
if [[ ! -z $CONFIG && $CANCEL -eq 1 ]]; then
    echo "[+] Proceding with deletion of config profile $CONFIG with name $NAME."
    echo "  [-] Deleting jobs with name \"chk_$NAME\"."
    squeue -u $USER --name="chk_$NAME"
    scancel -u $USER --name="chk_$NAME"
    echo "  [-] Deleting jobs with name \"strt_$NAME\"."
    squeue -u $USER --name="strt_$NAME"
    scancel -u $USER --name="strt_$NAME"
    echo "  [-] Deleting jobs with name \"cnt_$NAME\"."
    squeue -u $USER --name="cnt_$NAME"
    scancel -u $USER --name="cnt_$NAME"
    echo "[+] Remaning jobs."
    squeue -u $USER
    echo "done"
    exit
elif [ -z $CONFIG ]; then
    echo "[!] ERROR: Config profile was not provided. Usage of --config is mandatory to use --cancel flag."
    exit
fi

### Commit subscripts

if ! [ -z $AFTER ];
then
    # Find the latest submitted job id for the provided profile.
    if [ $AFTER == "last" ]; then
        if ! [-z $CONFIG]; then
            LAST_ID=$(squeue -u $USER --name="cnt_$NAME" --sort=i | tail -n 1 | grep -Eo '[0-9]{1,8}')
            IFS=', ' read -r -a LAST_ID <<< "$LAST_ID"
            LAST_ID=${LAST_ID[0]}
            
            if [ -z $LAST_ID ]; then
                LAST_ID=$(squeue -u $USER --name="strt_$NAME" --sort=i | tail -n 1 | grep -Eo '[0-9]{1,8}')
                IFS=', ' read -r -a LAST_ID <<< "$LAST_ID"
                LAST_ID=${LAST_ID[0]}
                if [ -z $LAST_ID ]; then
                    echo "[!] ERROR: Last submitted job for config profile with name \"$NAME\" was not found. Try specifying last job's pecifig ID."
                    exit
                fi
            fi
        else
            LAST_ID=$(squeue -u $USER --sort=i | tail -n 1 | grep -Eo '[0-9]{1,8}')
            IFS=', ' read -r -a LAST_ID <<< "$LAST_ID"
            LAST_ID=${LAST_ID[0]}
            LAST_ID=${LAST_ID[0]}
            if [ -z $LAST_ID ]; then
                echo "[!] ERROR: Last submitted job was not found. Try specifying last job's pecifig ID."
                exit
            fi
        fi
        
        AFTER=$LAST_ID
    fi
    
    echo "[!] Jobs will be executed after the folowing one:"
    squeue -j $AFTER
    AFTER="--dependency=afterany:$AFTER"
fi

echo "[+] Commiting jobs."
if [ $RESUME_TRAINING -eq 0 ]
then
	echo "	[-] Verification job."
	if ! [ -z $TRANSFER_LEARNING ]
	then
		echo "	   [-] Using transfer learning with \"$TRANSFER_LEARNING\""
		START_PATH="$START_PATH -transfer=$TRANSFER_LEARNING"
		CHECK_PATH="$CHECK_PATH -transfer=$TRANSFER_LEARNING"
		if ! [ -z $RESUME_KIMG ]; then
            echo "	      [-] Taking \"$RESUME_KIMG\" as initial kimg."
        fi
	fi
	JID=$(sbatch -p $QUEUE --time=$TIME $CHECK_PATH | grep -Eo '[0-9]{1,8}')
    
    echo "	[-] Starting training job (dependency)."
    JID=$(sbatch --dependency=afterok:$JID -p $QUEUE --time=$TIME $START_PATH | grep -Eo '[0-9]{1,8}')
else
    if [ -z $AFTER ]; then
        echo "	[-] Continuation job."
    else
        echo "	[-] Continuation job (dependency)."
    fi
	JID=$(sbatch $AFTER -p $QUEUE --time=$TIME $CONTINUE_PATH | grep -Eo '[0-9]{1,8}')
fi

for (( i=1; i<$((NUMBER_JOBS)); i++ ))
do
    echo "	[-] Continuation job (dependency)."
    JID=$(sbatch --dependency=afterany:$JID -p $QUEUE --time=$TIME $CONTINUE_PATH | grep -Eo '[0-9]{1,8}')
done

echo done


