library(tidyverse)
library(Quartet)
library(ggpubr)


gqd <- function(t1, t2) {
    statuses <- QuartetStatus(t1, t2)
    if (statuses[1, "d"] == 0) {
        g <- 0
    } else {
        g <- statuses[1, "d"] / (statuses[1, "s"] + statuses[1, "d"])
    }
    return(as.numeric(g))
}


glot_trees <- list.files("../data/glottologTrees/")

dbs <- lapply(str_split(glot_trees, "_"), function(x) x[1]) %>% unlist()

d_phy <- c()
d_catg <- c()

for (db in dbs) {
    t_glot <- read.tree(str_c("../data/glottologTrees/", db, "_glottolog.tre"))
    t_phy <- read.tree(str_c("../data/phylip_mltrees/", db, "_mltree.tre"))
    t_catg <- read.tree(str_c("../data/catg_mltrees/", db, "_catg_mltree.tre"))
    d_phy <- c(d_phy, gqd(t_phy, t_glot))
    d_catg <- c(d_catg, gqd(t_catg, t_glot))
} 


df <- tibble(db=dbs, phylip=d_phy, catg=d_catg)

ggpaired(df, "phylip", "catg", fill="condition")

df %>% 
    mutate(diff = phylip-catg) %>%
    ggplot(aes(x=diff)) +
    geom_density()

write_csv(df, "gqd_comparison.csv")
