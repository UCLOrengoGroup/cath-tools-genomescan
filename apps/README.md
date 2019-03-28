# cath-genomescan scripts

## About this document

 * This document provides details about the scripts/apps used in this repository
 * This document is currently considered 'beta' and is subject to change.
 * All feedback / corrections / suggestions are welcome

### cath-genomescan.pl

This script scans your query sequence(s) against the CATH-FunFam HMM models and returns a list of FunFams(Functional Families) for the identified domains in your sequence(s).

Usage: cath-genomescan.pl -i <fasta_file> -l <hmm_lib> -o <output_dir>

Example:

```
cath-genomescan.pl -i test.fasta -l cath.funfam.hmm.lib -o results/
```

### retrieve_FunFam_aln_GO_anno_CATH-API.pl

This script returns all the GO terms for each annotated sequence within a CATH-FunFam.

Usage: retrieve_FunFam_aln_GO_EC_anno_CATH-API.pl <CATH FunFam assignment> <CATH version> <output_dir>

Example:

```
retrieve_FunFam_aln_GO_EC_anno_CATH-API.pl 2.40.50.140/FF/58874 v4_2_0 /export/git/cath-tools-genomescan/results
```
