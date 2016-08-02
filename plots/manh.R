library(plotly)
library(ggrepel)

pop = c("CMC","NTR","YFS","METSIM")
genes = read.table("UCSC.hg19.knowngenes.longest",as.is=T,sep='\t')
genes[,2] = as.numeric( gsub("chr","",genes[,2]) )

# get chr bounds
chr.starts = rep(0,22)
chr.ends = rep(0,22)
for ( i in 1:22 ) {
	chr.starts[i] = min( genes[genes[,2] == i,3] , na.rm=T )
	chr.ends[i] = max( genes[genes[,2] == i,4] , na.rm=T )
}
offsets = c(0,cumsum(chr.ends - chr.starts))

for ( p in pop ) {
	imp = read.table(paste(p,".PGC.SCZ2.imp.NOHLA",sep=''),as.is=T)
	imp = imp[imp[,4] != 0,]
	m = match(imp[,2],genes[,5])
	cat( p , sum(is.na(m)) , "unmatched\n")
	imp = imp[!is.na(m),]
	m = m[!is.na(m)]
	
	cur.z = imp[,3] / sqrt(imp[,4])
	z.thresh = qnorm(0.05/(2*length(cur.z)),lower.tail=F)
	cur.chr = genes[m,2]
	cur.pos = (genes[m,3] + genes[m,4])/2
		
	keep = cur.z^2 > z.thresh^2
	cur.z = cur.z[keep]
	cur.chr = cur.chr[keep]
	cur.pos = cur.pos[keep]
	imp = imp[keep,]
	
	points.x = rep(NA,length(cur.pos))
	points.y = rep(NA,length(cur.pos))
	points.txt = rep(NA,length(cur.pos))

	for ( c in 1:22 ) {
		keep = (cur.chr == c)
		points.x[keep] = cur.pos[keep] - chr.starts[c] + offsets[c]
		points.y[keep] = cur.z[keep]
		points.txt[keep] = imp[keep,2]
	}
	df = data.frame(pos = points.x , zscore = points.y, gene = points.txt)
}

p <- ggplot(data = df, aes(x = pos, y = zscore)) +
  geom_point(aes(text = zscore), size = 1) + 
  scale_x_continuous("Physical position", labels = 1:22 , breaks = cumsum( chr.ends - chr.starts ) - chr.ends ) +
  ylab("Z-score") + ylim(-8,8)
(gg <- ggplotly(p))
