# Scripts to use the model in Ulysses

In this folder there is a collection of script to run the model in Ulysses (or any HPC cluster with slurm). Scripts are divided in different folders. However, them should be **always launched** from script folders (never from subfolders). Folders are organised for the different taps of the learning/usage process.

Documentation of old deprecated scripts is  not present in this document. 

* **Documentation of deprecated scripts can be found [here](./DEPRECATED.md).**





## 1. Root folder's scripts

### 1.1 commit_training_jobs.sh

This script manages the committing of different jobs of the training.

#### 	1.1.1 Usage

- `scripts_folder$ ./commit_training_jobs.sh`

#### 	1.1.2 Settings

- Settings are set via script modification. Variables are the following:
  - `RESUME_TRAINING`: 1 for resume the last started training and 0 for start a new one. 
  - `SCRIPT_PATH_1`: Path of "checking" script, to be launched previously to the training script.
  - `SCRIPT_PATH_2`: Path to the script that starts the learning process.
  - `SCRIPT_PATH_3`: Path to the script that continues the learning process.
  - `NUMBER_JOBS`: Number of jobs to launch in order to perform the whole learning process. For example,  with `RESUME_TRAINING=0`, `NUMBER_JOBS=3` means that `SCRIPT_PATH_2` will be executed once and `SCRIPT_PATH_3` once.
  - `TIME`: Wall-time for Slurm job.
  - `QUEUE`: Slurm's queue.
  - `EMAIL`: Slurm's email notification adress.
  - `DATASET_DIR`: Dataset files directory.
  - `RESULTS_DIR`: Directory in which results will be dropped.
  - `NAME`: Name of Slurm's job. 
  - `TRAINING_FLAGS`: String containing additional flags to be passed to training script (train.py). Are overlapped by `scripts_folder$ ./other/configs.sh` ones.
- Via flags:
  - `-config=<CONFIG LIST VALUE>`: Specifies a configuration for script runs of `other/config.sh` script. This overlaps default variables but not provided ones via flag.
  - `-data-dir=<DATASET DIRECTORY>`: Specifies the dataset directory, overlapping subscripts default one.
  - `-results-dir=<RESULTS DIRECTORY>`: Specifies the results directory, overlapping subscripts default one.
  - `-name=<JOB NAME>`: Specifies a name for learning jobs.
  - `-start`: Training process will be started from zero instead of be continued from the last pkl.
  - `-cancel`: Cancel submitted jobs  belonging to a provided config profile. Must be use together to the flag `-config`.
  - `-n`: Set the number of new jobs to be submitted. It overlaps `NUMBER_JOBS` variable.
  - `-after=<JOB ID>`: Submitted jobs will start after the indicated one.
    - `-after=last`: If used `last` value, It will be taken the last committed job to continue from. If `-config` flag is used, it will be taken the last job with the same config profile name.

### 1.2 collect_training_checks.sh

This script collects the images ("fakes" and "reals") spread in the different results directories into a new one.

#### 	1.2.1 Usage

- `scripts_folder$ ./collect_training_checks.sh`

####    1.2.2 Settings

- Via script variables:
  - `DESTINATION_FOLDER`: Folder in which images will be collected.
  - `RESULTS_DIR`: Folder in which the results of the training are dropped.
- Via flags:
  - `-config=<CONFIG LIST VALUE>`: Specifies a configuration for script runs of `other/config.sh` script. This overlaps default variables but not provided ones via flag.
  - `-no-images`: Avoid to copy "fakes" and "real" images from snapshot's directory
  - `-plot-last-samples=<number of samples>`: Restricts the metrics plot to the last specified number of snapshots.
  - `-save-metrics-data`: Saves a file with the metrics data.  It can be found at `DESTINATION_FOLDER` with the name `metrics_data.dat`. 
  - `-results-dir=<directory containing the results directories>`: Overlaps `RESULTS_DIR` variables.
  - `-prev-metrics-file=<path to file with old metrics data>`: Add the collected metrics data to data of an older file.

####    1.2.3 Output

* Results are stored in the set folder.

### 1.3 monitor_job.sh

Monitor Slurm's job activity.

#### 	1.3.1 Usage

- `scripts_folder$ ./monitor_job.sh`

####    1.3.2 Settings

- Via flags:
  - `-config=<CONFIG LIST VALUE>`: Specifies a configuration profile of `other/config.sh` script. It restrict the shown jobs to the specified one.

####    1.3.3 Output

* Results are stored in the set folder.





## 2. Dataset preparation scripts

### 2.1 preprocess_images.sh

This script uses the spritesheets and the metadata file to crop the different sprites from the spritesheet. It also takes generic images on png or gif format and makes it to have the desired resolution by making crops or extending the resolution. Resolution is extended by filling new pixels with black. If an animated gif image is processed, it is splitted into its individual frames.

####    2.1.1 Usage

- The script must be dropped first in the folder in the folder in which the spritesheets are contained. Then, it can be executed with the following command:
  - `spritesheets_folder$ ./preprocess_images.sh`

####    2.1.2 Settings

* Via flags
  * `-width=<new width>`: New width for the image. This parameter crop or extends the image, maintaining it centered.
  * `-height=<new height>`: New height for the image. This parameter crop or extends the image, maintaining it centered.
  * `-indir=<input directory>`: Directory containing the input images. By default it is `.`.
  * `-outdir=<output directory>`: Directory in which images will be dropped. `./cropped`.
  * `-no-alpha`: Cropped images will substitute alpha channel by black.
  * `-ignore-meta-png`: Ignore Blasphemous spritesheets with meta file when processing images.
  * `-ignore-png`: Ignore generic png images (except Blasphemous png images with metafile) when processing images.
  * `-ignore-gif`: Ignore gif images when processing images.
  * `-skip-meta-png=<INT NUMBER>`: Skip some first elements of png with metafiles.
  * `-skip-png=<INT NUMBER>`: Skip some first elements of png without metafiles.
  * `-skip-gif=<INT NUMBER>`: Skip some first gif elements.

####    2.1.3 Output

* Sprites will be dropped in the folder `spritesheets_folder/output`.

### 2.2 create_dataset.sh

This script creates a tf dataset by using RGB images in a directory with the same size. Usually images should be preprocessed by 2.1 script.

####    2.2.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:
  - `scripts_folder$ sbatch dataset_preparation/create_dataset.sh `

####    2.2.2 Settings

* Via variables:
  * Slurm's mail and job variables
  * `DATASET_PATH`: Directory in which the dataset will be created. Must be absolute.
  * `IMAGES_PATH:` Path to RGB images with equal size folder. Must be absolute.
  * `SINGULARITY_IMAGE_PATH:` Path to singularity image containing the software. Must be absolute.
* Via flags:
  * `-config=<CONFIG LIST VALUE>`: Specifies a configuration for script runs of `other/config.sh` script. This overlaps default variables but not provided ones via flag.
  * `-images-dir=<DIR>`: Specifies the directory containing the clean images (i.e. with final resolution and not alpha-channel).

####    2.2.3 Output

* A collection of folders with pkl files and other information created inside of `DATASET_PATH`.

### 2.3 check_preprocessed_images.sh

Check dimensions of pre-processed images in order to avoid future bugs. It have the feature of deleting wrong files.

####    2.3.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:
  - `scripts_folder$ sbatch dataset_preparation/check_preprocessed_images.sh `

####    2.3.2 Settings

* Via flags:
  * `-width=<INT NUMBER>`: Specify the desired width for the images. If not used, it is taken the first image's one.
  * `-heigh=<INT NUMBER>`: Specify the desired height for the images. If not used, it is taken the first image's one.
  * `-dir=<PATH TO IMAGES>`: Directory in which images will be found. If not specified it is used the current directory.
  * `-logfile-path=<PATH TO LOG FILE'S FOLDER>`: Path in which a logfile "wrong_images.log" will be created.
  * `-remove`: Remove wrong detected files.

####    2.3.3 Output

* Information in the standard output and eventually in a log file. 





## 3. Training scripts

### 3.1 check_training.sh

Checks if the training settings are correct.

####    3.1.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:

  - `scripts_folder$ sbatch -p <queue> training/check_training.sh `

  Is convenient to not use this script, but 1.1 instead.

####    3.1.2 Settings

* Via variables:
  * Slurm's mail and job variables
  * `DATASET_DIR`: Path to the dataset directory. Must be absolute.
  * `RESULTS_DIR`; Path to the directory containing the results.
  * `SINGULARITY_IMAGE_PATH`; Path to singularity image containing the software. Must be absolute.
  * `TRAINING_FLAGS`: Additional flats to the training script. Is overlapped by flag-passed ones.
  * `RESUME_KIMG`: Kimg in which the training will be resumed. Is overlapped by flag-passed one.
* Via flags:
  * `-data-dir=<DATASET DIRECTORY>`: Overlaps the variable `DATASET_DIR`.
  * `-results-dir=<RESULTS DIRECTORY>`: Overlaps the variable `RESULTS_DIR`.
  * `-transfer=<TRANSFER LEARNING PKL DIRECTORY>`: Specifies the path pkl with a pretrained starting model.
  * `-training_flags=<ADDITIONAL TRAINING FLAGS STRING>`: Permit the addition of flags to the training script.
  * `-resume-kimg=<INT KIMG>`: Kimg (kilo images) from which the simulation will continue.

####    3.1.3 Output

* Information about the run in the shell.

### 3.2 start_training.sh

Starts if the training settings are correct.

####    3.2.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:

  - `scripts_folder$ sbatch -p <queue> training/start_training.sh `

  Is convenient to not use this script, but 1.1 instead.

####    3.2.2 Settings

* Via variables:
  * Slurm's mail and job variables
  * `DATASET_DIR`: Path to the dataset directory. Must be absolute.
  * `RESULTS_DIR:` Path to the directory containing the results.
  * `SINGULARITY_IMAGE_PATH:` Path to singularity image containing the software. Must be absolute.
  * `TRAINING_FLAGS`: Additional flats to the training script. Is overlapped by flag-passed ones.
  * `RESUME_KIMG`: Kimg in which the training will be resumed. Is overlapped by flag-passed one.
* Via flags:
  * `-data-dir=<DATASET DIRECTORY>`: Overlaps the variable `DATASET_DIR`.
  * `-results-dir=<RESULTS DIRECTORY>`: Overlaps the variable `RESULTS_DIR`.
  * `-transfer=<TRANSFER LEARNING PKL DIRECTORY>`: Specifies the path pkl with a pretrained starting model.
  * `-training_flags=<ADDITIONAL TRAINING FLAGS STRING>`: Permit the addition of flags to the training script.
  * `-resume-kimg=<INT KIMG>`: Kimg (kilo images) from which the simulation will continue.

####    3.2.3 Output

* Pkl's and other information will be dropped in subfolders of `RESULTS_DIR` specified path.

### 3.3 continue_training.sh

Search the last run and continue it.

####    3.3.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:

  - `scripts_folder$ sbatch -p <queue> training/continue_training.sh `

  Is convenient to not use this script, but 1.1 instead.

####    3.3.2 Settings

* Via variables:
  * Slurm's mail and job variables
  * `DATASET_DIR`: Path to the dataset directory. Must be absolute.
  * `RESULTS_DIR:` Path to the directory containing the results.
  * `SINGULARITY_IMAGE_PATH:` Path to singularity image containing the software. Must be absolute.
* Via flags:
  * `-data-dir=<DATASET DIRECTORY>`: Overlaps the variable `DATASET_DIR`.
  * `-results-dir=<RESULTS DIRECTORY>`: Overlaps the variable `RESULTS_DIR`.
  * `-training_flags=<ADDITIONAL TRAINING FLAGS STRING>`: Permit the addition of flags to the training script.

####    3.3.3 Output

* Pkl's and other information will be dropped in subfolders of `RESULTS_DIR` specified path.





## 4. Projection scripts

### 4.1 commit_projections.sh

- Projects a set of images over the last snapshot of a learning.

####    4.1.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:

  - `scripts_folder$ sbatch projection/commit_projections.sh `


####    4.1.2 Settings

* Via variables:
  * Slurm's mail and job variables.
  * `RESULTS_DIR:` Path to the directory containing the results.
  * `INPUT_DIR`: Directory containing the images to be projected.
  * `OUTPUT_DIR`: Directory in which images will be projected.
  * `SINGULARITY_IMAGE_PATH:` Path to singularity image containing the software. Must be absolute.
* Via flags:
  * `-config=<CONFIG LIST VALUE>`: Specifies a configuration for script runs of `other/config.sh` script. This overlaps default variables but not provided ones via flag.
  * `-indir=<INPUT DIR>`: Overlaps the variable `INPUT_DIR`.
  * `-outdir=<OUTPUT DIR>`: Overlaps the variable `OUTPUT_DIR`.
  * `-results-dir=<RESULTS DIR>`: Overlaps the variable `RESULTS_DIR`.

####    4.1.3 Output

* Projected images and additional information is generated in `OUTPUT_DIR` 's subfolders with original image's names.

