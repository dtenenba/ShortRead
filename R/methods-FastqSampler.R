.FastqSampler_g$methods(
    reset = function() {
        "reopen the connection"
        if (verbose) msg("FastqSampler$reset()")
        if (isOpen(con)) {
            if (verbose) msg("FastqSamper$reset() re-open")
            s <- summary(con)
            class <- s$class
            desc <- s$description
            close(con)
            con <<- do.call(s$class, list(desc, "rb"))
        } else {
            open(con, "rb")
        }
        .self
    },
    status = function(update=FALSE) {
        "report status of FastqSampler"
        if (update || !length(.status))
            .status <<- .Call(.sampler_status, sampler)
        .status
    },
    yield = function(...) {
        "read and sample all records in a connection"
        if (verbose) msg("FastqSampler$yield()")
        reset()
        while (length(bin <- reader(con, readerBlockSize))) {
            if (verbose) {
                status(update=TRUE)
                msg("FastqSampler$yield() reader")
            }
            .Call(.sampler_add, sampler, bin)
        }
        if (status(update=TRUE)["buffer"])
            .throw(SRWarn("IncompleteFinalRecord",
                "FastqSampler yield() incomplete final record:\n  %s",
                summary(con)$description))
        if (verbose)
            msg("FastqSampler$yield() XStringSet")
        elts <- .Call(.sampler_as_XStringSet, sampler, ordered)
        if (verbose)
            msg("FastqSampler$yield() ShortReadQ")
        ShortReadQ(elts[["sread"]], elts[["quality"]], elts[["id"]], ...)
    },
    show = function() {
        callSuper()
        cat("ordered:", ordered, "\n")
    })

FastqSampler <-
    function(con, n = 1e6, readerBlockSize=1e8, verbose=FALSE,
             ordered=FALSE)
{
    if (length(n) != 1 || !is.finite(n) || n < 0)
        stop("'n' must be length 1, finite and >= 0")
    if (is(con, "FastqFile")) 
        con <- path(con)
     if (is.character(con)) {
        con <- file(con)
        open(con, "rb")
    } else if (is(con, "connection") && summary(con)$opened != "opened")
        open(con, "rb")
    sampler <- .Call(.sampler_new, as.integer(n))
    .ShortReadFile(.FastqSampler_g, con, reader=.binReader,
                   readerBlockSize=as.integer(readerBlockSize),
                   sampler=sampler, verbose=verbose, ordered=ordered)
}

setMethod("FastqSamplerList", "ANY",
          function(..., n=1e6, readerBlockSize=1e8, verbose=FALSE,
                   ordered = FALSE)
{
    FastqFileList(..., class="FastqSampler")
})

setMethod("FastqSamplerList", "character",
          function(..., n=1e6, readerBlockSize=1e8, verbose=FALSE,
                   ordered = FALSE)
{
    listData <-
        lapply(..1, FastqSampler, n=n, readerBlockSize=readerBlockSize,
               verbose=verbose, ordered=ordered)
    new("FastqSamplerList", listData=listData)
})
