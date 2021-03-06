# Similarity network fusion
## Load packages
library(data.table)
library(dplyr)
library(ggplot2)
library(magrittr)
library(reshape2)
library(SNFtool)

# Array of RepoDB unique drug IDs
repodb.ids <- fread("../data/repoDB_full.csv") %>%
    `$`(drug_id) %>%
    unique()

# PREPROCESSING
# Chemical structure
## Load structure sims as matrix
struct.sim <- fread("../data/chem_similarity.csv") %>%
    as.matrix()

## Convert first column to row names
rownames(struct.sim) <- struct.sim[,1]
struct.sim <- struct.sim[,-1]

## Subset based on RepoDB
struct.sim.repodb <- struct.sim[ ,which(colnames(struct.sim) %in% repodb.ids)]
struct.sim.repodb <- subset(struct.sim.repodb, rownames(struct.sim.repodb) %in% repodb.ids)

## Make elements numeric -- so `affinityMatrix()` won't throw a hissy fit
struct.sim.repodb <- apply(struct.sim.repodb, 2, as.numeric) %>%
    `rownames<-`(., colnames(.))

## Remove NA
struct.sim.repodb <- struct.sim.repodb[rowSums(is.na(struct.sim.repodb)) != ncol(struct.sim.repodb), ]
struct.sim.repodb <- struct.sim.repodb[ ,colSums(is.na(struct.sim.repodb)) < nrow(struct.sim.repodb)]

# Target structure
## Load target similarities as matrix
seq.sim <- fread("../data/target_similarity.csv") %>%
    as.matrix()

## Convert first column to row names
rownames(seq.sim) <- seq.sim[,1]
seq.sim <- seq.sim[,-1]

## Subset based on RepoDB
seq.sim.repodb <- seq.sim[ ,which(colnames(seq.sim) %in% repodb.ids)]
seq.sim.repodb <- subset(seq.sim.repodb, rownames(seq.sim.repodb) %in% repodb.ids)

## Make elements numeric -- so `affinityMatrix()` won't throw a hissy fit
seq.sim.repodb <- apply(seq.sim.repodb, 2, as.numeric) %>%
    `rownames<-`(., colnames(.))

## Remove NA
seq.sim.repodb <- seq.sim.repodb[rowSums(is.na(seq.sim.repodb)) != ncol(seq.sim.repodb), ]
seq.sim.repodb <- seq.sim.repodb[ ,colSums(is.na(seq.sim.repodb)) < nrow(seq.sim.repodb)]

# Pathway similarity
path.sim <- fread("../data/path_similarity_v2.csv") %>%
    as.matrix()

## Convert first column to row names
rownames(path.sim) <- path.sim[,1]
path.sim <- path.sim[,-1]

## Subset based on RepoDB
path.sim.repodb <- path.sim[ ,which(colnames(path.sim) %in% repodb.ids)]
path.sim.repodb <- subset(path.sim.repodb, rownames(path.sim.repodb) %in% repodb.ids)

## Make elements numeric -- so `affinityMatrix()` won't throw a hissy fit
path.sim.repodb <- apply(path.sim.repodb, 2, as.numeric) %>%
    `rownames<-`(., colnames(.))

## Remove NA
path.sim.repodb <- path.sim.repodb[rowSums(is.na(path.sim.repodb)) != ncol(path.sim.repodb), ]
path.sim.repodb <- path.sim.repodb[ ,colSums(is.na(path.sim.repodb)) < nrow(path.sim.repodb)]

# GO BP similarity
bp.sim <- fread("../data/GO_Sim_BP_combined.csv") %>%
    as.matrix()

## Convert first column to row names
rownames(bp.sim) <- bp.sim[,1]
bp.sim <- bp.sim[,-1]

## Subset based on RepoDB
bp.sim.repodb <- bp.sim[ ,which(colnames(bp.sim) %in% repodb.ids)]
bp.sim.repodb <- subset(bp.sim.repodb, rownames(bp.sim.repodb) %in% repodb.ids)

## Make elements numeric -- so `affinityMatrix()` won't throw a hissy fit
bp.sim.repodb <- apply(bp.sim.repodb, 2, as.numeric) %>%
    `rownames<-`(., colnames(.))

## Remove NA
bp.sim.repodb <- bp.sim.repodb[rowSums(is.na(bp.sim.repodb)) != ncol(bp.sim.repodb), ]
bp.sim.repodb <- bp.sim.repodb[ ,colSums(is.na(bp.sim.repodb)) < nrow(bp.sim.repodb)]

# GO CC similarity
cc.sim <- fread("../data/GO_Sim_CC_combined.csv") %>%
    as.matrix()

## Convert first column to row names
rownames(cc.sim) <- cc.sim[,1]
cc.sim <- cc.sim[,-1]

## Subset based on RepoDB
cc.sim.repodb <- cc.sim[ ,which(colnames(cc.sim) %in% repodb.ids)]
cc.sim.repodb <- subset(cc.sim.repodb, rownames(cc.sim.repodb) %in% repodb.ids)

## Make elements numeric -- so `affinityMatrix()` won't throw a hissy fit
cc.sim.repodb <- apply(cc.sim.repodb, 2, as.numeric) %>%
    `rownames<-`(., colnames(.))

## Remove NA
cc.sim.repodb <- cc.sim.repodb[rowSums(is.na(cc.sim.repodb)) != ncol(cc.sim.repodb), ]
cc.sim.repodb <- cc.sim.repodb[ ,colSums(is.na(cc.sim.repodb)) < nrow(cc.sim.repodb)]

# GO MF similarity
mf.sim <- fread("../data/GO_Sim_MF_combined.csv") %>%
    as.matrix()

## Convert first column to row names
rownames(mf.sim) <- mf.sim[,1]
mf.sim <- mf.sim[,-1]

## Subset based on RepoDB
mf.sim.repodb <- mf.sim[ ,which(colnames(mf.sim) %in% repodb.ids)]
mf.sim.repodb <- subset(mf.sim.repodb, rownames(mf.sim.repodb) %in% repodb.ids)

## Make elements numeric -- so `affinityMatrix()` won't throw a hissy fit
mf.sim.repodb <- apply(mf.sim.repodb, 2, as.numeric) %>%
    `rownames<-`(., colnames(.))

## Remove NA
mf.sim.repodb <- mf.sim.repodb[rowSums(is.na(mf.sim.repodb)) != ncol(mf.sim.repodb), ]
mf.sim.repodb <- mf.sim.repodb[ ,colSums(is.na(mf.sim.repodb)) < nrow(mf.sim.repodb)]

# COMMON DRUG ID COLLECTION
## List of processed similarity matrices, convert to distance matrices
mats.repodb <- list(struct.sim.repodb, seq.sim.repodb, path.sim.repodb, bp.sim.repodb, cc.sim.repodb, mf.sim.repodb) %>%
    lapply(., `*`, -1) %>%
    lapply(., `+`, 1)

## Collect row names and subset dist mats by common drug IDs
common.rows <- Reduce(intersect, lapply(mats.repodb, row.names))
red.repodb <- lapply(mats.repodb, function(x) { x[row.names(x) %in% common.rows,] }) %>%
    lapply(., function(x) {x[ ,which(colnames(x) %in% common.rows)]})

# Similarity network fusion
## Set parameters
K <- 20 # K neighbours
alpha <- 0.5 # empirical hyperparameter
t <- 20 # t iterations

## Construct distance graphs
W.all <- lapply(red.repodb, affinityMatrix, K, alpha)

## Fuse distance graphs
W <- SNF(W.all, K, t)

## Output new data frame as sanity check
W.rownamed <- as.data.frame(W) %>%
    setDT(., keep.rownames = "rn")
fwrite(W.rownamed, file = "../data/new_net_info_V7_pval.csv")
