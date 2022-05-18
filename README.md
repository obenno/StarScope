# StarScope

`StarScope` provide a convenient way to run the 
[scRNA-seq workflow](https://github.com/obenno/scRNA-seq)
which uses **starsolo** (https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md) 
and **Seurat** package (https://satijalab.org/seurat/) as the core modules to process scRNA-seq
data and generate a concise HTML report. 
The workflow was implemented by [**nextflow**](https://www.nextflow.io/).

## Installation

`StarScope` will automatically check dependencies, install nextflow and
create conda environment if conda is selected as running environment. 
But user will have to install [`Java`](https://openjdk.java.net/install/) and 
[`miniconda`](https://docs.conda.io/en/latest/miniconda.html) 
manually. It is suggested to install
[`mamba`](https://mamba.readthedocs.io/en/latest/installation.html) 
via `conda install -n base -c conda-forge mamba` to speedup environment
creating process.

### Dependencies

- Java 8 or higher
- conda/miniconda
- or docker (not ready)

### Get Code

```
git clone --recurse-submodules https://github.com/obenno/StarScope.git
```

or download compressed file from project release page.

### Add `starscope` to PATH

User could add `starscope` to PATH via creating
symbolic link (assuming `~/.local/bin` is in the PATH): 

```
ln -s /git/repo/starscope ~/.local/bin/
```

## Usage

### Main programme

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
                --soloUMIlen = 10 \
                -bg

options:
  --conda           Use conda env to run (true)
  --docker          Use docker container to run (not implemented)
  --input           Input sample list, csv format, required
                    columns include "sample" for sampleName,
                    "fastq_1" for read1, "fastq_2" for read2,
                    and read1 is assumed to contain cell
                    barcode.
  --genomeDir       Path of STAR reference directory
  --genomeGTF       Path of reference genome GTF file
  --whitelist       Path of whitelist of barcodes
  --trimLength      Min read length retained after cutadapt
                    trimming (28)
  --soloCBstart     Cell barcode start base in read1 (1)
  --soloCBlen       Cell barcode length (29)
  --soloUMIstart    UMI start base in read1 (30)
  --soloUMIlen      UMI length (10)
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

## Output

- **results**: main output directory
  - **pipeline\_info**: store plain text execution_trace file
  - **cutqc**: store cutadapt trimming report generated by customized R markdown script
  - **starsolo**: store `starsolo` output files, including barcode/UMI matrix, summary files etc.
  - **qualimap**: store `qualimap` report
  - **report**: contain main HTML report files

- **work**: intermediate directory, could be safely removed after running complete


## Release Note

### StarScope v0.0.3

- Set thunderbio data running parameters as defaults instead of 10x parameters

- Added whitelists for thunderbio V2, 10x V2 and V3

### StarScope v0.0.2

- Implemented `mkref` command

- Added output section for README

### StarScope v0.0.1

- Implemented `run` command

- Added running env checking procedure
