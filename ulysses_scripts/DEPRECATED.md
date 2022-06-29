# Deprecated scripts documentation

In this document there is the documentation of deprecated scripts. In principle features of these scripts are performed by other newer script. The use of these scripts is not recommended since them can contain bugs and other type of problems. However, codes could be useful for new script production.

* **Current scripts documentation can be found [here](./README.md).**

## 1. Root folder's scripts

Anything at the moment.

## 2. Dataset preparation scripts

### 2.1 manage_RGB_converting

This script manages the conversion from RGBA to RGB images within a directory. It manages some Slurm features and works as a wrapper for RGBA_to_RGB.py script. 

####    2.1.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:
  - `scripts_folder$ sbatch -p <Slurm queue> --time=XX:XX:XX -nXX -NXX dataset_preparation/deprecated/manage_RGB_converting.sh `

####    2.1.2 Settings

* Via flags:
  * `-id=<job id>`: Specifies the id of a previous manage_RGB_converting.sh slurm finished job. This is useful to automatically read the last converted image from `slurm.*.out` file and resume the learning.
* Via variables:
  * Slurm's mail variables
  * `IN_DIRECTORY`: Path to RGBA images folder. Must be absolute.
  * `OUT_DIRECTORY:` Path to RGB output images folder. Must be absolute. It must exists, cannot be created.
  * `SINGULARITY_IMAGE_PATH:` Path to singularity image containing the software. Must be absolute.

####    2.1.3 Output

* Images will be dropped in the specified `OUT_DIRECTORY`.

### 2.2 manage_cropping.sh

This script make crops of specified resolution from images contained in a directory, generating images of the same resolution. It works as a wrapper of uniform_images.py script.

####    2.2.1 Usage

- After loaded singularity module, it can be committed into a Slurm job as following:
  - `scripts_folder$ sbatch -p <Slurm queue> --time=XX:XX:XX -nXX -NXX dataset_preparation/deprecated/manage_cropping.sh `

####    2.2.2 Settings

* Via variables:
  * Slurm's mail variables
  * `INPUT_DIRECTORY`: Path to RGBA images folder. Must be absolute.
  * `OUTPUT_DIRECTORY:` Path to RGB output images folder. Must be absolute. It must exists, cannot be created.
  * `SINGULARITY_IMAGE_PATH:` Path to singularity image containing the software. Must be absolute.
  * `CONTINUE_FROM:` Name of the last processed file in a previous run. It will continue from this file.

####    2.2.3 Output

* Images will be dropped in the specified `OUTPUT_DIRECTORY`.

## 3. Training scripts

Anything at the moment.

## 4. Projection scripts

Anything at the moment.
