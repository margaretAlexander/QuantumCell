#!/bin/bash
input=$(echo $1) # dataset to run metacell on

sed "s/input/$input/g" < run_mcrigor.sh | bsub
