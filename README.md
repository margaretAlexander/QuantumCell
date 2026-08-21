# Generating and Evaluating Metacell Atlases
All single-cell datasets are stored in /media/ResearchHome/plummgrp/home/common/Maggie/QuantumCell/cellxgene

## Cleaning data
Open clean_data.ipynb and follow instructions

## Running Metacell2
Since we're running metacell with multiple target sizes, I would recommend using the cluster

Run the following command to submit run_metacell.sh as a job on the HPC

`./sender_metacell.sh organ min_metacell_size max_metacell_size interval_size filter_lateral`

Note: Metacell will throw an error is min_metacell_size is less than 12. I usually just go with 20

After Metacell finishes, check for any errors

If one of the sizes gets skipped (i.e. no metacell object or cell membership .csv got generated for that size), this can be fixed by lowering select_min_genes in mc.pl.divide_and_conquer_pipeline.

If it just kinda stops on a size... Let me know.

## Running mcRigor
Use get_cell_membership.ipynb to generate cell membership files for all the metacell sizes

Run the following command to submit run_mcrigor.sh as a job on the HPC

`./sender_mcrigor.sh organ`

## Visualizing Metacell and mcRigor results
Open mcrigor_visualization.Rmd and follow instructions

## Comparing metacell vs. single-cell
- metacell vs. single-cell cell type proportions
- using singleR to annotate original single-cell with metacell
- using singleR to annotate new single-cell with original single cell and metacell
