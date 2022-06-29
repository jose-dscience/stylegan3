#!/bin/bash

SINGULARITY_IMAGE_PATH=/scratch/jfernand/my_container_latest.sif

### MANAGE FLAGS

NEW_WIDTH=-1
NEW_HEIGHT=-1
OUTDIR=./cropped
INDIR=.
NO_ALPHA=0
USE_PNG_IMAGES=1
USE_META_IMAGES=1
USE_GIF_IMAGES=1
SKIP_META=0
SKIP_PNG=0
SKIP_GIF=0
for arg in "$@"
do
	case $arg in 
		-width=*)
		NEW_WIDTH="${arg#*=}"
		shift # Remove argument name from processing
        shift # Remove argument value from processing
        ;;
		-height=*)
		NEW_HEIGHT="${arg#*=}"
		shift
		shift
		;;
		-indir=*)
		INDIR="${arg#*=}"
		shift
		shift
		;;
		-outdir=*)
		OUTDIR="${arg#*=}"
		shift
		shift
		;;
		-no-alpha)
		NO_ALPHA=1
		shift
		;;
		-ignore-meta-png)
        USE_META_IMAGES=0
        shift
        ;;
        -ignore-png)
        USE_PNG_IMAGES=0
        shift
        ;;
        -ignore-gif)
        USE_GIF_IMAGES=0
        shift
        ;;
        -skip-meta-png=*)
        SKIP_META="${arg#*=}"
        shift
        shift
        ;;
        -skip-png=*)
        SKIP_PNG="${arg#*=}"
        shift
        shift
        ;;
        -skip-gif=*)
        SKIP_GIF="${arg#*=}"
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

mkdir -p $OUTDIR

### REPLACE SPACES WITH "+"
echo "[+] Replacing spaces by character \"+\"."
find $INDIR -type f -name "* *" | while read file; do mv "$file" ${file// /+}; done

META_NAMES=($(find $INDIR -type f -name "*.meta"))
GIF_NAMES=($(find $INDIR -type f -name "*.gif"))
FAKE_GIF_NAMES=($(find $INDIR -type f -name "*.gif.png"))

#Remove fake gifs from gif list
for FAKE_GIF in "${FAKE_GIF_NAMES}"; do
    GIF_NAMES=( ${GIF_NAMES[@]/$FAKE_GIF} )
done

# Remove associated png file from png images list and meta if no meta is used
mkdir ./temp
echo "[+] Removing png with metafile from non-metafile png list."
i=0
n=${#META_NAMES[@]}
for META in "${META_NAMES[@]}"; do
    PNG=${META%.meta}
    PNG_NAME=$(basename $PNG)
    mv $PNG ./temp/$PNG_NAME
    echo -ne "  [-] Checked: $i/$n \r"
    ((i++))
done
echo "  [-] Checked: $i/$n"
echo -ne "  [-] Creating png list... \r"
PNG_NAMES=($(find $INDIR -type f -name "*.png"))

if [ "$(ls ./temp)" ]; then
    mv ./temp/* $INDIR/
fi
rm -r ./temp
echo "  [-] Creating png list... OK"


#Filter first parts of arrays (if requested)
META_NAMES=("${META_NAMES[@]:$SKIP_META}")
GIF_NAMES=("${GIF_NAMES[@]:$SKIP_GIF}")

if [ $NO_ALPHA ]
   then
      BACKGROUND=black
   else
      BACKGROUND=transparent
fi

# CHECK IF SINGULARITY EXIST
SINGULARITY=$(command -v singularity)
if [ -z $SINGULARITY ]; then
    SINGULARITY=0
    echo "[!] Singularity not found. Trying without."
else
    SINGULARITY=1
fi

### PROCESS METAFILE PNG

if [ $USE_META_IMAGES -ne 0 ]; then
    echo "[+] Working on PNG spritesheets with metafile."
    i=$SKIP_META
    for META in "${META_NAMES[@]}"
    do
        # Remove ".meta" from file extension
        META=$(basename $META)
        SPRITESHEET=${META%.meta}
        
        # Remove useless information from the meta file and save it as another file
        SKIP_UP_TO_LINE=$(grep -n spriteSheet: $INDIR/$SPRITESHEET.meta | grep -Eo '[0-9]{1,10}')
        NUMBER_OF_LINES=$(cat $INDIR/$SPRITESHEET.meta | wc -l)
        REMAINING_LINES=$((NUMBER_OF_LINES-SKIP_UP_TO_LINE))
        tail -n $REMAINING_LINES $INDIR/$SPRITESHEET.meta > meta.tmp

        # Get number of sprites in spritesheet
        NUM_OF_SPRITES=$(cat meta.tmp | grep -c name:)
        # let "NUM_OF_SPRITES=(NUM_OF_SPRITES-3)/2"

        #Get dimensions of spritesheet
        RAW_INFO=$(file $INDIR/$SPRITESHEET)
        IFS=', ' read -r -a ARRAY <<< "$RAW_INFO"
        SHEET_WIDTH=${ARRAY[4]}
        SHEET_HEIGHT=${ARRAY[6]}
        
        n=${#META_NAMES[@]}
        (( n=n+SKIP_META ))
        echo "   -Working over $SPRITESHEET of size "$SHEET_WIDTH" x "$SHEET_HEIGHT" containing $NUM_OF_SPRITES sprites [$i/$n]."
        
        # For single sprite, keep the original resolution
        if [ $NUM_OF_SPRITES -eq 1 ] || [ $NUM_OF_SPRITES -eq 0 ]
        then
            NUM_OF_SPRITES=1
            if [ $NEW_WIDTH -eq -1 ]
            then
                NEW_WIDTH=$(identify -format '%w' $INDIR/$SPRITESHEET)
            fi
            if [ $NEW_HEIGHT -eq -1 ]
            then
                NEW_HEIGHT=$(identify -format '%h' $INDIR/$SPRITESHEET)
            fi
            convert $INDIR/$SPRITESHEET -gravity center -background $BACKGROUND -extent "$NEW_WIDTH"x"$NEW_HEIGHT" $OUTDIR/$SPRITESHEET.png
        else
            for (( NUM_FILE=1; NUM_FILE<=$NUM_OF_SPRITES; NUM_FILE++ ))
            do
                # Extract the name of the NUM_ROW'th file of spritesheet
                RAW_NAME=$(cat meta.tmp | grep name | head -n $NUM_FILE | tail -n -1)
                IFS=', ' read -r -a ARRAY <<< "$RAW_NAME"
                NAME=${ARRAY[1]}
                    
                # echo "   +Cropping $NAME."

                # Extract the X coordinate within spritesheet
                let "NUM_ROW=NUM_FILE"
                RAW_X=$(cat meta.tmp | grep "  x: " | head -n $NUM_ROW | tail -n -1)
                IFS=', ' read -r -a ARRAY <<< "$RAW_X"
                X=${ARRAY[1]}

                # Extract the Y coordinate within spritesheet
                let "NUM_ROW=NUM_FILE"
                RAW_Y=$(cat meta.tmp | grep "  y: " | head -n $NUM_ROW | tail -n -1)
                IFS=', ' read -r -a ARRAY <<< "$RAW_Y"
                Y=${ARRAY[1]}

                # Extract the WIDTH coordinate within spritesheet
                let "NUM_ROW=NUM_FILE"
                RAW_WIDTH=$(cat meta.tmp | grep width: | head -n $NUM_ROW | tail -n -1)
                IFS=', ' read -r -a ARRAY <<< "$RAW_WIDTH"
                WIDTH=${ARRAY[1]}

                # Extract the HEIGHT coordinate within spritesheet
                let "NUM_ROW=NUM_FILE"
                RAW_HEIGHT=$(cat meta.tmp | grep height: | head -n $NUM_ROW | tail -n -1)
                IFS=', ' read -r -a ARRAY <<< "$RAW_HEIGHT"
                HEIGHT=${ARRAY[1]}
                
                # the reference in y is in the bottom 
                let "Y=SHEET_HEIGHT-Y-HEIGHT"
                
                # Debug information prints
                # echo "    -Value of X: $X" ########################################################
                # echo "    -Value of Y: $Y" ########################################################
                # echo "    -Value of width: $WIDTH" ########################################################
                # echo "    -Value of height: $HEIGHT" ########################################################
                
                # take original dimensions if are not provided
                if [ $NEW_WIDTH -eq -1 ]
                then
                    USED_WIDTH=$WIDTH
                else
                    USED_WIDTH=$NEW_WIDTH
                fi
                if [ $NEW_HEIGHT -eq -1 ]
                then
                    USED_HEIGHT=$HEIGHT
                else
                    USED_HEIGHT=$NEW_HEIGHT
                fi
                
                convert $INDIR/$SPRITESHEET -crop "$WIDTH"x"$HEIGHT"+"$X"+"$Y" -gravity center -background $BACKGROUND -extent "$USED_WIDTH"x"$USED_HEIGHT" $OUTDIR/$NAME.png
            done
        fi
        ((i++))
        rm meta.tmp
    done
fi

### PROCESS GIF

if [ $USE_GIF_IMAGES -ne 0 ]; then
    echo "[+] Pre-processing GIF images."
    PNG_COMING_FROM_GIF=()
    i=$SKIP_GIF
    for GIF in "${GIF_NAMES[@]}"
    do
        NUM_FRAMES=$(identify -format "%n\n" $GIF | head -1)
        GIF=$(basename $GIF)
        
        # Remove ".gif" from file extension
        IMAGE=${GIF%.gif}
        
        n=${#GIF_NAMES[@]}
        (( n=n+$SKIP_GIF ))
        echo "   -Working over $GIF [$i/$n]."
        convert $INDIR/$GIF -coalesce $INDIR/$IMAGE.png
        
        for (( j=0; j<NUM_FRAMES; j++)); do
            PNG_COMING_FROM_GIF+=( "$OUTDIR/$IMAGE-$j.png" )
        done
        ((i++))
    done
fi

### PROCESS NON-METAFILE PNG

if [ $USE_PNG_IMAGES -ne 0 ]; then
    echo "[+] Working on png images without metafile and these coming from gifs."
    PNG_NAMES+=(${PNG_COMING_FROM_GIF[@]})
else
    echo "[+] Working only on png images coming from gifs."
    PNG_NAMES=()
    PNG_NAMES+=(${PNG_COMING_FROM_GIF[@]})
fi
        
i=$SKIP_PNG
for PNG in "${PNG_NAMES[@]}"
do   
    PNG=$(basename $PNG)        

    # Remove ".png" from file extension
    IMAGE=${PNG%.png}
    WIDTH=$(identify -format '%w' $INDIR/$PNG)
    HEIGHT=$(identify -format '%h' $INDIR/$PNG)
    
    n=${#PNG_NAMES[@]}
    ((n=n+SKIP_PNG))
    echo "   -Working over $PNG of size "$WIDTH" x "$HEIGHT" [$i/${#PNG_NAMES[@]}]."
    
    # take original dimensions if are not provided
    if [ $NEW_WIDTH -eq -1 ]
    then
        USED_WIDTH=$WIDTH
    else
        USED_WIDTH=$NEW_WIDTH
    fi
    if [ $NEW_HEIGHT -eq -1 ]
    then
        USED_HEIGHT=$HEIGHT
    else
        USED_HEIGHT=$NEW_HEIGHT
    fi
    
    # Crop if needed
    NUM_CROPS_WIDTH=1
    NUM_CROPS_HEIGHT=1
    if [ $WIDTH -gt $USED_WIDTH ]; then
        ((NUM_CROPS_WIDTH=WIDTH/USED_WIDTH+1))
        if [ $((WIDTH%USED_WIDTH)) -eq 0 ]; then
            ((NUM_CROPS_WIDTH--))
        fi
    fi
    if [ $HEIGHT -gt $USED_HEIGHT ]; then
        ((NUM_CROPS_HEIGHT=HEIGHT/USED_HEIGHT+1))
        if [ $((HEIGHT%USED_HEIGHT)) -eq 0 ]; then
            ((NUM_CROPS_HEIGHT--))
        fi
    fi
    ((DELTA_WIDTH=(WIDTH-USED_WIDTH)/NUM_CROPS_WIDTH ))
    ((DELTA_HEIGHT=(HEIGHT-USED_HEIGHT)/NUM_CROPS_HEIGHT ))
    
    if [ $NUM_CROPS_WIDTH -eq 1 ] && [ $NUM_CROPS_HEIGHT -eq 1 ]; then
        convert $INDIR/$PNG -gravity center -background $BACKGROUND -extent "$USED_WIDTH"x"$USED_HEIGHT" $OUTDIR/$PNG
    else
        PIVOT_HEIGHT=0
        j=0
        for ((row=0; row<NUM_CROPS_HEIGHT; row++)); do
            PIVOT_WIDTH=0
            for ((col=0; col<NUM_CROPS_WIDTH; col++)); do
                convert $INDIR/$PNG -crop "$USED_WIDTH"x"$USED_HEIGHT"+"$PIVOT_WIDTH"+"$PIVOT_HEIGHT" -gravity center -background $BACKGROUND -extent "$USED_WIDTH"x"$USED_HEIGHT" $OUTDIR/$IMAGE-$j.png
                
                #Delete void images
                NUM_COLORS=$(identify -format %k $OUTDIR/$IMAGE-$j.png)
                if [ $NUM_COLORS -lt 2 ]; then
                    rm $OUTDIR/$IMAGE-$j.png
                fi
                
                ((PIVOT_WIDTH=PIVOT_WIDTH+DELTA_WIDTH))
                ((j++))
            done
            ((PIVOT_HEIGHT=PIVOT_HEIGHT+DELTA_HEIGHT))
        done
    fi
    ((i++))
done

### CONVERT ALL IMAGES TO NO-ALPHA

if [ $NO_ALPHA ]; then
    echo "[+] Converting to no-alpha."

    PYTHON=python3
    if [ $SINGULARITY -eq 1 ]; then
        PYTHON="singularity exec $SINGULARITY_IMAGE_PATH $PYTHON"
        cd /scratch
    fi

    CURRENT_DIR=$(pwd)
    
    $PYTHON << END
from PIL import Image
import glob

images = glob.glob("$OUTDIR/*")

for image in images:
   with open(image, 'rb') as file:
      img = Image.open(file).convert('RGB')
      img.save(image, 'PNG')
END
fi
cd $CURRENT_DIR
echo done

