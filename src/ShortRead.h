#include <Rdefines.h>
#include "Biostrings_interface.h"

/* util.c */

int _rtrim(char *linebuf);
void _solexa_to_IUPAC(char *linebuf);
SEXP count_lines(SEXP files);

/* io.c */

SEXP read_solexa_fastq(SEXP files);

/* alphabet.c */

SEXP alphabet_by_cycle(SEXP stringSet, SEXP width, SEXP alphabet);
