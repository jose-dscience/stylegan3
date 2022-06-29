#!/bin/bash

SINGULARITY_IMAGE_PATH=/scratch/jfernand/my_container_latest.sif

### MANAGE FLAGS

WIDTH=-1
HEIGHT=-1
DIR=.
LOGFILE_PATH=0
REMOVE=0
DEBUG_MODE=0
for arg in "$@"
do
	case $arg in 
		-width=*)
		WIDTH="${arg#*=}"
		shift # Remove argument name from processing
        shift # Remove argument value from processing
        ;;
		-height=*)
		HEIGHT="${arg#*=}"
		shift
		shift
		;;
		-dir=*)
		DIR="${arg#*=}"
		shift
		shift
		;;
		-logfile-path=*)
		LOGFILE_PATH="${arg#*=}"
		shift
		shift
		;;
		-remove-wrongs)
		REMOVE=1
		shift
		;;
		-debug-mode)
		DEBUG_MODE=1
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

FILE_PATHS=($DIR/*)
echo ${#FILE_PATHS[@]}

if [ $WIDTH -eq -1 ]; then
    WIDTH=$(identify -format '%w' ${FILE_PATHS[1]})
fi
if [ $HEIGHT -eq -1 ]; then
    HEIGHT=$(identify -format '%h' ${FILE_PATHS[1]})
fi

echo "[+] Looking for files without right dimensions (using $WIDTH x $HEIGHT)."

if [ $LOGFILE_PATH -ne 0 ]; then
    touch $LOGFILE_PATH/wrong_images.log
fi

n=${#FILE_PATHS[@]} 
for (( i=1; i<=n; i++ )); do
    FILE=${FILE_PATHS[i]}
    CURRENT_WIDTH=$(identify -format '%w' $FILE)
    CURRENT_HEIGHT=$(identify -format '%h' $FILE)
    
    if [ $CURRENT_WIDTH -ne $WIDTH ] || [ $CURRENT_HEIGHT -ne $HEIGHT ]; then
        echo "  [!] Image \"$(basename $FILE)\" has wrong dimensions ($CURRENT_WIDTH x $CURRENT_HEIGHT)."
        
        if [ $LOGFILE_PATH -ne 0 ]; then
            $FILE >> $LOGFILE_PATH
        fi
        
        if [ $REMOVE -eq 1 ]; then
            echo "      Removing."
            rm $FILE
        fi
        
    fi
    
    ((i++))
done

echo done

