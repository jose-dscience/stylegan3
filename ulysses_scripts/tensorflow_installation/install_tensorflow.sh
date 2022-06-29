#!/bin/bash

echo y | conda create -n tf_1.14 tensorflow=1.14 &>> output.out &
echo y | conda install requests &>> output.out &
