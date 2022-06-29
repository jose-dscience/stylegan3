#!/bin/bash

echo y | conda clean --packages
echo y | conda remove --name tf_1.14 --all
conda clean --index-cache
