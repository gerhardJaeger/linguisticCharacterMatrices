library(ape)
library(stringr)
library(TAF)


contrees <- list.files("mrbayes_scripts/output", pattern="*.con.tre")

dbs <- str_split(contrees, ".con.tre", simplify=T)[,1]

mkdir("../data/mrbayes_posteriors/")


for (db in dbs) {
    trees1 <- read.nexus(str_interp("mrbayes_scripts/output/${db}.run1.t"))
    trees2 <- read.nexus(str_interp("mrbayes_scripts/output/${db}.run2.t"))
    bi <- round(length(trees1)/4)
    trees <- c(trees1[-(1:bi)], trees2[-(1:bi)])
    trees <- sample(trees, min(length(trees), 1000))
    write.tree(trees, str_interp("../data/mrbayes_posteriors/${db}.posterior.tree"))
}
