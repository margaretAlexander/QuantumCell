import anndata as ad             # For reading/writing AnnData files
import matplotlib.pyplot as plt  # For plotting
import metacells as mc           # The Metacells package
import numpy as np               # For array/matrix operations
import pandas as pd              # For data frames
import os                        # For filesystem operations
import seaborn as sb             # For plotting
import scipy.sparse as sp        # For sparse matrices
import shutil                    # for filesystem operations
from math import hypot           # For plotting
from Ensembl_converter import EnsemblConverter                      # For getting gene symbols
import scanpy as sc
import sys
import argparse
import gseapy as gp # try importing gene sets as lateral genes instead?
from gseapy import Msigdb
from typing import List


parser = argparse.ArgumentParser(description='idk what to write')
parser.add_argument('--dataset_name', type=str, required=True, help='Name of single cell dataset')
parser.add_argument('--metacell_size', type=int, required=True, help='Traget size for metacells')
parser.add_argument('--filter_lateral', action='store_true')
args = parser.parse_args()

# constants
dataset_name = args.dataset_name
metacell_size = args.metacell_size

# We'll reuse this through the iterations.
# It is just a thin wrapper for mark_lateral_genes,
# and optionally also shows the results.
def update_lateral_genes(
    *,
    names: List[str] = [],
    patterns: List[str] = [],
    op: str = "set",
    show: bool = True
) -> None:
    mc.pl.mark_lateral_genes(
        cells,
        lateral_gene_names=names,
        lateral_gene_patterns=patterns,
        op=op
    )

    if not show:
        return
    
    lateral_genes_mask = mc.ut.get_v_numpy(cells, "lateral_gene")
    lateral_gene_names = set(cells.var_names[lateral_genes_mask])
    
    print(sorted([
        name for name in lateral_gene_names
        if not name.startswith("RPL") and not name.startswith("RPS")
    ]))

    print(f"""and {len([
        name for name in lateral_gene_names if name.startswith("RPL") or name.startswith("RPS")
    ])} RP[LS].* genes""")


if args.filter_lateral:
    OUTPUT_DIR = dataset_name + '_metacells/one_pass/'
    
    # get lateral gene list
    msig = Msigdb()
    
    hypoxia = msig.get_gmt(category='h.all', dbver="2025.1.Hs")['HALLMARK_HYPOXIA']
    cell_cycle = msig.get_gmt(category='c2.cp.kegg_legacy', dbver="2025.1.Hs")['KEGG_CELL_CYCLE']
    stress =  msig.get_gmt(category='c5.go.bp', dbver="2025.1.Hs")['GOBP_CELLULAR_RESPONSE_TO_STRESS']
    
    lateral_gene_sets = cell_cycle
    lateral_gene_sets = list(set(lateral_gene_sets))
        
    LATERAL_GENE_NAMES = lateral_gene_sets
    LATERAL_GENE_PATTERNS = ["RP[LS].*"]  # Ribosomal
else:
    OUTPUT_DIR = dataset_name + '_metacells/with_lateral/'
    LATERAL_GENE_NAMES = []
    LATERAL_GENE_PATTERNS = []
    
if not os.path.isdir(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR, exist_ok=True)

# read clean data
clean = ad.read_h5ad("metacell_clean/" + dataset_name + ".clean.h5ad")

# compute metacells
cells = clean
clean = None  # Allow it to be gc-ed
mc.ut.set_name(cells, dataset_name + "_" + str(metacell_size) + ".one-pass.preliminary.cells")
print(f"Input: {cells.n_obs} cells, {cells.n_vars} genes")

update_lateral_genes(names=LATERAL_GENE_NAMES, patterns=LATERAL_GENE_PATTERNS)

# parallelization
# Either use the guesstimator:
max_parallel_piles = mc.pl.guess_max_parallel_piles(cells)
# Or, if running out of memory manually override:
# max_paralle_piles = ...
print(max_parallel_piles)
mc.pl.set_max_parallel_piles(max_parallel_piles)

# assigning cells to metacells
mc.pl.divide_and_conquer_pipeline(cells, 
                                  random_seed=123456,
                                  target_metacell_size=metacell_size)

# collecting metacells
metacells = \
    mc.pl.collect_metacells(cells, name=dataset_name + "_" + str(metacell_size) + ".one-pass.preliminary.metacells", random_seed=123456)
print(f"Preliminary: {metacells.n_obs} metacells, {metacells.n_vars} genes")

for cat in cells.obs.columns:
    # Assign a single value for each metacell based on the cells.
    mc.tl.convey_obs_to_group(
        adata=cells, gdata=metacells,
        property_name=cat, 
        method=mc.ut.most_frequent  # This is the default, for categorical data
    )

# compute for mcview
with mc.ut.progress_bar():
    mc.pl.compute_for_mcview(adata=cells, gdata=metacells, random_seed=123456)

metacells.write_h5ad(OUTPUT_DIR + dataset_name + "_" + str(metacell_size) + ".metacells.h5ad")

cell_membership = pd.DataFrame(cells.obs['metacell_name'])
cell_membership.to_csv(OUTPUT_DIR + dataset_name + "_" + str(metacell_size) + "_cell_membership.csv")

