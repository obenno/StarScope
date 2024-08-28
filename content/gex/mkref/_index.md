---
title: Make Reference
weight: 3
---

To build a genome reference index, StarScope included a subcommand
`mkref` to help user achieve this via nextflow run.

```
starscope mkref --conda \
--conda_env /path/to/env \
--genomeFasta genome.fa \
--genomeGTF genes.gtf 
```

The output index directory will be like:

```
results/STAR_reference/
├── chrLength.txt
├── chrNameLength.txt
├── chrName.txt
├── chrStart.txt
├── exonGeTrInfo.tab
├── exonInfo.tab
├── geneInfo.tab
├── Genome
├── genomeParameters.txt
├── Log.out
├── SA
├── SAindex
├── sjdbInfo.txt
├── sjdbList.fromGTF.out.tab
├── sjdbList.out.tab
└── transcriptInfo.tab

0 directories, 16 files
```

We also included a helper script to perform a [10X like filtration step](https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header) on reference
files downloaded from [Ensembl](https://ftp.ensembl.org/pub/release-112/), user could invoke with:

```
starscope/process_reference.sh --fasta origin_genome.fa.gz --gtf origin.gtf.gz
```
The output files are `genome.fa` and `genes.gtf` in the working directory.
