## get coverage for fine and coarse view
.get_fine_coverage <- function(x)
{
    rng <- vrange(x)
    wd <- width(rng)
    cvg <- function(aln) {
        if (identical(0L, length(aln))) 
            numeric(wd)
        else
            as.numeric(coverage(aln, shift=-start(rng)+1, width=wd))
    }
    lst <- lapply(as.list(files(x)), function(fl) {
        aln <- readBamGappedAlignments(fl, which=rng)
        seqlevels(aln) <- seqlevels(rng)
        list(`+`=cvg(aln[strand(aln)=="+"]),
             `-`=cvg(aln[strand(aln)=="-"]))
    })
}

.get_coarse_coverage <- function(x)
{
    nbins <- 5000L
    rng <- vrange(x)
    wd <- width(rng)
    breaks <- seq(start(rng), end(rng), length.out=nbins)
    lst <- lapply(as.list(files(x)), function(fl) {
        param <- ScanBamParam(which=rng, what=c("pos", "strand"))
        starts <- scanBam(fl, param=param)[[1]]
        bins <- with(starts, {
            lapply(split(pos, strand)[1:2], function(elt) {
                if (length(elt)) cut(elt, breaks=breaks, labels=FALSE)
                else integer()
            })
        })
        lapply(bins, tabulate, length(breaks)-1) #nbins = breaks-1
    })
}

.coverage_as_dataframe <- function(lst, range, ignore.strand=FALSE,
                                   resolution.fine=TRUE)
{
    positive <- sapply(lst, "[[", "+")
    negative <- sapply(lst, "[[", "-")
    if (is.matrix(positive))
        positive <- rowMeans(positive)
    if (is.matrix(negative))
        negative <- rowMeans(negative)

    if (resolution.fine)
        pos <- seq.int(start(range), end(range), length.out=length(positive))
    else { ## center the pos at the bin
        delta <- (end(range)-start(range))/(length(positive))
        pos <- seq.int(start(range)+delta/2, by=delta,
                       length.out=length(positive))
    }

    if (!ignore.strand) {
        snames <- c("positive", "negative")
        group <- factor(rep(snames, each=length(positive)),
                        levels=snames)
        data.frame(data=c(positive, -negative),
                   group=group,
                   pos=pos)
    } else {
        data.frame(data=positive+negative, pos=pos)
    }
    
}


.multiFile_coverage_as_dataframe <- function(lst, range, ignore.strand=FALSE,
                                             resolution.fine=TRUE)
{ 
    wd <- width(range)
    positive <- sapply(lst, "[[", "+")
    negative <- sapply(lst, "[[", "-")
    nPoints <- length(lst[[1]][[1]])
    if (resolution.fine)
        #pos <- rep(seq.int(start(range), end(range)), 2*length(lst))
        pos <- seq.int(start(range), end(range))
    else {
        nIntervals <- length(lst[[1]][[1]])
        delta <- (end(range)-start(range))/(nPoints)
        pos <- seq.int(start(range)+delta/2, by=delta, length.out=nPoints)
        #p <- seq.int(start(range)+delta/2, by=delta, length.out=nPoints)
        #pos <- rep(p, times=2*length(lst))
    }

    fnames <- names(lst)
    if (length(unique(fnames))!=length(fnames))
        fnames <- paste(1:length(fnames), fnames, sep="-")
    file <- c(do.call(cbind, lapply(fnames, rep, nPoints)))

    if (ignore.strand) {
        data.frame(data=c(positive+negative), pos=pos, levels=file)
    } else {
        snames <- c("positive", "negative")
        strand <- rep(snames, each=length(positive))
        file <- rep(file, 2)
        data.frame(data=c(positive, -negative),
                   pos=pos, group=strand, levels=file)                 
#        group <-
#            factor(paste(strand, file, sep=": "))
#        data.frame(data=c(positive, -negative),
#                   pos=pos, group=group)
  }


    
}


################### readers #######################
.fine_coverage_reader <- function(x)
{   ## x: a Snapshot instance
    ## create a plot of coverage as sum of coverage of all the files
    lst <- .get_fine_coverage(x)
    rng <- vrange(x)
    ignore.strand <- ignore.strand(x)
    .coverage_as_dataframe(lst, rng, ignore.strand=ignore.strand,
                           resolution.fine=TRUE)
}

.coarse_coverage_reader <- function(x)
{   ## x: a Snapshot instance
    ## create a plot of coverage as sum of coverage of all the files
    lst <- .get_coarse_coverage(x)
    rng <- vrange(x)
    ignore.strand <- ignore.strand(x)
    .coverage_as_dataframe(lst, rng, ignore.strand=ignore.strand,
                           resolution.fine=FALSE)
} 

.multifine_coverage_reader <- function(x)  
{   ## x: a Sanpshot instance
    ## create a plot of coverage, separate lines for each file
    lst <- .get_fine_coverage(x)
    rng <- vrange(x)
    ignore.strand <- ignore.strand(x)
    .multiFile_coverage_as_dataframe(lst, rng, ignore.strand=ignore.strand,
                                     resolution.fine=TRUE)
}

.multicoarse_coverage_reader <- function(x)
{   ## x: a Sanpshot instance
    ## create a plot of coverage, separate lines for each file
    lst <- .get_coarse_coverage(x)
    rng <- vrange(x)
    ignore.strand <- ignore.strand(x)
    .multiFile_coverage_as_dataframe(lst, rng, ignore.strand=ignore.strand,
                                     resolution.fine=FALSE)
}

.update_viewer <- function(x, cv)
{
    ## subset annTrack and validate anntrack
    anntrack <- annTrack(x)
    rng <- vrange(x) 
    if (any(seqnames(anntrack)@values %in% seqlevels(rng)))
        gr <- keepSeqlevels(anntrack, seqlevels(vrange(x)))
    else  {
        message("SnapshotFunction-helper: seqname of 'annTrack' does not match to the imported range. Annotation track will not be plotted.")
        return(NULL)
    }

    ## if anntrack has no elementMetada value, then return NULL
    if (ncol(values(anntrack)) < 1) {
        message("SnapshotFunction-helper: at least one column of 'annTrack' elementMetadata is required. Annotation track will not be plotted.")
        return(NULL)
    }
    
    # x: a Snapshot instance
    if (.currentFunction(x) %in% c("coarse_coverage", "multicoarse_coverage"))
        ann <- .coarse_annviewer(gr, rng)

    if (.currentFunction(x) %in% c("fine_coverage", "multifine_coverage"))
        ann <- .fine_annviewer(gr)

    ann$x.limits <- cv$x.limits
    update(c(cv, ann), x.same=TRUE, layout=c(1,length(cv$packet.sizes)+1),
           xlab=NULL, ylab=NULL,
           scales=list(y=list(alternating=2, tck=c(0,1)),
                       x=list(rot=45, tck=c(1,0), tick.number=20)), 
           par.setting=list(layout.heights=list(panel=c(2,1))))
}
     
## viewers
.coverage_viewer <- function(x)
{
    ## x: a Snapshot instance
    sp <- .getData(x) # x$.data
    lty <- rep(seq_len(length(levels(sp$group)) / 2), times=2)
    ## sp: data.frame with "data", "group", and "pos" column
    col <- c("#66C2A5", "#FC8D62")

    if (!ignore.strand(x)) 
        cv <- xyplot(data ~ pos, data=sp, group=group, col=col)
    else
        cv <- xyplot(data ~ pos, data=sp, col=col[1])
    
    cv <- update(cv, type="s",
                 ylab="Coverage", xlab="Coordinate",
                 scales=list(y=list(tck=c(1,0)),
                             x=list(rot=45, tck=c(1,0), tick.number=20)),
                 panel=function(...) {
                     panel.xyplot(...)
                     panel.grid(h=-1, v=20)
                     panel.abline(a=0, b=0, col="grey")
                 })
    #cv <- xyplot(data ~ pos, data=sp, group=group, type="s",
    #             col=col, 
    #             ylab="Coverage", xlab="Coordinate",
    #             #key=list(space="top", column=2, cex=0.8,
    #             #         lines=list(lty=lty, col=col),
    #             #         text=list(levels(sp$group))),
    #             scales=list(y=list(tck=c(1,0)),
    #                         x=list(rot=45, tck=c(1,0), tick.number=20)),
    #             panel=function(...) {
    #                 panel.xyplot(...)
    #                 panel.grid(h=-1, v=20)
    #                 panel.abline(a=0, b=0, col="grey")
    #             })
    
    if (!is.null(annTrack(x))) {
        ud <- .update_viewer(x, cv)
        if (!is.null(ud)) cv <- ud
    }  
        
    SpTrellis(trellis=cv)   
}

.multicoverage_viewer <- function(x, ...)
{   ## x: a Snapshot instance
    sp <- .getData(x) #x$.data
    lv <- length(levels(sp$group))/2
    lty <- rep(seq_len(lv), times=2)
    col <- c("#FC8D62", "#66C2A5")
    #col <- c(rep("#FC8D62", lv) , rep("#66C2A5", lv))
    if (ignore.strand(x)) 
        cv <- xyplot(data ~ pos | levels, data=sp, col=col[1])
    else
        cv <- xyplot(data ~ pos | levels, data=sp, group=group, col=col)
    cv <- update(cv, type="s", #lty=lty,
                 ylab="Coverage", xlab="Coordinate",
                 layout=c(1, length(levels(factor(sp$levels)))),
                 scales=list(y=list(tck=c(1,0)),
                             x=list(rot=45, tck=c(1,0), tick.number=20)),
                 key=list(space="top", column=2, cex=0.8,
                          lines=list(lty=lty, col=col),
                          text=list(levels(sp$group))),
                 panel=function(...) {
                     panel.xyplot(...)
                     panel.grid(h=-1, v=20)
                     panel.abline(a=0, b=0, col="grey")
                 })
    #cv <- xyplot(data ~ pos, data=sp, group=group, type="s",
    #             col=col, lty=lty,
    #             ylab="Coverage", xlab="Coordinate",
    #             scales=list(y=list(tck=c(1,0)),
    #                         x=list(rot=45, tck=c(1,0), tick.number=20)),
    #             key=list(space="top", column=2, cex=0.8,
    #                      lines=list(lty=lty, col=col),
    #                      text=list(levels(sp$group))),
    #             panel=function(...) {
    #                 panel.xyplot(...)
    #                 panel.grid(h=-1, v=20)
    #                panel.abline(a=0, b=0, col="grey")
    #             })
    if (!is.null(annTrack(x))) {
        ud <- .update_viewer(x, cv)
        if (!is.null(ud)) cv <- ud
    }  

    SpTrellis(trellis=cv)
}

### default annotation track viewer
.fine_annviewer <- function(gr)
{   ## how to get the window
    x <- start(gr)
    x1 <- end(gr)
    xm <- (x+x1)/2
    y <- rep(c(-1.4, -0.7, 0, 0.7, 1.4), length.out=length(x))
    col <- c("#66C2A5", "#FC8D62")
    myCol <- col[as.numeric(strand(gr)@values)]
    mypanel <- function(x,y, genenames, x1, ...) {
        panel.xyplot(x,y, ..., col="transparent")
        ltext(x=xm, y=y, genenames, cex=0.45, pos=3)
        lsegments(x0=x, y0=y, x1=x1, y1=y, col=myCol, alpha=0.5)
    }
    ann <- xyplot(y ~ x, genenames=as.character(values(gr)[[1]]),
                  x1=x1, xm=xm, panel=mypanel,
                  xlab=NULL, ylab=NULL,
                  scales=list(y=list(tick.number=0, labels=NULL)),
                  par.settings=
                      list(axis.text=list(alpha=0.5), axis.line=list(alpha=0.5))
                  )
    ann$y.limits[2] = 2.1
    ann
}

.coarse_annviewer <- function(gr, rng)
{
    ## gr: GRanges for tracks
    ## x:  range of an Snapshot instance
    col <- c("#66C2A5", "#FC8D62")
    nbins=5000L
    interval <- seq.int(start(rng), end(rng), length.out=nbins)
    l <- length(interval)
    ir <- IRanges(start=interval[1:(l-1)], end=interval[2:l])
    lst <- list("+" = countOverlaps(ir, ranges(gr[strand(gr)=="+"])),
                "-" = countOverlaps(ir, ranges(gr[strand(gr)=="-"])))
    snames <- c("positive", "negative")
    group <- factor(rep(snames, each=length(lst[[1]])),
                    levels=snames)
    cvg <- data.frame(data=c(lst[["+"]], -lst[["-"]]),
                      group=group,
                      pos = (start(ir)+end(ir))/2)
    xyplot(data ~ pos, data=cvg, groups=group, type="h", col=col,
           xlab=NULL, ylab=NULL,
           scales=list(y=list(alternating=2, tick.number=3,tck=c(0,1)),
                       x=list(tck=c(0,0), labels=NULL)),
           par.settings=
                   list(axis.text=list(alpha=0.5), axis.line=list(alpha=0.5))
           )
}