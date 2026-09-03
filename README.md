# Generating and Evaluating Metacell Atlases
All single-cell datasets are stored in /media/ResearchHome/plummgrp/home/common/Maggie/QuantumCell/cellxgene

## Setting Up Metacell Environment
If you are working in the lab server, use:

`conda activate metacell_MA`

If you are working on the HPC, you will have to make your own environment using:

`conda env create -f metacell_env.yml`

## Cleaning data
Open clean_data.ipynb and follow instructions

## Running Metacell2
Since we're running metacell with multiple target sizes, I would recommend using the cluster

Run the following command to submit run_metacell.sh as a job on the HPC

`./sender_metacell.sh dataset min_metacell_size max_metacell_size interval_size filter_lateral`

Only add filter_lateral if filtering lateral genes.

Here's an example with the Human Breast Cell Atlas (HBCA) without filtering lateral genes:

`./sender_metacell.sh hbca 100 200 10`

Note: Metacell will throw an error is min_metacell_size is less than 12. I usually just go with 20

After Metacell finishes, check for any errors in metacell_organ.err and metacell_organ.out

If one of the sizes gets skipped (i.e. no metacell object or cell membership .csv got generated for that size), try lowering select_min_genes in mc.pl.divide_and_conquer_pipeline.

If it just kinda stops on a size without ever finishing... Let me know.

## Getting single-cell membership file
Run the following to get "cell_membership.csv". This will contain which single cells were assigned to which metacells for each metacell size

`python get_cell_membership.py dataset --filter_lateral`

Example with HBCA without filtering lateral:

`python get_cell_membership.py hbca`

## Running mcRigor
On the HPC, install R 4.3.1

`module load R/4.3.1`

Open R on HPC and install mcRigor using:

`install.packages("/research_jude/rgs01_jude/groups/plummgrp/home/common/Maggie/QuantumCell/mcRigor", repos = NULL, type = "source")`

Run the following command to submit run_mcrigor.sh as a job on the HPC

`./sender_mcrigor.sh organ filter_lateral`

Example with HBCA without filtering lateral:

`./sender_mcrigor.sh hbca`

Check for errors in mcrigor_organ.err and mcrigor_organ.out

## Visualizing Metacell and mcRigor results
Open mcrigor_visualization.Rmd and follow instructions. I use NoMachine for this.

If you need to install mcRigor on lab server:

`install.packages("/media/ResearchHome/plummgrp/home/common/Maggie//QuantumCell/mcRigor", repos = NULL, type = "source")`
