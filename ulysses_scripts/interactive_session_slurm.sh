#!/bin/bash


srun -p gpu2 --gpus-per-node=2 -N1 -n10 --time 12:00:00 --mem 63500M --pty bash
# CMD="srun -p regular2 --time 01:00:00 --pty bash"
