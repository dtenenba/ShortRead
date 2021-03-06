\name{qa}
\alias{qa}
\alias{qa,character-method}
\alias{qa,list-method}

\title{Perform quality assessment on short reads}

\description{

  This function is a common interface to quality assessment functions
  available in \code{ShortRead}. Results from this function may be
  displayed in brief, or integrated into reports using, e.g.,
  \code{\link{report}}.

}
\usage{
qa(dirPath, ...)
\S4method{qa}{character}(dirPath, pattern=character(0), 
    type=c("fastq", "SolexaExport", "SolexaRealign", "Bowtie",
           "MAQMap", "MAQMapShort"),
    ...)
\S4method{qa}{list}(dirPath, ...)
}

\arguments{

  \item{dirPath}{A character vector or other object (e.g.,
    \code{\link{SolexaPath}}; see \code{showMethods}, below) locating
    the data for which quality assessment is to be performed. See help
    pages for defined methods (by evaluating the example code, below)
    for details of available methods.}

  \item{pattern}{A character vector limiting the files in \code{dirPath}
    to be processed, as with \code{\link{list.files}}. Care should be
    taken to specify pattern to avoid reading unintended files.}

  \item{type}{The type of file being parsed; must be a character vector
    of length 1, selected from one of the types enumerated in the
    parameter.}

  \item{\dots}{Additional arguments used by methods. 

    \describe{

      \item{\code{sample=TRUE}:}{Logical(1) indicating whether QA should
        be performed on a sample (default size 1000000) drawn from each
        FASTQ file, or from the entire file.}

      \item{\code{n}:}{The number of reads to sample when processing
        FASTQ files.}

      \item{\code{Lpattern}, \code{Rpattern}:}{A character vector or
        XString object to be matched to the left end of a sequence. If
        either \code{Lpattern} or \code{Rpattern} are provided,
        \code{trimLRPatterns} is invoked to produce a measure of adapter
        contamination.  Mismatch rates are 0.1 on the left and 0.2 on
        the right, with a minimum overlap of 10 nt.}

      \item{\code{BPPARAM}:}{How parallel evalutation will be
        performed. see \code{\link{BiocParallelParam}}; the default is
        \code{BiocParallel::registered()[1]}.}

    }
  }
}

\details{

  The most common use of this function provides a directory path and
  pattern identifying FASTQ files for quality assessment. The default is
  then to create a quality assessment report based on a random sample of
  n=1000000 reads from each file.

  The following methods are defined, in addition to those on S4 formal
  classes documented elsewhere:

  \describe{

    \item{\code{qa,character-method}}{

      Quality assessment is performed on all files in directory
      \code{dirPath} whose file name matches \code{pattern}. The type of
      analysis performed is based on the \code{type} argument. Use
      \code{SolexaExport} when all files matching \code{pattern} are
      Solexa \code{_export.txt} files. Use \code{SolexaRealign} for
      Solexa \code{_realign.txt} files. Use \code{Bowtie} for Bowtie
      files. Use \code{MAQMapShort} for MAQ \code{map} files produced by
      MAQ versions below 0.70 and \code{MAQMap} for more recent output.
      Use \code{fastq} for collections of fastq-format files. Quality
      assessment details vary depending on data source.

    }
    
    \item{\code{qa,list-method}}{

      \code{dirPath} is a list of objects, all of the same class and
      typically derived from \code{ShortReadQ}, on which quality
      assessment is performed. All elements of the list must have names,
      and these should be unique.

    }
  }
}

\value{

  An object derived from class \code{\linkS4class{.QA}}. Values
  contained in this object are meant for use by \code{\link{report}}

}

\author{Martin Morgan <mtmorgan@fhcrc.org>}

\seealso{
  \code{\linkS4class{.QA}},
  \code{\linkS4class{SolexaExportQA}}
  \code{\linkS4class{MAQMapQA}}
  \code{\linkS4class{FastqQA}}
}

\examples{
dirPath <- system.file(package="ShortRead", "extdata", "E-MTAB-1147")
## sample 1M reads / file
qa <- qa(dirPath, "fastq.gz", BPPARAM=SerialParam())
if (interactive())
    browseURL(report(qa))

showMethods("qa", where=getNamespace("ShortRead"))
}

\keyword{manip}
