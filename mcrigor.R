library(Seurat)
library(SeuratDisk)
library(SeuratData)
library(ggplot2)
library(BPCells)
library(Rcpp)
library(mcRigor)

# user provides dataset name
args <- commandArgs(trailingOnly = TRUE)

dataset_name = args[1]
filter_lateral = args[2]

quantumcell_dir <- "/research_jude/rgs01_jude/groups/plummgrp/home/common/Maggie/QuantumCell/"
sc_input_dir <- paste0(quantumcell_dir, "metacell_clean/")

if (filter_lateral) {
  mc_input_dir <- paste0(quantumcell_dir, dataset_name, "_metacells/one_pass")
  }
else {
  mc_input_dir <- paste0(quantumcell_dir, dataset_name, "_metacells/with_lateral")
}

# load single cell data
tryCatch(
  expr = {
    # try schard for easy loading
    sc_seurat <- schard::h5ad2seurat(paste0(sc_input_dir, dataset_name, ".clean.h5ad"))
  },
  error = function(e) {
    # back up if object is too large
    print("Single cell object was too large to be loaded with schard. Using BPCells instead.")
    
    if (!file.exists(paste0(sc_input_dir, dataset_name, ".clean_BP"))) {
      data <- open_matrix_anndata_hdf5(paste0(sc_input_dir, dataset_name, ".clean.h5ad"))
      write_matrix_dir(
        mat = data,
        dir = paste0(sc_input_dir, dataset_name, ".clean_BP"))
    } 
    
    mat <- open_matrix_dir(dir = paste0(sc_input_dir, dataset_name, ".clean_BP"))
    metadata <- read.csv(paste0(sc_input_dir, dataset_name, "_metadata.csv"), header = T, row.names = 1)
    
    sc_seurat <- CreateSeuratObject(counts = mat, meta.data = metadata)
  }
)

# load metacell partitions
cell_membership_all <- read.csv(file = paste0(mc_input_dir, "/cell_membership.csv"), check.names = F, row.names = 1)
                                  
while (!file.exists(paste0(mc_input_dir, "opt_res.rds"))){
    # optimization of hyperparameters
    start.time <- Sys.time()
    optimize_res = mcRigor_OPTIMIZE(obj_singlecell = sc_seurat, 
                                    cell_membership = cell_membership_all,
                                    pur_metric = 'cell_type',
                                    fields = 'cell_type')
    
    end.time <- Sys.time()
    time.taken <- end.time - start.time
    print(paste0("Hyperparameter optimization took: ", time.taken))
    saveRDS(optimize_res, file = paste0(mc_input_dir, "opt_res.rds")) 
} 

if(file.exists(paste0(mc_input_dir, "opt_res.rds"))){
  # load optimal metacell if it's already there
  optimize_res <- readRDS(paste0(mc_input_dir, "opt_res.rds"))  

  # check that it uses the same metacell partitions as the ones used for metacell construction
  if(!identical(optimize_res[["scores"]][["gamma"]], colnames(cell_membership_all))){
    # optimization of hyperparameters
    start.time <- Sys.time()
    optimize_res = mcRigor_OPTIMIZE(obj_singlecell = sc_seurat, 
                                    cell_membership = cell_membership_all,
                                    pur_metric = 'cell_type',
                                    fields = 'cell_type')
    end.time <- Sys.time()
    time.taken <- end.time - start.time
    print(paste0("Hyperparameter optimization took: ", time.taken))
    saveRDS(optimize_res, file = paste0(mc_input_dir, "opt_res.rds")) 
  }
} else{
  # optimization of hyperparameters
    start.time <- Sys.time()
    optimize_res = mcRigor_OPTIMIZE(obj_singlecell = sc_seurat, 
                                    cell_membership = cell_membership_all,
                                    pur_metric = 'cell_type',
                                    fields = 'cell_type')
    end.time <- Sys.time()
    time.taken <- end.time - start.time
    print(paste0("Hyperparameter optimization took: ", time.taken))
    saveRDS(optimize_res, file = paste0(mc_input_dir, "opt_res.rds")) 
}

opt_metacell <- optimize_res$opt_metacell
sc_membership = opt_metacell@misc$cell_membership$Metacell
names(sc_membership) = rownames(opt_metacell@misc$cell_membership)

# re-partition single-cells in dubious metacells to be more "trustworthy"
step1_res = mcRigorTS_Step1(obj_singlecell = sc_seurat, 
                            sc_membership = sc_membership, 
                            TabMC = optimize_res$TabMC, 
                            fields = 'cell_type',
                            method = 'mc2')

cell_membership_twostep = cell_membership_all[ , as.numeric(names(cell_membership_all)) < optimize_res$best_granularity_level]
cell_membership_twostep = cell_membership_twostep[colnames(step1_res$obj_sc_dub),]

step2_res = mcRigorTS_Step2(step1_res = step1_res, 
                            obj_singlecell = sc_seurat, 
                            cell_membership_twostep = cell_membership_twostep,
                            fields = 'cell_type',
                            method = 'mc2',
                            color_field = 'cell_type')

saveRDS(step2_res, file = paste0(mc_input_dir, "2step_res.rds"))
