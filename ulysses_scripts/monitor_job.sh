#!/bin/bash

for arg in "$@"
do
    case $arg in 
    -config=*)
    CONFIG="${arg#*=}"
    source other/configs.sh -config=$CONFIG
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

SQUEUE="squeue --users=$USER"

if ! [ -z $CONFIG ]; then
    SQUEUE="$SQUEUE --name=chk_$NAME,strt_$NAME,cnt_$NAME"
fi

while true
do
	clear
        clear
	$SQUEUE
	sleep 1
done
