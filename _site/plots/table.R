library(htmlwidgets)
library(DT)

load("/Users/sasha/github/chromaTWAS/plots/TWAS.PGC.SCZ2.RESULTS.RDa")

colnames(tbl) = c("Study","Gene","Z","INFO","P","chr","start","end","best GWAS SNP","GWAS P","*","chromatin")

tbl[,3] = round(tbl[,3],1)
tbl[,4] = round(tbl[,4],2)

tbl[,5] = sprintf("%2.1e",tbl[,5])
tbl[,10] = sprintf("%2.1e",tbl[,10])

keep = c(1:8,10:12)
d = datatable(tbl[,keep],rownames=F,class='compact',options = list(searchHighlight = TRUE,pageLength = 20))

saveWidget(d, file="TWAS_RESULTS.html")
