---
title: Invoke with StarScope
weight: 2
---

## Input

The input sample list file is a simple csv with four columns. 
The first column `sample` indicates sample IDs, and multiple fastq 
files with the same sample ID will be concatenated before further
processing (e.g. two pairs of `human_pbmc_s1` fastq files will be 
cat to a single pair). Multiple samples in one single sample list 
will be submitted parallelly and processed asynchronously. The
fourth column indicates expected number of cells used for
**starsolo** `--soloCellFilter` parameter.

```
sample,fastq_1,fastq_2,expected_cells
human_test,human_test.R1.fq.gz,human_test.R2.fq.gz,3000
human_pbmc_s1,human_pbmc_s1_R1_001.fastq.gz,human_pbmc_s1_R2_001.fastq.gz,8000
human_pbmc_s1,human_pbmc_s1_R1_002.fastq.gz,human_pbmc_s1_R2_002.fastq.gz,8000
```

{{% notice style="note" %}}
All samples in the sampleList will use the same options. Therefore, a combination of samples from different species is not supported.
{{% /notice %}}

## Command

### Invoke with config file

Due to the abundance of processes and options, we suggest utilizing a custom 
configuration file when invoking the pipeline. This allows for greater 
control over resource management. ThunderBio has released two versions of the 
chemistry, each with a distinct barcode structure. Please refer to the 
corresponding configuration examples provided below.

```
starscope gex --input sampleList.csv --config example_docker.config
```

{{< tabs >}}
{{% tab title="example_docker.ThunderBio_v2.config" %}}
```json
params {
  genomeDir = "/refdata/human/starsolo/"
  genomeGTF = "/refdata/human/refdata-gex-GRCh38-2020-A/genes/genes.gtf"
  whitelist = "starscope/whitelist/V2_barcode_seq_210407_concat.txt"
  trimLength = 50
  soloType = "CB_UMI_Simple"
  soloCBstart = 1
  soloCBlen = 29
  soloUMIstart = 30
  soloUMIlen = 10
  publishSaturation = true
}

// uncomment line below if using slurm, see https://www.nextflow.io/docs/latest/executor.html
// process.executor = 'slurm'

// uncomment below chunk if using conda
// process.conda = "/home/xzx/Tools/mambaforge/envs/starscope_scRNAseq_env"
// conda.enabled = true

// docker setting, comment chunk below if using conda
process.container = "registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/starscope_scrnaseq_env:1.2.5"
docker.enabled = true
docker.userEmulation = true
docker.runOptions = '--init -u $(id -u):$(id -g) $(opt=""; for group in $(id -G); do opt=$opt" --group-add $group"; done; echo $opt)'

// Resouces for each process
process {
  withLabel: process_high {
    cpus = 16
    memory = 40.GB
  }
  withLabel: process_medium {
    cpus = 4
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
    withLabel: process_high {
    cpus = 32
    memory = 32.GB
  }
  withLabel: process_medium {
    cpus = 32
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
  withName: CHECK_SATURATION {
    cpus = 4
    memory = 10.GB
  }
  withName: CAT_FASTQ {
    cpus = 2
    memory = 4.GB
  }
  withName: TRIM_FASTQ {
    cpus = 12
    memory = 20.GB
  }
  withName: MULTIQC {
    cpus = 4
    memory = 10.GB
  }
  withName: STARSOLO {
    cpus = 16
    memory = 40.GB
  }
  withName: REPORT {
    cpus = 4
    memory = 40.GB
  }
  withName: FEATURESTATS {
    cpus = 2
    memory = 8.GB
  }
  withName: GENECOVERAGE {
    cpus = 8
    memory = 10.GB
  }
}
```
{{% /tab %}}
{{% tab title="example_docker.ThunderBio_v3.config" %}}
```json
params {
  genomeDir = "/refdata/human/starsolo/"
  genomeGTF = "/refdata/human/refdata-gex-GRCh38-2020-A/genes/genes.gtf"
  whitelist = "/starscope/whitelist/TB_v3_20240429.BC1.tsv /starscope/whitelist/TB_v3_20240429.BC2.tsv /starscope/whitelist/TB_v3_20240429.BC3.tsv"
  soloType = "CB_UMI_Complex"
  trimLength = 50
  soloAdapterSequence = "NNNNNNNNNGTGANNNNNNNNNGACANNNNNNNNNNNNNNNNN"
  soloCBposition = "2_0_2_8 2_13_2_21 2_26_2_34"
  soloUMIposition = "2_35_2_42"
  soloCBmatchWLtype = "1MM"
  publishSaturation = true
}

// uncomment line below if using slurm, see https://www.nextflow.io/docs/latest/executor.html
// process.executor = 'slurm'

// uncomment below chunk if using conda
// process.conda = "/home/xzx/Tools/mambaforge/envs/starscope_scRNAseq_env"
// conda.enabled = true

// docker setting, comment chunk below if using conda
process.container = "registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/starscope_scrnaseq_env:1.2.5"
docker.enabled = true
docker.userEmulation = true
docker.runOptions = '--init -u $(id -u):$(id -g) $(opt=""; for group in $(id -G); do opt=$opt" --group-add $group"; done; echo $opt)'

// Resouces for each process
process {
  withLabel: process_high {
    cpus = 16
    memory = 40.GB
  }
  withLabel: process_medium {
    cpus = 4
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
    withLabel: process_high {
    cpus = 32
    memory = 32.GB
  }
  withLabel: process_medium {
    cpus = 32
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
  withName: CHECK_SATURATION {
    cpus = 4
    memory = 10.GB
  }
  withName: CAT_FASTQ {
    cpus = 2
    memory = 4.GB
  }
  withName: TRIM_FASTQ {
    cpus = 12
    memory = 20.GB
  }
  withName: MULTIQC {
    cpus = 4
    memory = 10.GB
  }
  withName: STARSOLO {
    cpus = 16
    memory = 40.GB
  }
  withName: REPORT {
    cpus = 4
    memory = 40.GB
  }
  withName: FEATURESTATS {
    cpus = 2
    memory = 8.GB
  }
  withName: GENECOVERAGE {
    cpus = 8
    memory = 10.GB
  }
}
```
{{% /tab %}}
{{% tab title="example_docker.10X_v3.config" %}}
```json
params {
  genomeDir = "/refdata/human/starsolo/"
  genomeGTF = "/refdata/human/refdata-gex-GRCh38-2020-A/genes/genes.gtf"
  whitelist = "3M-february-2018.txt"
  trimLength = 28
  soloType = "CB_UMI_Simple"
  soloCBstart = 1
  soloCBlen = 16
  soloUMIstart = 17
  soloUMIlen = 12
  publishSaturation = true
}

// uncomment line below if using slurm, see https://www.nextflow.io/docs/latest/executor.html
// process.executor = 'slurm'

// uncomment below chunk if using conda
// process.conda = "/home/xzx/Tools/mambaforge/envs/starscope_scRNAseq_env"
// conda.enabled = true

// docker setting, comment chunk below if using conda
process.container = "registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/starscope_scrnaseq_env:1.2.5"
docker.enabled = true
docker.userEmulation = true
docker.runOptions = '--init -u $(id -u):$(id -g) $(opt=""; for group in $(id -G); do opt=$opt" --group-add $group"; done; echo $opt)'

// Resouces for each process
process {
  withLabel: process_high {
    cpus = 16
    memory = 40.GB
  }
  withLabel: process_medium {
    cpus = 4
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
    withLabel: process_high {
    cpus = 32
    memory = 32.GB
  }
  withLabel: process_medium {
    cpus = 32
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 4
    memory = 20.GB
  }
  withName: CHECK_SATURATION {
    cpus = 4
    memory = 10.GB
  }
  withName: CAT_FASTQ {
    cpus = 2
    memory = 4.GB
  }
  withName: TRIM_FASTQ {
    cpus = 12
    memory = 20.GB
  }
  withName: MULTIQC {
    cpus = 4
    memory = 10.GB
  }
  withName: STARSOLO {
    cpus = 16
    memory = 40.GB
  }
  withName: REPORT {
    cpus = 4
    memory = 40.GB
  }
  withName: FEATURESTATS {
    cpus = 2
    memory = 8.GB
  }
  withName: GENECOVERAGE {
    cpus = 8
    memory = 10.GB
  }
}
```
{{% /tab %}}
{{< /tabs >}}

### Invoke with command line options

To invoke scATAC pipeline with conda environment:

{{< tabs >}}
{{% tab title="ThunderBio_v2" %}}
```bash
starscope gex --conda \
              --conda_env /path/to/env \
              --input sampleList.csv \
              --genomeDir /path/to/STAR/reference/dir \
              --genomeGTF /path/to/genomeGTF \
              --whitelist /path/to/whitelist/V2_barcode_seq_210407_concat.txt \
              --trimLength 28 \
              --soloType CB_UMI_Simple \
              --soloCBstart 1 \
              --soloCBlen 29 \
              --soloUMIstart 30 \
              --soloUMIlen 10

```
{{% /tab %}}
{{% tab title="ThunderBio_v3" %}}
```bash
starscope gex --conda \
              --conda_env /path/to/env \
              --input sampleList.csv \
              --genomeDir /path/to/STAR/reference/dir \
              --genomeGTF /path/to/genomeGTF \
              --whitelist "/path/to/TB_v3_20240429.BC1.tsv /path/to/TB_v3_20240429.BC2.tsv /path/to/TB_v3_20240429.BC3.tsv" \
              --trimLength 28 \
              --soloType CB_UMI_Complex \
              --soloAdapterSequence NNNNNNNNNGTGANNNNNNNNNGACANNNNNNNNNNNNNNNNN \
              --soloCBposition "2_0_2_8 2_13_2_21 2_26_2_34" \
              --soloUMIposition 2_35_2_42 \
              --soloCBmatchWLtype 1MM
```
{{% /tab %}}
{{< /tabs >}}

user will have to add `--conda` and indicate conda env path with `--conda_env`. To check
your env path, please use `mamba env list`: 

```bash
# conda environments:
#
base                       /home/xzx/Tools/mambaforge
starscope_scRNAseq_env     /home/xzx/Tools/mambaforge/envs/starscope_scRNAseq_env
```

and provide the second column (e.g. `/home/xzx/Tools/mambaforge/envs/starscope_scRNAseq_env`).


### Required Options

**`--genomeDir`**: [STARsolo](https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md) reference index path. 

For instance, a typical file structure of the index folder will be like:

```bash
## human hg38
/refdata/human/starsolo/
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
```

To create the index above, use the command below:

```bash
STAR  --runMode genomeGenerate \
      --runThreadN 10 \
      --genomeDir /path/to/outputDir \
      --genomeFastaFiles /path/to/genome.fa  \
      --sjdbGTFfile /path/to/genes.gtf
```

**`--genomeGTF`**: reference genome GTF file path.

User could generate the "filtered" GTF file using 10X's mkref tool: https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/advanced/references

**`--whitelist`**: The white list file(s) path. ThunderBio whitelist files were distributed with StarScope:

```
/starscope/whitelist/
├── TB_v3_20240429.BC1.tsv
├── TB_v3_20240429.BC2.tsv
├── TB_v3_20240429.BC3.tsv
└── V2_barcode_seq_210407_concat.txt.gz
```

For ThunderBio chemistry v3, please use 

```
--whitelsit "/starscope/whitelist/TB_v3_20240429.BC1.tsv /starscope/whitelist/TB_v3_20240429.BC2.tsv /starscope/whitelist/TB_v3_20240429.BC3.tsv"

```

and use **decompressed** `V2_barcode_seq_210407_concat.txt.gz` for ThunderBio chemistry v2:

```
--whitelist /starscope/whitelist/V2_barcode_seq_210407_concat.txt
```

Other options are parsed to [STARsolo](https://github.com/alexdobin/STAR/blob/master/docs/STARsolo.md#all-parameters-that-control-starsolo-output-are-listed-again-below-with-defaults-and-short-descriptions)

```
soloType                    None
    string(s): type of single-cell RNA-seq
                            CB_UMI_Simple   ... (a.k.a. Droplet) one UMI and one Cell Barcode of fixed length in read2, e.g. Drop-seq and 10X Chromium.
                            CB_UMI_Complex  ... one UMI of fixed length, but multiple Cell Barcodes of varying length, as well as adapters sequences are allowed in read2 only, e.g. inDrop.
                            CB_samTagOut (Not supported)    ... output Cell Barcode as CR and/or CB SAm tag. No UMI counting. --readFilesIn cDNA_read1 [cDNA_read2 if paired-end] CellBarcode_read . Requires --outSAMtype BAM Unsorted [and/or SortedByCoordinate] (Not supported by StarScope for now)
                            SmartSeq (Not supported)        ... Smart-seq: each cell in a separate FASTQ (paired- or single-end), barcodes are corresponding read-groups, no UMI sequences, alignments deduplicated according to alignment start and end (after extending soft-clipped bases) (Not supported by StarScope for now)

soloCBstart                 1
    int>0: cell barcode start base

soloCBlen                   16
    int>0: cell barcode length

soloUMIstart                17
    int>0: UMI start base

soloUMIlen                  10
    int>0: UMI length

soloCBposition              -
    strings(s)              position of Cell Barcode(s) on the barcode read.
                            Presently only works with --soloType CB_UMI_Complex, and barcodes are assumed to be on Read2.
                            Format for each barcode: startAnchor_startPosition_endAnchor_endPosition
                            start(end)Anchor defines the Anchor Base for the CB: 0: read start; 1: read end; 2: adapter start; 3: adapter end
                            start(end)Position is the 0-based position with of the CB start(end) with respect to the Anchor Base
                            String for different barcodes are separated by space.
                            Example: inDrop (Zilionis et al, Nat. Protocols, 2017):
                            --soloCBposition  0_0_2_-1  3_1_3_8

soloUMIposition             -
    string                  position of the UMI on the barcode read, same as soloCBposition
                            Example: inDrop (Zilionis et al, Nat. Protocols, 2017):
                            --soloCBposition  3_9_3_14

soloAdapterSequence         -
    string:                 adapter sequence to anchor barcodes.

soloCellFilter              CellRanger2.2 3000 0.99 10
    string(s):              cell filtering type and parameters
                            None            ... do not output filtered cells
                            TopCells        ... only report top cells by UMI count, followed by the exact number of cells
                            CellRanger2.2   ... simple filtering of CellRanger 2.2.
                                                Can be followed by numbers: number of expected cells, robust maximum percentile for UMI count, maximum to minimum ratio for UMI count
                                                The harcoded values are from CellRanger: nExpectedCells=3000;  maxPercentile=0.99;  maxMinRatio=10
                            EmptyDrops_CR   ... EmptyDrops filtering in CellRanger flavor. Please cite the original EmptyDrops paper: A.T.L Lun et al, Genome Biology, 20, 63 (2019): https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1662-y
                                                Can be followed by 10 numeric parameters:  nExpectedCells   maxPercentile   maxMinRatio   indMin   indMax   umiMin   umiMinFracMedian   candMaxN   FDR   simN
                                                The harcoded values are from CellRanger:             3000            0.99            10    45000    90000      500               0.01      20000  0.01  10000
```


## Outputs

Each sample will have a separated result folder named with sample ID. The sub-directory `final`
contains most of the result files, including html report, gene expression matrix (**filtered**: 
contains cell associated barcodes only; **raw**: contains all barcodes).

The `pipeline_info` directory contains statistics of the pipeline running resources.

```
results/human_test/
├── cutqc
│   └── human_test.cutadapt.json
├── final
│   ├── human_test_DEG.tsv
│   ├── human_test.matrix_filtered
│   │   ├── barcodes.tsv.gz
│   │   ├── features.tsv.gz
│   │   └── matrix.mtx.gz
│   ├── human_test.matrix_raw
│   │   ├── barcodes.tsv.gz
│   │   ├── features.tsv.gz
│   │   └── matrix.mtx.gz
│   ├── human_test.metrics.json
│   ├── human_test.metrics.tsv
│   ├── human_test_report.html
│   └── human_test.saturation_out.json
├── multiqc
│   └── human_test_multiqc_report.html
└── starsolo
    ├── human_test.CellReads.stats
    ├── human_test.Log.final.out
    ├── human_test.Log.out
    ├── human_test.Log.progress.out
    ├── human_test.matrix_filtered
    │   ├── barcodes.tsv.gz
    │   ├── features.tsv.gz
    │   └── matrix.mtx.gz
    ├── human_test.matrix_raw
    │   ├── barcodes.tsv.gz
    │   ├── features.tsv.gz
    │   └── matrix.mtx.gz
    ├── human_test.SJ.out.tab
    ├── human_test_summary.unique.csv
    └── human_test_UMIperCellSorted.unique.txt

8 directories, 26 files
```

## WorkDir

By default, the intermediate files will be written to sub-directory of 
`work` under the pipeline running directory, please feel free to
remove it after all the processes finished successfully.
