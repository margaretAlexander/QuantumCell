import pandas as pd
from pathlib import Path
import argparse

# constants
parser = argparse.ArgumentParser(description='idk what to write')
parser.add_argument('--dataset_name', type=str, required=True, help='Name of single cell dataset')
parser.add_argument('--filter_lateral', action='store_true')
args = parser.parse_args()

dataset_dir = args.dataset_name + "_metacells/"

if args.filter_lateral:
    OUTPUT_DIR = Path(dataset_dir + "one_pass/")
else:
    OUTPUT_DIR = Path(dataset_dir + "with_lateral/")

# create empty dataframe to hold cell membership data
cell_membership = pd.DataFrame()

# get all cell membership files in directory
files = list(OUTPUT_DIR.rglob('*_cell_membership.csv'))

# add all cell membership data to dataframe
for file in files:
    cells = pd.read_csv(file, index_col = 0)
    cell_membership[int(file.stem.split('_')[1])] = cells['metacell_name']

# sort columns by increasing metacell size
cell_membership = cell_membership.sort_index(axis=1)

# output dataframe as .csv for mcrigor to use
cell_membership.to_csv(OUTPUT_DIR.joinpath('cell_membership.csv'))
