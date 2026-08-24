#!/bin/bash
#BSUB -J mcrigor_input
#BSUB -P mcrigor_input
#BSUB -oo input_metacells/mcrigor_input.out -eo input_metacells/mcrigor_input.err
#BSUB -n 3
#BSUB -R a100_80g
#BSUB -q gpu
#BSUB -M 240G
#BSUB -gpu "num=1/host"

module load R/4.3.1
module load HDF5/1.14.3-gompi-2023b
export LD_LIBRARY_PATH="/hpcf/authorized_apps/rhel8_apps/R/4.3.1/install/lib64/R/lib:/hpcf/authorized_apps/rhel8_apps/easybuild/software/GCCcore/13.2.0/lib64:$EBROOTHDF5/lib:$LD_LIBRARY_PATH"

Rscript mcrigor.R input

if [ -z "$filter_lateral" ]; then
	Rscript mcrigor.R input --filter_lateral
else
	Rscript mcrigor.R input
fi
