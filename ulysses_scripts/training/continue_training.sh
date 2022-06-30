#!/bin/bash
#SBATCH -N2	
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=2
#SBATCH --time 12:00:00
#SBATCH --mem=63500M
#SBATCH --mail-user="fernandez.fisica@gmail.com"
#SBATCH --mail-type=ALL

### change 5-digit MASTER_PORT as you wish, slurm will raise Error if duplicated with others
### change WORLD_SIZE as gpus/node * num_nodes
export MASTER_PORT=12340
export WORLD_SIZE=4
master_addr=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export MASTER_ADDR=$master_addr
#export SCRATCH=/scratch/jfernand/temp
export SCRATCH=$SINGULARITY_TMPDIR

SINGULARITY_IMAGE_PATH=/scratch/jfernand/container_pytorch.sif

DATASET_DIR="/scratch/jfernand/blasphemous/datasets/extended_data_512.zip"
RESULTS_DIR="/scratch/jfernand/blasphemous/results"
TRAINING_FLAGS="--cfg=auto --mirror=1 --aug=ada --metrics=fid50k --snap=10"
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
                -training-flags=*)
                TRAINING_FLAGS="${arg#*=}"
                TRAINING_FLAGS="${TRAINING_FLAGS//¬/ }"
                shift
                shift
                ;;
                *)
                echo "[!] ERROR: Passed wrong argument \"${arg#*=}\" in continue_training.sh."
                exit
                shift # Remove generic argument from processing
                ;;
        esac
done

CURRENT_DIR=$(pwd)
cd /scratch

i=1
LAST_PKL=""
while [ -z "$LAST_PKL" ]
do
	LAST_PKL_FOLDER="$(ls $RESULTS_DIR | tail -n $i | head -n 1)"
	LAST_PKL="$(ls $RESULTS_DIR/$LAST_PKL_FOLDER/ | grep network-snapshot | tail -n 1)"
	PKL_PATH="$RESULTS_DIR/$LAST_PKL_FOLDER/$LAST_PKL"
	((i++))
done
echo "[+] Resuming training on file $PKL_PATH."

CMD="python3 $CURRENT_DIR/../train.py --gpus=4 --data=$DATASET_DIR --outdir=$RESULTS_DIR --resume=$PKL_PATH"
CMD="$CMD $TRAINING_FLAGS"

echo "singularity exec --nv $SINGULARITY_IMAGE_PATH $CMD"
singularity exec --nv $SINGULARITY_IMAGE_PATH $CMD
