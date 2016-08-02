library('ggrepel')
library('RColorBrewer')

multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

pop = c("CMC","NTR","YFS","METSIM")
pop.ttl = c("Brain (CMC)","Blood (NTR)","Blood (YFS)","Adipose (METSIM)")

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

clr = brewer.pal(3,"Set1")
clr = c("gray70","gray60",clr[1:2])

clumped = read.table("clump.rsq30.transcriptomewide.out",as.is=T)

plots = list()
for ( pi in 1:length(pop) ) {
	p = pop[pi]
	imp = read.table(paste(p,".PGC.SCZ2.imp.NOHLA",sep=''),as.is=T)
	imp = imp[imp[,4] != 0,]
	m = match(imp[,2],genes[,5])
	cat( p , sum(is.na(m)) , "unmatched\n")
	imp = imp[!is.na(m),]
	m = m[!is.na(m)]
	cur.chr = genes[m,2]
	cur.pos = (genes[m,3] + genes[m,4])/2
	cur.z = imp[,3] / sqrt(imp[,4])
	
	z.thresh = qnorm(0.05/(2*length(cur.z)),lower.tail=F)
	
	ylm = max(abs(cur.z),na.rm=T)
	ylm = c(-8,8)
	
	top = clumped[clumped[,3] == p,]
	top.z = top[,5]
	m = match(top[,4],genes[,5])

	points.x = rep(NA,length(cur.pos))
	points.y = rep(NA,length(cur.pos))
	points.clr = rep(NA,length(cur.pos))
	points.txt = rep(NA,length(cur.pos))
	# plot the chromomsomes
	for ( c in 1:22 ) {
		keep = (cur.chr == c)
		points.x[keep] = cur.pos[keep] - chr.starts[c] + offsets[c]
		points.y[keep] = cur.z[keep]
		points.clr[keep] = clr[(c %% 2) + 1]
		
		top.all = keep & cur.z^2 > z.thresh^2
		points.clr[ top.all & cur.z > 0 ] = clr[3]
		points.clr[ top.all & cur.z < 0 ] = clr[3]
		points.txt[ top.all ] = imp[top.all,2]
	}
	
	lbl.keep = !is.na(points.txt)
	df.main = data.frame(pos = points.x , yval = points.y , labels = points.txt , colors = points.clr )
	df.top = data.frame(pos = points.x[lbl.keep] , yval = points.y[lbl.keep] , labels = points.txt[lbl.keep] , colors = points.clr[lbl.keep])
	
	points.size = rep(1,length(points.y))
	points.size[lbl.keep] = 1.5
	# text
	plots[[p]] = ggplot() +
	geom_point(data = df.main, aes(pos, yval), color = points.clr , size=points.size) +
	geom_text_repel(data = df.top , aes(pos, yval, label = labels),size=3,segment.size = 0.5,fontface='bold') +
	geom_point(data = df.top , aes(pos, yval), color = points.clr[lbl.keep] , size=1.5 ) +
	theme_classic(base_size = 10) + 
	scale_x_continuous("Chromosome", labels = 1:22 , breaks = cumsum( chr.ends - chr.starts ) - chr.ends ) + 
	ylim(-8,8) + ylab("Z-score") + 
	ggtitle(pop.ttl[[pi]]) + theme(plot.title = element_text(hjust = 0)) + geom_hline(yintercept=0)
}


png("manhattan_scz.png",height=600,width=850)
multiplot( plots[["CMC"]] , plots[["NTR"]] , plots[["YFS"]] , plots[["METSIM"]] )
dev.off()
