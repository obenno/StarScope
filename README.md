# StarScope

`StarScope` provide a convenient way to run the 
[scRNA-seq workflow](https://github.com/obenno/scRNA-seq)
which uses **starsolo** (https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md) 
and **Seurat** package (https://satijalab.org/seurat/) as the core modules to process scRNA-seq
data and generate a concise HTML report. 
The workflow was implemented by [**nextflow**](https://www.nextflow.io/).

## Installation

### Dependencies

- Java 8 or higher
- conda/miniconda
- or docker

`StarScope` will automatically check dependencies, install nextflow and
create conda environment if conda is selected as running environment. 
But user will have to install [`Java`](https://openjdk.java.net/install/) and 
[`miniconda`](https://docs.conda.io/en/latest/miniconda.html) 
manually. It is suggested to install
[`mamba`](https://mamba.readthedocs.io/en/latest/installation.html) 
via `conda install -n base -c conda-forge mamba` to speedup environment
creating process. By default, the nextflow binary will be downloaded in the working directory, user could move it to \$PATH.

Alternatively, user could use docker container as running environment. But `docker` has to be installed on the system:

```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

To use docker command without `sudo`, add account to `docker` group:

```
sudo usermod -aG docker $(whoami)
```
Then login out and login again for the changes to take effect.

`starscope` will pull the image automatically when invoke commands. If the network is not stable, user could pull the image manually with:

```
docker pull registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/thunderbio_scrnaseq_env:2.7.10a
```

### Get Code

```
git clone --recurse-submodules https://github.com/obenno/StarScope.git
```

### Add `starscope` to PATH

User could add `starscope` to PATH via creating
symbolic link (assuming `~/.local/bin` is in the $PATH): 

```
ln -s /git/repo/starscope ~/.local/bin/
```

## Prepare STAR reference

We included a bash script for user to generate 10x compatible reference. 10x has removed some genes from the standard genecode annotation. Please refer to their [website](https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header) for detail process procedures.

To generate human reference with conda, use command below:

```
prepare_10x_compatible_reference.sh human --cpus 8 --mem 32.GB -bg
```

user could use `prepare_10x_compatible_reference.sh -h` to get the full help:

```
prepare_10x_compatible_reference.sh will help you to generate
10x cellranger compatible STAR reference set. The detail preparing
procedures could be referred from 10x's documentation website:
https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header

Usage:
prepare_10x_compatible_reference.sh <human|mouse|hm|all> [starscope_options]

prepare_10x_compatible_reference.sh human    generate human GRh38 reference
prepare_10x_compatible_reference.sh mouse    generate mouse mm10 reference
prepare_10x_compatible_reference.sh hm       combine GRh38 and mm10 to
                                             generate reference for hybrid
                                             sample analysis
prepare_10x_compatible_reference.sh all      generate all three reference
                                             datasets mentioned above

starscope_options:
--executor        Define executor of nextflow (local), see:
                  https://www.nextflow.io/docs/latest/executor.html
--cpus            CPUs to use for all processes (8)
--mem             Memory to use for all processes, please note
                  the special format (16.GB)
--noDepCheck      Do not check Java and nextflow before
                  running (false)
-bg               Running the pipeline in background (false)

example:
prepare_10x_compatible_reference.sh human --cpus 8 --mem 32.GB -bg
```

User could use their own genome fasta and GTF file to create STAR reference by invoking `starscope mkref` command.

## Usage

Please note the whitelist files have to be decompressed before passing to the program.
To run thunderbio dataset, decompress with `gunzip whitelist/V2_barcode_seq_210407_concat.txt.gz`
and use the `/path/to/V2_barcode_seq_210407_concat.txt` as the whitelist file in `starscope run` command.

### Example command

Run thunderbio data with conda env:
```
starscope <run> --conda \
                --input sampleList.csv \
                --genomeDir /path/to/STAR/reference \
                --genomeGTF /path/to/genomeGTF \
                --whitelist /path/to/whitelist \
                --trimLength 50 \
                --soloCBstart 1 \
                --soloCBlen 29 \
                --soloUMIstart 30 \
                --soloUMIlen = 10 \
                -bg
```


### Example sample list

The workflow takes a csv format sample list as input, which is the `sampleList.csv` 
in the command above. The sample list file only contains three 
column: `sample`, `fastq_1`, `fastq_2`. User only needs to specify sample name, 
path of read1 and read2. The program will assume that read1 file is the one 
containing barcode and UMI information. Both absolute and relative path are supported. 
If the library has multiple runs (i.e. multiple files of R1 and R2), user could indicate 
the path of those files with identical sample name, and they will be `cat` into one 
in the analysis.

```
sample,fastq_1,fastq_2
sampleID,read1.fq.gz,/absolute/path/to/read2.fq.gz
```

### Resources

Please ensure that you have enough resource for `StarScope`:

- Human GRh38 genome needs at least 32GB memory

- Hybrid sample (human and mouse cells) may need 50-60GB memory

### Main program

```
starscope uses starsolo and Seurat package as the core modules to process
scRNA-seq data and generate a concise html report. The workflow was
implemented by nextflow.

Running pipeline:
starscope <run> --conda \
                --input sampleList.csv \
                --genomeDir /path/to/STAR/reference \
                --genomeGTF /path/to/genomeGTF \
                --whitelist /path/to/whitelist \
                --trimLength 28 \
                --soloCBstart 1 \
                --soloCBlen 29 \
                --soloUMIstart 30 \
                --soloUMIlen = 10 \
                -bg

Example input list (csv):
sample,fastq_1,fastq_2
sampleName,read1.fq.gz,/absolute/path/to/read2.fq.gz

Making Reference:
starscope <mkref> --conda \
                  --genomeFasta /path/to/genome/fasta \
                  --genomeGTF /path/to/genome/gtf \
                  --refoutDir reference_out_dir \
                  -bg

starscope has two valid subcommands:
    run:      run the scRNAseq analysis pipeline with nextflow
    mkref:    prepare STAR reference

Please use -h option following each subcommand to get detail
of the options: e.g. starscope run -h
```

### `run` command

```
Basic Usage:
============
starscope <run> --conda \
                --input sampleList.csv \
                --genomeDir /path/to/STAR/reference \
                --genomeGTF /path/to/genomeGTF \
                --whitelist /path/to/whitelist \
                --trimLength 28 \
                --soloCBstart 1 \
                --soloCBlen 29 \
                --soloUMIstart 30 \
                --soloUMIlen 10 \
                -bg

options:
  --conda               Use conda env to run (true)
  --docker              Use docker container to run
  --input               Input sample list, csv format, required
                        columns include "sample" for sampleName,
                        "fastq_1" for read1, "fastq_2" for read2,
                        and read1 is assumed to contain cell
                        barcode.
  --genomeDir           Path of STAR reference directory
  --genomeGTF           Path of reference genome GTF file
  --whitelist           Path of whitelist of barcodes
  --trimLength          Min read length retained after cutadapt
                        trimming (28)
  --soloCBstart         Cell barcode start base in read1 (1)
  --soloCBlen           Cell barcode length (29)
  --soloUMIstart        UMI start base in read1 (30)
  --soloUMIlen          UMI length (10)
  --soloFeatures        Define whether only count UMI in exon region:
                        Gene or GeneFull which includes both exon and
                        intron reads (GeneFull)
  --soloMultiMappers    Counting method for reads mapping to multiple genes:
                        Unique or EM (Unique)
  --soloStrand          Library strandness, Forward for thunderbio
                        3' RNA-seq, Reverse for 5' RNA-seq (Forward)
  --config              Provide a custom nextflow config file to
                        define all parameters
  --executor            Define executor of nextflow (local), see:
                        https://www.nextflow.io/docs/latest/executor.html
  --cpus                CPUs to use for all processes (8)
  --mem                 Memory to use for all processes, please note
                        the special format (32.GB)
  --noDepCheck          Do not check Java and nextflow before
                        running (false)
  -bg                   Running the pipeline in background (false)
```

### `mkref` command

```
Basic Usage:
===========
starscope <mkref> --conda \
                  --genomeFasta /path/to/genome/fasta \
                  --genomeGTF /path/to/genome/gtf \
                  --refoutDir reference_out_dir \
                  -bg

options:
  --conda           Use conda env to run (true)
  --genomeFasta     Path of reference FASTA file
  --genomeGTF       Path of reference GTF file
  --config          Provide a custom nextflow config file to
                    define all parameters
  --executor        Define executor of nextflow (local), see:
                    https://www.nextflow.io/docs/latest/executor.html
  --cpus            CPUs to use for all processes (8)
  --mem             Memory to use for all processes, please note
                    the special format (16.GB)
  --noDepCheck      Do not check Java and nextflow before
                    running (false)
  -bg               Running the pipeline in background (false)

```

### `check_version` command

```
Basic Usage:
===========
starscope <check_version> [--conda|--docker]

options:
  --conda     print program version of conda env
  --docker    print program version in docker container
```

## Advance Usage

User could use a local config file and submit jobs to job scheduler on HPC (e.g. `slurm`):

```
starscope run --input sampleList.csv --config local.config -bg
```

Example config for thunderbio 3' scRNA-seq data:

```
params {
  genomeDir = "/path/to/STAR/reference/"
  genomeGTF = "/path/to/reference/genes.gtf"
  whitelist = "/path/to/whitelist"
  trimLength = 50
  soloCBstart = 1
  soloCBlen = 29
  soloUMIstart = 30
  soloUMIlen = 10
  soloMultiMappers = "Unique"
  enable_conda = true
}

process {
  executor = "slurm" // remove this line if use local executor
  conda = "/path/to/miniconda3/envs/starscope_env"
  // adjust resources here
  withLabel: process_high {
    cpus = 8
    memory = 32.GB
  }
  withLabel: process_medium {
    cpus = 4
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
}
```

For docker container, please use the config below:

```
params {
  genomeDir = "/path/to/STAR/reference/"
  genomeGTF = "/path/to/reference/genes.gtf"
  whitelist = "/path/to/whitelist"
  trimLength = 50
  soloCBstart = 1
  soloCBlen = 29
  soloUMIstart = 30
  soloUMIlen = 10
  soloMultiMappers = "Unique"
}

process {
  executor = 'slurm'
  //conda = "/home/xzx/Tools/miniconda3/envs/scRNA_thunderbio_env"
  container = "registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/thunderbio_scrnaseq_env:2.7.10a"
  withLabel: process_high {
    cpus = 8
    memory = 32.GB
  }
  withLabel: process_medium {
    cpus = 4
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
}

docker.enabled = true
docker.userEmulation = true
docker.runOptions = '-u $(id -u):$(id -g) --init'
```


All parameters could be found in the `nextflow.config` file.

## Output

- **results**: main output directory
  - **pipeline\_info**: store plain text execution_trace file
  - **cutqc**: store cutadapt trimming report generated by customized R markdown script
  - **starsolo**: store `starsolo` output files, including barcode/UMI matrix, summary files etc.
  - **qualimap**: store `qualimap` report
  - **report**: contain main HTML report files

- **work**: intermediate directory, could be safely removed after running complete

## Issues

Please note that `StarScope` only supports one sample (library) each sampleList for now.

## Release Note

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
