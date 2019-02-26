# Generating CATH assignments for large sequence datasets

## About this document

 * This document provides a set of instructions to annotate large sequence datasets with CATH functional family assignments.
 * This document is currently considered 'beta' and is subject to change.
 * All feedback / corrections / suggestions are welcome

# Steps

## 1. Create a new project

Clone a new project template from GitHub and move into the directory.

```
> git clone https://github.com/UCLOrengoGroup/cath-tools-genomescan.git myproject
> cd myproject/
> pwd
```

Note: this directory will be called ```${PROJECTHOME}``` for the rest of the tutorial.

## 2. Organise your query sequences

Choose a genome and get all translated protein sequences in FASTA format. 

The file ```${PROJECTHOME}/data/test.fasta``` containing two query sequences has been included in the template as an example.

```
> cd ${PROJECTHOME}
> cd data/
> cat test.fasta
>cath|4_1_0|2fupA
GXPDSPTLLDLFAEDIGHANQLLQLVDEEFQALERRELPVLQQLLGAKQPLXQQLERNGRARAEILREAGVSLDREGLARYARERADGAELLARGDELGELLERCQQANLRNGRIIRANQASTGSLLNILR
>cath|4_1_0|1cukA
MIGRLRGIIIEKQPPLVLIEVGGVGYEVHMPMTCFYELPEAGQEAIVFTHFVVREDAQLLYGFNNKQERTLFKELIKTNGVGPKLALAILSGMSAQQFVNAVEREEVGALVKLPGIGKKTAERLIVEMKDRFKGLHGDLFTPAADLVLTSPASPATDDAEQEAVARLVALGYKPQEASRMVSKIARPDASSETLIREALRAAL
```

## 3. Download and install HMMER3

Download and extract the recent [HMMER3](http://eddylab.org/software/hmmer3/) software:

```
> cd ${PROJECTHOME}
> cd apps/
> wget http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz
> tar zxf hmmer-3.1b2-linux-intel-x86_64.tar.gz
```

Create a link for convenience:

```
> cd ${PROJECTHOME}
> cd bin/
> ln -s ../apps/hmmer-3.1b2-linux-intel-x86_64/binaries hmmer3
```

Check to make sure the link and binaries work as expected:

```
> cd ${PROJECTHOME}
> ./bin/hmmer3/hmmscan -h
# hmmscan :: search sequence(s) against a profile database
# HMMER 3.1b2 (February 2015); http://hmmer.org/
# Copyright (C) 2015 Howard Hughes Medical Institute.
# Freely distributed under the GNU General Public License (GPLv3).
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Usage: hmmscan [-options] <hmmdb> <seqfile>
...
```

More information can be found on installing HMMER3 on the excellent [HMMER documentation](http://hmmer.org/documentation.html)

## 4. Download library of CATH models

Download the library of CATH FunFam (Functional Family) models and unzip.

We are using here the v4.2 CATH FunFam models. 
Check the most recent version [here](http://www.cathdb.info/wiki/doku/?id=release_notes).

```
> cd ${PROJECTHOME}
> cd data/
> wget http://download.cathdb.info/cath/releases/all-releases/v4_2_0/sequence-data/funfam-hmm3-v4_2_0.lib.gz
> gunzip funfam-hmm3-v4_2_0.lib.gz
```

Use ```hmmpress``` to index the HMM library:

```
> cd ${PROJECTHOME}
> cd data/
> ../bin/hmmer3/hmmpress funfam-hmm3-v4_2_0.lib
```

## 5. Scan the query sequence(s)

CATH FunFam assignments can now be generated by scanning the query sequences against the CATH FunFam model library. Only those which meet the FunFam inclusion threshold are reported.

```
> cd ${PROJECTHOME}
> ./apps/cath-genomescan.pl -i data/test.fasta -l data/funfam-hmm3-v4_2_0.lib -o results/
```

## 6. Assigned domain architecture of query sequences

Three result files are generated in the ```results/``` folder:
```
> cd ${PROJECTHOME}/results/
> ls
 test.crh  test.domtblout  test.html
```

#### (i) test.crh 
This is the main FunFam scan result file which displays the most confident domain matches across the query sequence(s) that matches a CATH FunFam, the corresponding domain regions in the sequence(s) along with the bit-score and E-values of the matches. Each identified domain in a query sequence that matches a FunFam is represented by a different row. The matching region(s) for a domain can sometimes be discontinuous (in case of discontinuous domains), where more than one segment of the protein sequence forms the structural domain region.

This file is generated by cath-resolve hits which collapses a list of domain matches to your query sequence(s) (```test.domtbout```) down to the best, non-overlapping subset (i.e. domain architecture).

An example is shown below:
```
> cd ${PROJECTHOME}/results/
> cat test.crh
#Generated by cath-resolve-hits, one of the cath-tools (https://github.com/UCLOrengoGroup/cath-tools)
#FIELDS query-id match-id score boundaries resolved cond-evalue indp-evalue
cath|4_1_0|1cukA 2.40.50.140/FF/58874 160.3 1-65 1-65 5.4e-52 1.1e-51
cath|4_1_0|1cukA 1.10.150.20/FF/4839 169.4 67-140 67-140 5.5e-55 1.1e-54
cath|4_1_0|1cukA 1.10.8.10/FF/15460 61.4 157-201 157-201 3.8e-21 7.5e-21
cath|4_1_0|2fupA 1.20.58.300/FF/1517 113 6-130 6-130 5.7e-37 1.1e-36
```

*The FunFam ID has the following pattern: 2.40.50.140/FF/58874 where the CATH superfamily ID of the FunFam match is 2.40.50.140 and the matched FunFam number within that superfamily is 58874. The four numbers in the superfamily ID (2.40.50.140) corresponds to each level in the [CATH classification](http://www.cathdb.info/browse/tree). For example, the 2 refers to the class to which the domain belongs (mainly beta), the 2.40 refers to the architecture (beta barrel), the 2.40.50 refers to the actual fold or topology the domain adopts (OB fold) and 2.40.50.140 is the homologous superfamily code.* 

#### (ii) test.html
Point your web browser at this file to visualise the assigned domain architecture of your query sequence(s).

##### 1. Assigned domain architecture for cath|4_1_0|1cukA

![](/images/test_seq_1cukA_crh_resolved.png)

Look at the assigned domain architecture for the query sequence ```cath|4_1_0|1cukA``` (figure above). There are three good domain matches (we generally consider E-values <0.001 as significant). So, it is likely, that your protein comprises three domains. The FunFams marked by blue box have a known structure. 

##### 2. Assigned domain architecture for cath|4_1_0|2fupA

![](/images/test_seq_2fupA_crh_resolved.png)

There is only one good domain match that covers the entire  length of the the query sequence ```cath|4_1_0|2fupA``` (figure above). So, it is likely, that your protein comprises a single domain.

#### (iii) test.domtblout
This is the raw FunFam scan file generated by HMMER3 which lists all the domain matches of your query sequence(s) to CATH FunFam models.

## 7. Retrieve alignments and GO annotations for an assigned CATH FunFam

The FunFam alignments are available in STOCKHOLM format through a RESTful API that contains UniProt accessions of the FunFam member sequences 
along with their annotations such as Gene Ontology (GO) and Enzyme Commission Number (EC) annotations along with other meta-data.

The script ```${PROJECTHOME}/apps/retrieve_FunFam_aln_GO_anno_CATH-API.pl``` uses the CATH API to fetch the FunFam alignment and returns GO terms of all characterised FunFam member sequences.

For retrieving alignments and GO annotation for a particular CATH FunFam: 

```
cd ${PROJECTHOME}
./apps/retrieve_FunFam_aln_GO_anno_CATH-API.pl 2.40.50.140/FF/58874 v4_1_0
```

The following result files will be available in the ```results/``` folder:

```
> cd ${PROJECTHOME}/results/
> ls 2.40.50.140.FF.58874*
 2.40.50.140.FF.58874.sto.aln  2.40.50.140.FF.58874.GO.anno
```

#### (i) FunFam alignment 

```
> cd ${PROJECTHOME}/results/`
> cat 2.40.50.140.FF.58874.sto.aln
# STOCKHOLM 1.0
#=GF ID 2.40.50.140/FF/58874
#=GF AC 2.40.50.140/FF/58874
#=GF DE Holliday junction DNA helicase RuvA
#=GF TP FunFam
#=GF DR CATH: v4.1
#=GF DR DOPS: 45.244
#=GS 1hjpA01/1-66        AC P0A809
#=GS 1hjpA01/1-66        OS Escherichia coli K-12
...
```

#### (ii) GO annotation file

```
> cd ${PROJECTHOME}/results/
> head 2.40.50.140.FF.58874.GO.anno
FUNFAM_RELATIVE/DOMAIN_RANGE        GO_ANNOTATIONS
1hjpA01/1-66        GO:0000725; GO:0003677; GO:0005524; GO:0005737; GO:0009378; GO:0009379; GO:0009432; GO:0032508; GO:0048476;
P66746/1-65         GO:0003677; GO:0005524; GO:0006281; GO:0006310; GO:0009378; GO:0009379; GO:0009432;
P0A809/1-65         GO:0000725; GO:0003677; GO:0005524; GO:0005737; GO:0009378; GO:0009379; GO:0009432; GO:0032508; GO:0048476;
Q83KR4/1-66         GO:0003677; GO:0005524; GO:0006281; GO:0006310; GO:0009378; GO:0009379; GO:0009432;
W1HVM5/1-66         GO:0003677; GO:0005524; GO:0006281; GO:0006310; GO:0009378; GO:0009432;
A0A0A2VCS0/983-1048 GO:0003677; GO:0004520; GO:0004812; GO:0005524; GO:0005737; GO:0006281; GO:0006310; GO:0006418; GO:0008828; GO:0009378; GO:0009379;
L7ACY6/1-63         GO:0005524; GO:0006281; GO:0006310; GO:0009378;
...
```

Kindly note that the annotations in these alignments were retrieved from UniProt during the most recent database release.


## 8. Using CATH API to access more information on CATH FunFams

Detailed CATH API documentation on accessing CATH FunFam data is available here: 

https://github.com/sillitoe/cath-api-docs/blob/master/README.md#functional-families-funfams

Example usage in Perl and shell/cURL for accessing example CATH data via Restful API is shown below: 

#### (i) shell/cURL
```
$ curl -w "\n" -s -X GET -H 'Accept: application/json' http://www.cathdb.info/version/v4_1_0/api/rest/superfamily/1.10.8.10/funfam/1302
```
#### (ii) Perl
```
#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
 
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->default_header( 'Accept' => 'application/json' );
 
my $url = 'http://www.cathdb.info/version/v4_1_0/api/rest/superfamily/1.10.8.10/funfam/1302';
 
 
my $response = $ua->get( $url );
 
if ( $response->is_success ) {
    print $response->decoded_content;
}
else {
    die $response->status_line;
}
```

# Relevant Links:

1. [Functional classification of CATH superfamilies: a domain-based approach for protein function annotation](https://doi.org/10.1093/bioinformatics/btv398)

2. [CATH FunFHMMer web server: protein functional annotations using functional family assignments](https://doi.org/10.1093/nar/gkv488)

3. [HMMER3 User Manual](ftp://ftp.hgc.jp/pub/mirror/wustl/hmmer3/3.1b1/Userguide.pdf)

