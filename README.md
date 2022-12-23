# StarScope

`StarScope` provide a convenient way to run the 
[scRNA-seq workflow](https://github.com/obenno/scRNA-seq)
which uses **starsolo** (https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md) 
and **Seurat** package (https://satijalab.org/seurat/) as the core modules to process scRNA-seq
data and generate a concise HTML report. 
The workflow was implemented by [**nextflow**](https://www.nextflow.io/).

## Installation

### Dependencies

- Java 11 or higher
- Nextflow
- Conda/Miniconda
- or Docker Engine

`StarScope` will automatically check dependencies, install nextflow and
create conda environment if conda is selected as running environment. 
But user will have to install [`Java`](https://openjdk.java.net/install/) and 
[`Miniconda`](https://docs.conda.io/en/latest/miniconda.html) 
manually. It is suggested to install
[`mamba`](https://mamba.readthedocs.io/en/latest/installation.html) 
via `conda install -n base -c conda-forge mamba` to speedup environment
initiation process. By default, the nextflow binary will be downloaded in the working directory, user could move it to \$PATH.
Alternatively, user could use docker container as running environment. But `docker` has to be installed on the system:

#### Java

StarScope was tested with both openJDK and oracle Java SE version.

```
## download link may vary depending on java version
wget -c https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
## Java SE version
## wget -c https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
tar xvzf openjdk-17.0.2_linux-x64_bin.tar.gz
## set environment variable
export JAVA_HOME="$(pwd)/jdk-17.0.2"
export PATH="$(pwd)/jdk-17.0.2/bin:$PATH"
## it is suggested to add export cmd above to your .bashrc
```

#### Conda

Please use the corresponding installation script for your processor architecture.

```
wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

`starscope` will create conda environment automatically when invoking `run` subcommand
first time with the `--conda` option. User could create the environment
manually before running.

```
conda env create -f starscope/scRNA-seq/scRNAseq_env.yml
```

#### Docker

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

#### Nextflow

Download `nextflow` with:

```
curl -s https://get.nextflow.io | bash
```

Then mv the executable to `$PATH` (e.g. ~/.local/bin)

```
mv ./nextflow ~/.local/bin/
```

Confirm that nextflow runs properly

```
NXF_VER=22.04.5 nextflow run hello
```

The output will be:

```
N E X T F L O W ~ version 22.04.5
Launching `https://github.com/nextflow-io/hello` [distraught_ride] DSL2
- revision: 4eab81bd42 [master]
executor > local (4)
[92/5fbfca] process > sayHello (4) [100%] 4 of 4 ✔
Bonjour world!

Hello world!

Ciao world!

Hola world!
```

#### Get Code

Clone the repository from github:

```
git clone --recurse-submodules https://github.com/obenno/StarScope.git
```

User could add `starscope` to PATH via creating
symbolic link (assuming `~/.local/bin` is in the $PATH): 

```
ln -s /git/repo/starscope ~/.local/bin/
```

## Prepare STAR reference

User could use their own genome FASTA and GTF file to create STAR reference by invoking `starscope mkref` command. Example below used Zebrafish genome files as input.

```bash
## Zebrafish genome files are from Ensembl release 107
## https://uswest.ensembl.org/Danio_rerio/Info/Index
## Download genome FASTA file
wget -c http://ftp.ensembl.org/pub/release-107/fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz
## Download GTF file
wget -c http://ftp.ensembl.org/pub/release-107/gtf/danio_rerio/Danio_rerio.GRCz11.107.gtf.gz
```

`mkref` command:

```bash
starscope mkref --docker \
                --genomeFasta Danio_rerio.GRCz11.dna.primary_assembly.fa \
                --gtf Danio_rerio.GRCz11.107.gtf \
                --refoutDir Danio_rerio.GRCz11.107_STAR
```

We included a bash script for user to generate 10x compatible reference. 10x has removed some genes 
from the standard genecode annotation. Please refer to their 
[website](https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/build#header) 
for detail process procedures.

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

## Usage

Please note the whitelist files have to be decompressed before passing to the program.
To run ThunderBio dataset, decompress with `gunzip whitelist/V2_barcode_seq_210407_concat.txt.gz`
and use the `/path/to/V2_barcode_seq_210407_concat.txt` as the whitelist file in `starscope run` command.

Please also note `--mem` option of `run` command needs a special format: e.g. `32.GB`. 

Please note user could use `-bg` to run the command in the background, and `--executor slurm` will submit the jobs to HPC `slurm` job scheduler.

### Example sample list

The workflow takes a csv format sample list as input, which is the `sampleList.csv` 
in the command above. The sample list file only contains three 
column: `sample`, `fastq_1`, `fastq_2`. User only needs to specify sample name, 
path of read1 and read2. The program will assume that read1 file is the one 
containing barcode and UMI information. Both absolute and relative path are supported. 
If the library has multiple runs (i.e. multiple files of R1 and R2), user could indicate the path of those files with identical sample name, and they will be `cat` into one 
in the analysis.

```
sample,fastq_1,fastq_2
sampleID,read1.fq.gz,/absolute/path/to/read2.fq.gz
```

For GEX+VDJ analysis, `sampleList.csv` will require an additional column `feature_types`.

```
sample,fastq_1,fastq_2,feature_types
vdj_sample1,gex_R1.fq.gz,gex_R2.fq.gz,GEX
vdj_sample1,vdj_t_R1.fq.gz,vdj_t_R2.fq.gz,VDJ-T
vdj_sample1,vdj_b_R1.fq.gz,vdj_b_R2.fq.gz,VDJ-B
```

### Example command

#### Create STAR reference index

```
starscope mkref --conda \
                --genomeFasta /path/to/genome/fasta \
                --genomeGTF /path/to/genome/gtf \
                --refoutDir reference_out_dir 
```



#### ThunderBio 3'-scRNA-seq

Run thunderbio 3'-scRNA-seq data with conda env:

```
starscope run --conda \
              --input sampleList.csv \
              --genomeDir /path/to/STAR/reference/dir \
              --genomeGTF /path/to/genomeGTF \
              --whitelist /path/to/whitelist \
              --trimLength 50 \
              --soloCBstart 1 \
              --soloCBlen 29 \
              --soloUMIstart 30 \
              --soloUMIlen 10 
```

#### ThunderBio 5'-scRNA-seq

Run thunderbio 5'-scRNA-seq data with conda env:

```
starscope run --conda \
              --input sampleList.csv \
              --genomeDir /path/to/STAR/reference/dir \
              --genomeGTF /path/to/genomeGTF \
              --whitelist /path/to/whitelist \
              --trimLength 50 \
              --soloCBstart 1 \
              --soloCBlen 29 \
              --soloUMIstart 30 \
              --soloUMIlen 10 \
              --soloStrand Reverse
```

#### ThunderBio GEX+VDJ

Run thunderbio 5'-scRNA-seq together with single cell VDJ libraries:

```
starscope vdj_gex --conda \
                  --input sampleList.csv \
                  --genomeDir /path/to/STAR/reference/dir \
                  --genomeGTF /path/to/genomeGTF \
                  --whitelist /path/to/whitelist \
                  --trust4_vdj_refGenome_fasta /path/to/refGenome_vdj_fasta \
                  --trust4_vdj_imgt_fasta /path/to/imgt_vdj_fasta \
                  --trimLength 28 \
                  --soloCBstart 1 \
                  --soloCBlen 29 \
                  --soloUMIstart 30 \
                  --soloUMIlen 10 \
```

The pre-built vdj reference fasta file for trust4 was also included in `starscope/scRNA-seq/vdj/reference`.

For human hg38:

- `trust4_vdj_refGenome_fasta` : `starscope/scRNA-seq/vdj/reference/hg38_bcrtcr.fa`

- `trust4_vdj_imgt_fasta` : `starscope/scRNA-seq/vdj/reference/human_IMGT+C.fa`

For mouse mm10:

- `trust4_vdj_refGenome_fasta` : `starscope/scRNA-seq/vdj/reference/GRCm38_bcrtcr.fa`

- `trust4_vdj_imgt_fasta` : `starscope/scRNA-seq/vdj/reference/mouse_IMGT+C.fa`

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
                --genomeDir /path/to/STAR/reference/dir \
                --genomeGTF /path/to/genomeGTF \
                --whitelist /path/to/whitelist \
                --trimLength 28 \
                --soloCBstart 1 \
                --soloCBlen 29 \
                --soloUMIstart 30 \
                --soloUMIlen 10 \
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

starscope has four valid subcommands:
    run:            run the scRNAseq analysis pipeline with nextflow
    mkref:          prepare STAR reference
    vdj_gex:        perform vdj+gex analysis
    check_version:  check software versions

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

### `vdj_gex` command

```
Basic Usage:
===========
Example sampleList.csv:
sample,fastq_1,fastq_2,feature_types
vdj_sample1,gex.R1.fq.gz,gex.R2.fq.gz,GEX
vdj_sample1,t.R1.fq.gz,t.R2.fq.gz,VDJ-T
vdj_sample1,b.R1.fq.gz,b.R2.fq.gz,VDJ-B

starscope <vdj_gex> --conda \
                    --input sampleList.csv \
                    --genomeDir /path/to/STAR/reference/dir \
                    --genomeGTF /path/to/genomeGTF \
                    --whitelist /path/to/whitelist \
                    --trust4_vdj_refGenome_fasta /path/to/refGenome_vdj_fasta \
                    --trust4_vdj_imgt_fasta /path/to/imgt_vdj_fasta \
                    --trimLength 28 \
                    --soloCBstart 1 \
                    --soloCBlen 29 \
                    --soloUMIstart 30 \
                    --soloUMIlen 10 \

options:
  --conda               Use conda env to run (true)
  --docker              Use docker container to run
  --input               Input sample list, csv format, required
                        columns include "sample" for sampleName,
                        "fastq_1" for read1, "fastq_2" for read2,
                            "feature_types" for library type
                            (GEX/VDJ-T/VDJ-B), and read1 is assumed
                            to contain cell barcode.
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
  //executor = "slurm" // uncomment this line to submit jobs to slurm job scheduler
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
  withName: REPORT {
    // adjust report memory config according to dataset size
    memory = 40.GB
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
  //executor = 'slurm' // uncomment this line to submit jobs to slurm job scheduler
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
  withName: REPORT {
    // adjust report memory config according to dataset size
    memory = 40.GB
  }
}

docker.enabled = true
docker.userEmulation = true
docker.runOptions = '-u $(id -u):$(id -g) --init'
```

All parameters could be found in the `starscope/scRNA-seq/nextflow.config` file.

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
