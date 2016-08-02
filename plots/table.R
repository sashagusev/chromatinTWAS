library(htmlwidgets)
library(DT)

load("TWAS.PGC.SCZ2.RESULTS.RDa")

colnames(tbl) = c("Study","Gene","Z","INFO","P","chr","start","end","best GWAS SNP","GWAS P","joint","chromatin")

tbl[,3] = round(tbl[,3],1)
tbl[,4] = round(tbl[,4],2)

tbl[,5] = sprintf("%2.1e",tbl[,5])
tbl[,10] = sprintf("%2.1e",tbl[,10])

keep = !is.na((tbl)[,12])
tbl[keep,12] = paste('<span class="label label-success">', gsub(",",'</span>&nbsp;<span class="label label-success">',tbl[keep,12],fixed=T) ,'</span>')

keep = tbl[,11] == 1
tbl[keep,11] = '<span class="label label-danger">*</span>'
tbl[!keep,11] = NA

keep = c(1:8,10:12)
d = datatable(tbl[,keep],rownames=F,class='compact',options = list(searchHighlight = TRUE,pageLength = 20),escape=F)

saveWidget(d, file="TWAS_RESULTS.html")

cat( 'add `<link rel="stylesheet" href="../css/main.css">` to html file\n' )
