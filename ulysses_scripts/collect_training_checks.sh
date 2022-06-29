#!/bin/bash
DESTINATION_FOLDER="./training_checks_highres"
RESULTS_DIR="/scratch/jfernand/blasphemous/highres_results"
SINGULARITY_IMAGE_PATH=/scratch/jfernand/my_container_latest.sif

ROOT_DIR="$(pwd)/.."

### MANAGE FLAGS

NUMBER_PLOT_SAMPLES=""
COLLECT_IMAGES=1
SAVE_DATA_FILE=0
PREV_METRICS=""
for arg in "$@"
do
	case $arg in
		-config=*)
                CONFIG="${arg#*=}"
                source other/configs.sh -config=$CONFIG
                shift
                shift
                ;; 
		-plot-last-samples=*)
		NUMBER_PLOT_SAMPLES="${arg#*=}"
		shift # Remove argument name from processing
        	shift # Remove argument value from processing
        	;;
		-no-images)
		COLLECT_IMAGES=0
		shift
		;;
		-save-metrics-data)
		SAVE_DATA_FILE=1
		shift
		;;
                -results-dir=*)
                RESULTS_DIR="${arg#*=}"
                shift
                shift
                ;;
		-prev-metrics-file=*)
		PREV_METRICS="${arg#*=}"
		shift
		shift
		;;
		*)
                OTHER_ARGUMENTS+=("$1")
                echo "[!] ERROR: Argument \"${arg#*=}\" was wrong in collect_training_checks.sh."
                exit
                shift # Remove generic argument from processing
                ;;
	esac
done

NUMBER_OF_FOLDERS=$(ls -l $RESULTS_DIR | grep -v ^l | wc -l)
mkdir -p $DESTINATION_FOLDER

if [ -z "$NUMBER_PLOT_SAMPLES" ]
then
	NUMBER_PLOT_SAMPLES=0
fi
	

### SEARCH THROUGH THE FOLDERS AND COLLECT IMAGES AND TRAINING METRICS
touch data.tmp
for (( i=1; i<NUMBER_OF_FOLDERS; i++ ))
do
	POSSIBLE_PNG_FOLDER="$(ls $RESULTS_DIR | head -n $i | tail -n 1)"
	PNG_IMAGES=($(ls $RESULTS_DIR/$POSSIBLE_PNG_FOLDER/ | grep .png))
	if [ -f "$RESULTS_DIR/$POSSIBLE_PNG_FOLDER/metric-fid50k.jsonl" ]
	then
		cat $RESULTS_DIR/$POSSIBLE_PNG_FOLDER/metric-fid50k.jsonl >> data.tmp
	fi
	if [ $COLLECT_IMAGES -eq 1 ]
	then
		for IMAGE in "${PNG_IMAGES[@]}"
		do
			echo "[+] Collecting $IMAGE in $POSSIBLE_PNG_FOLDER [folder $((i+1))/$NUMBER_OF_FOLDERS]"
			cp $RESULTS_DIR/$POSSIBLE_PNG_FOLDER/$IMAGE $DESTINATION_FOLDER/$POSSIBLE_PNG_FOLDER.$IMAGE
		done
	fi
done


### POSPROCESS TRAINING METRICS AND DROP IT INTO A SINGLE FILE
echo "[+] Processing metrics data."

THRESHOLD=0
PREV_TIC=0
if [ -z $PREV_METRICS ]; then
        touch data2.tmp
else
        cp $PREV_METRICS ./data2.tmp
	PREV_TIC=($(tail -n 1 data2.tmp | grep -Eo '[0-9]{1,10}'))
	PREV_TIC=${PREV_TIC[0]}
fi

DATA=($(cat data.tmp | grep -Eo '[0-9]{1,10}'))
NUM_SAMPLES=$(cat data.tmp | wc -l)
THRESHOLD=0
for (( i=k; i<NUM_SAMPLES; i++ ))
do
	TIC=${DATA[$((i*14+11))]}
	TIC=$((10#$TIC))
	TIC=$((TIC + PREV_TIC))

	FID="${DATA[$((i*14+1))]}.${DATA[$((i*14+2))]}"
	LINE="$TIC $FID"
	PREV_TIC=$TIC
	$(echo $LINE >> data2.tmp)
done
echo "	[-] Collected a total of $(cat data2.tmp | wc -l) metrics samples."


### PRODUCE A PLOT WITH THE TRAINING METRICS

echo "[+] Creating plot."
singularity exec $SINGULARITY_IMAGE_PATH python3 << END
import matplotlib.pyplot as plt

X, Y = [], []
for line in open('data2.tmp', 'r'):
	values = [float(s) for s in line.split()]
	X.append(values[0])
	Y.append(values[1])

X=X[-int($NUMBER_PLOT_SAMPLES):len(X)]
Y=Y[-int($NUMBER_PLOT_SAMPLES):len(Y)]

print("	[-] Printing last " + str(len(X)) + " metrics samples.")

plt.plot(X, Y, linewidth=1.0)
plt.title('Training Progress')
plt.xlabel('tics')
plt.ylabel('FID')
plt.savefig('progress.png', dpi=1500)
END

mv progress.png $DESTINATION_FOLDER/progress.png

if [ $SAVE_DATA_FILE -eq 1 ]
then
	cp data2.tmp $DESTINATION_FOLDER/metrics_data.dat
fi

rm data.tmp
rm data2.tmp


echo "done"
