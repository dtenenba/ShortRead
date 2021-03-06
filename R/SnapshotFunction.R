SnapshotFunction <-
    function(reader, viewer, limits, ...)
{
    if (missing(limits) || length(limits) != 2)
        stop("limits must have length 2")
    if ((limits[2] - limits[1]) < 50)
        stop("limits[2] -  limits[1] must be greater than 50 bps")

    new("SnapshotFunction", reader=reader, viewer=viewer,
        limits=as.integer(limits), ...)
}

reader <- function(x, ...) x@reader
viewer <- function(x, ...) x@viewer
limits <- function(x, ...) x@limits

setMethod(show, "SnapshotFunction", function(object) 
{
    cat("class:", class(object), "\n")
    cat("reader:\n")
    print(head(reader(object)))
    cat("...\n\n")
    cat("viewer:\n")
    print(head(viewer(object)))
    cat("...\n\n")
    cat(sprintf("limits: min. %.0f to max. %.0f bps",
                limits(object)[1], limits(object)[2]), "\n")
})

## SnapshotFunctionList

setMethod(SnapshotFunctionList, "ANY",
    function(...)
{
    if (nargs())
        stop("'SnapshotFunctionList' unknown argument type: ",
             class(..1))
    new("SnapshotFunctionList")
})

setMethod(SnapshotFunctionList, "SnapshotFunction",
    function(...) 
{
    funs <- list(...)
    if (is.null(names(funs)) || any(!nzchar(names(funs))))
        stop("'SnapshotFunctionList' functions must be named")
    new("SnapshotFunctionList", listData=funs)
})

.fine_coverage <-
    SnapshotFunction(reader=.fine_coverage_reader,
                     viewer=.coverage_viewer, limits=c(50L, 10000L))

.coarse_coverage <-
    SnapshotFunction(reader=.coarse_coverage_reader,
                     viewer=.coverage_viewer,
                     limits=c(10000L,.Machine$integer.max))

.multifine_coverage <-
    SnapshotFunction(reader=.multifine_coverage_reader,
                     viewer=.multicoverage_viewer,
                     limits=c(50L, 10000L))

.multicoarse_coverage <-
    SnapshotFunction(reader=.multicoarse_coverage_reader,
                     viewer=.multicoverage_viewer,
                     limits=c(10000L,.Machine$integer.max))
