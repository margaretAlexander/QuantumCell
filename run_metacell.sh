#!/bin/bash
#BSUB -J metacell_input
#BSUB -P metacell_input
#BSUB -oo input_metacells/metacell_input.out -eo input_metacells/metacell_input.err
#BSUB -n 3
#BSUB -R a100_80g
#BSUB -q gpu
#BSUB -M 240G
#BSUB -gpu "num=1/host"
#BSUB -P test "sleep 100"

module load conda3/202402
module unload conda3/201903
conda activate metacell
PIP_TARGET=/home/malexand/.conda/envs/metacell/lib/python3.9/site-packages/ # change to your metacell environment's path
unset PYTHONPATH

sizes=( {min_size..max_size..interval} )

if [ -z "$filter_lateral" ]; then
	for i in "${sizes[@]}"; do
		python metacell_one_pass.py --dataset_name input --metacell_size $i --filter_lateral
	done
else
	for i in "${sizes[@]}"; do
		python metacell_one_pass.py --dataset_name input --metacell_size $i
	done
fi
