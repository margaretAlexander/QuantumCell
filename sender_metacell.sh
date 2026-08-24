#!/bin/bash
input=$(echo $1) # dataset to run metacell on
min_size=$(echo $2) # min metacell size
max_size=$(echo $3) # max metacell size
interval=$(echo $4) # interval between metacell sizes
filter_lateral=$(echo $5) # whether to filter lateral genes

sed -e "s/input/$input/g" \
    -e "s/min_size/$min_size/g" \
    -e "s/max_size/$max_size/g" \
    -e "s/interval/$interval/g" \
    -e "s/filter_lateral/$filter_lateral/g" < run_metacells_test.sh | bsub
