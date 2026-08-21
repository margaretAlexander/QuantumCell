#!/bin/bash
input=$(echo $1) # dataset to run mcrigor on (must have ran metacell already and generated cell membership file)

sed "s/input/$input/g" < run_mcrigor.sh | bsub
