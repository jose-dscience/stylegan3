#!/bin/bash

STDOUTPUT=0
for arg in "$@"
do
    case $arg in 
        -std)
        STDOUTPUT=1
        shift
        ;;
        -config=*)
        CONFIG="${arg#*=}"
        source other/configs.sh -config=$CONFIG
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

SEEK_DIR=$(pwd)

if ! [ -z $LOG_PATH ]; then
    SEEK_DIR=$LOG_PATH
fi

LAST_SLURM_OUTPUT=$(ls $SEEK_DIR | grep slurm- | tail -n 1)
VIEW_PATH="$SEEK_DIR/$LAST_SLURM_OUTPUT"

if [ $STDOUTPUT -eq 1 ]; then
	VIEW_PATH=./output.out
fi   
 
while true
do
	clear
        clear
	cat $VIEW_PATH | tail -n 50
	sleep 1
done
