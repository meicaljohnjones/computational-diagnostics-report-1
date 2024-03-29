rm(list=ls())
source("http://bioconductor.org/biocLite.R")
biocLite() # install all the main biocLite packages
biocLite("limma")
biocLite("GEOquery")
biocLite("affy")
biocLite("affyPLM")
biocLite("hgu133a2.db")
biocLite("annotate")

library("limma")
library("GEOquery")
library("affy")
library("affyPLM")
library("hgu133a2.db")
library("annotate")

# retrieve geneset
G.ExpressionSet <- GEOquery::getGEO("GSE24249", GSEMatrix=TRUE)[[1]] # this is 51.8MB - will take some time to download

# already normalised otherwise would use
# affyPLM::normalize.ExpressionSet.quantiles(G.ExpressionSet)

# design matrix
design <- cbind(Grp1=1,Grp2vs1=c(0,0,0,1,1,1))

fit <- limma::lmFit(G.ExpressionSet, design)
fit <- limma::eBayes(fit)

# Extract a table of the top-ranked genes from a linear model fit.
result <- topTable(fit, coef=2, n=length(featureNames(G.ExpressionSet)), adjust="fdr", sort.by="p", p.value = 0.05)

# How many probesets do you find differentially expressed using a 
# false discovery rate (FDR) of 0.05?
# Answer
num.diff.exp.probesets <- nrow(result)

# How many unique entrez gene identifiers are in the dataset and how many unique entrez identifiers are differentially 
# expressed?
all.probe.ids <- featureNames(G.ExpressionSet)
all.entrez.gene.ids <- annotate::getSYMBOL(all.probe.ids, "hgu133a2")
# remove NA values
all.entrez.gene.ids <- unique(all.entrez.gene.ids[!is.na(all.entrez.gene.ids)])
count.total.gene.ids <- length(all.entrez.gene.ids)

diff.expressed.probe.ids <- rownames(result)
diff.expressed.gene.ids <- annotate::getSYMBOL(diff.expressed.probe.ids, "hgu133a2")
# remove NA values
diff.expressed.gene.ids <- unique(diff.expressed.gene.ids[!is.na(diff.expressed.gene.ids)])
count.diff.expressed.gene.ids <- length(diff.expressed.gene.ids)


# Show a table of the top 15 differentially expressed probesets along with 
# their gene symbol, log fold change, average expression, t-score, p-value, adjusted p-value,
# and B statistic
top.15.results <- head(result, 15)

# add the gene symbols
top.15.probe.ids <- row.names(top.15.results)
top.15.gene.symbols <- annotate::getSYMBOL(top.15.probe.ids, "hgu133a2")
top.15.results <- cbind(gene.symbols=top.15.gene.symbols, top.15.results)
top.15.results <- data.frame(top.15.results$gene.symbols, top.15.results$logFC,
                        top.15.results$AveExpr, top.15.results$t, 
                        top.15.results$P.Value, top.15.results$adj.P.Val, top.15.results$B)
names(top.15.results) <- substr(names(top.15.results), start = 16, stop=1000)
row.names(top.15.results) <- top.15.probe.ids

# === q3 ====================================================================
biocLite("topGO")
library("topGO")
all.genes <- result$adj.P.Val
names(all.genes) <- row.names(result)

## define a function to select the "significant" genes
topDiffGenes <- function(allScore) {
  return(allScore <= 0.05)
}

# Q. How many terms are significantly enriched? Perform the analysis for Molecular Function,
# Biological Process, and Cellular Components

# molecular function
mf.GOdata <- new("topGOdata",
                    ontology = "MF",
                    allGenes = all.genes,
                    geneSel = topDiffGenes,
                    annot = annFUN.db,
                    affyLib ="hgu133a2")
mf.ks <- topGO::runTest(mf.GOdata, algorithm = "classic", statistic = "ks")
mf.significant.go.terms <- length(which(score(mf.ks) <= 0.05))

# biological process
bp.GOdata <- new("topGOdata",
                    ontology = "BP",
                    allGenes = all.genes,
                    geneSel = topDiffGenes,
                    annot = annFUN.db,
                    affyLib ="hgu133a2")
bp.ks <- topGO::runTest(bp.GOdata, algorithm = "classic", statistic = "ks")
bp.significant.go.terms <- length(which(score(bp.ks) <= 0.05))

# cellular components
cc.GOdata <- new("topGOdata",
                    ontology = "CC",
                    allGenes = all.genes,
                    geneSel = topDiffGenes,
                    annot = annFUN.db,
                    affyLib ="hgu133a2")
cc.ks <- topGO::runTest(cc.GOdata, algorithm = "classic", statistic = "ks")
cc.significant.go.terms <- length(which(score(cc.ks) <= 0.05))

# Q. Show a table of the top 15 Gene Ontology Biological Process terms which are significantly 
# enriched for your set of differentially expressed genes.
bp.top.15 <- GenTable(bp.GOdata, classicKS= bp.ks, topNodes=15)
