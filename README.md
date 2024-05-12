# StarScope

`StarScope` provides a convenient way to run [ThunderBio](http://thunder-bio.com/) single
cell analysis [**nextflow**](https://www.nextflow.io/) pipelines.
[scRNA-seq workflow](https://github.com/obenno/scRNA-seq)
uses **starsolo** (https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md)
and **Seurat** package (https://satijalab.org/seurat/) as the core modules to process 3' single
cell RNA-seq data and generate a concise HTML report. We also integrated single cell
immune repertopire and ATAC analysis workflows as other two subcommands, both of
which were also built using nextflow.

## Quick Start with ThunderBio Example Data

ThunderBio will provide human and mouse pre-built reference and two sets example data upon request.
The `demo_data` fold contains two directories, human and mouse. In each directory, user could invoke
the pipeline by running command below. Please note the reference index has to be placed in the
same parent folder of the `demo_data`.

```
## Human Data Testing with conda or docker
cd demo_data/human
starscope run --input sampleList.csv --config thunderbio_human_conda.config
starscope run --input sampleList.csv --config thunderbio_human_docker.config
```

```
## Mouse Data Testing with conda or docekr
cd demo_data/mouse

```


```
demo_data/
├── human
│   ├── human_test.R1.fq.gz
│   ├── human_test.R2.fq.gz
│   ├── sampleList.csv
│   ├── thunderbio_human_conda.config
│   └── thunderbio_human_docker.config
├── mouse
│   ├── mouse_test.R1.fq.gz
│   ├── mouse_test.R2.fq.gz
│   ├── sampleList.csv
│   ├── thunderbio_mouse_conda.config
│   └── thunderbio_mouse_docker.config
└── V2_barcode_seq_210407_concat.txt
```

## Release Note

### StarScope v1.1.4

- Updated script for saturation calculation, and included UMI and gene hist data for `{preseqR}` prediction

- Now a tsv summary file will be outputted in the report process

### StarScope v1.1.3

- Added `--outBAMsortingBinsN 300` option to STARsolo process to solve the RAM issue when sorting a very large BAM file, refer to [STAR #870](https://github.com/alexdobin/STAR/issues/870)

### StarScope v1.1.2

- Use soft link instead of cat when there is only one fastq file

- Added support for VDJ subworkflow to only analyze BCR or TCR dataset

- Added support for publishing saturation json file

### StarScope v1.1.1

- Honer the memory option in the report process

- Added option for publishing starsolo BAM output

- Added option to enable conda env for nextflow 22.10, and the nextflow version was fixed to 22.04

### StarScope v1.1.0

- Added VDJ workflow (GEX+VDJ)

- Removed time limit for process resources

- Modified the margin of the tables in the 3'-scRNA-Seq report

- Adjusted knee plot to fixed size and center positioned

### StarScope v1.0.0

- Added pipeline running information to the reports

- Fixed issue for saturation calculation script when there is no whitelist provided

- Output a full list of DEGs

### StarScope v0.0.9

- Updated STAR to v2.7.10a in both the docker image and the conda environment

- Adapt the pipeline to generate report for starsolo `--soloMultiMappers` option, only "Unique" and "EM" are supported by now.

- Changed the default parameter for `--soloFeatures` to "GeneFull", which includes both exon and **intron** reads

### StarScope v0.0.8

- Fixed the issue that RunPCA uses up all cores and consumes too much memory ([Seurat #3991](https://github.com/satijalab/seurat/issues/3991))

- Changed h5file format to H5Seurat

- Disabled sass cache in rmd report

- Changed future package strategy to multisession to avoid fork errors

### StarScope v0.0.7

- **Raw gene/barcode count table will be stored in a loom file and published for subsequent analysis**

- **Mapping metrics will be written to a json file**

- **Added support for 5' RNA-seq library**


### StarScope v0.0.6

- **Now the BAM output will not by published**

- **Added support for counting intron reads**

- Added `check_version` command, to print all software versions including docker or conda engine information

- Fixed STAR to 2.7.9a and samtools to 1.15

- Fixed issue that no report generated if too few cells detected

### StarScope v0.0.5

- Fixed issue that no report generated if there are too few cells left after filtering by nFeature >= 200

### StarScope v0.0.3, v0.0.4

- Set thunderbio data running parameters as defaults instead of 10x parameters

- Added whitelists for thunderbio V2, 10x V2 and V3

- Fixed nextflow default path issue

- Fixed conda env name issue

- Implemented docker container running environment

- Added a new script for user to generate 10x compatible STAR reference

### StarScope v0.0.2

- Implemented `mkref` command

- Added output section for README

### StarScope v0.0.1

- Implemented `run` command

- Added running env checking procedure
