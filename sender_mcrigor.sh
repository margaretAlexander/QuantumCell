#!/bin/bash
input=$(echo $1) # dataset to run mcrigor on (must have already run metacell at more than one size)
filter_lateral=$(echo $2) # whether lateral genes were filtered in metacell

sed -e "s/input/$input/g" \
    -e "s/filter_lateral/$filter_lateral/g" < run_mcrigor.sh | bsub
