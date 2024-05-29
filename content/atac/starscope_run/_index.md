---
title: Invoke with StarScope
weight: 1
---

## Input

The input sample list file is a simple csv with three columns. 
The first column `sample` indicates sample IDs, and multiple fastq 
files with the same sample ID will be concatenated before further
processing (e.g. two pairs of `human_pbmc_s1` fastq files will be 
cat to a single pair). Multiple samples in one single sample list 
will be submitted parallelly and processed asynchronously. The workflow
supports both ThunderBio and 10X ATAC data, please use the suggested
configuration below. User could check 10X ATAC library structure
from https://teichlab.github.io/scg_lib_structs/.

{{< tabs >}}
{{% tab title="example_docker.ThunderBio_v3.config" %}}
```
sample,fastq_1,fastq_2
human_pbmc_s1,human_pbmc_s1_R1_001.fastq.gz,human_pbmc_s1_R2_001.fastq.gz
human_pbmc_s1,human_pbmc_s1_R1_002.fastq.gz,human_pbmc_s1_R2_002.fastq.gz
human_pbmc_s2,human_pbmc_s2_R1_001.fastq.gz,human_pbmc_s2_R2_001.fastq.gz
human_tissue_s1,human_tissue_s1_R1_001.fastq.gz,human_tissue_s1_R2_001.fastq.gz
```
{{% /tab %}}
{{% tab title="example_docker.10X_v2.config" %}}
```
sample,fastq_1,fastq_2,fastq_3
10X_pbmc_10k_v1,10X_pbmc_10k_v1_R1_001.fastq.gz,10X_pbmc_10k_v1_R2_001.fastq.gz,10X_pbmc_10k_v1_R3_001.fastq.gz
10X_pbmc_10k_v1,10X_pbmc_10k_v1_R1_002.fastq.gz,10X_pbmc_10k_v1_R2_002.fastq.gz,10X_pbmc_10k_v1_R3_002.fastq.gz
10X_pbmc_10k_v2,10X_pbmc_10k_v2_R1_001.fastq.gz,10X_pbmc_10k_v2_R2_001.fastq.gz,10X_pbmc_10k_v2_R3_001.fastq.gz
10X_pbmc_10k_v2,10X_pbmc_10k_v2_R1_002.fastq.gz,10X_pbmc_10k_v2_R2_002.fastq.gz,10X_pbmc_10k_v2_R3_002.fastq.gz
```
{{% /tab %}}
{{< /tabs >}}

{{% notice style="note" %}}
All samples in the sampleList will use the same options. Therefore, a combination of samples from different species is not supported.
{{% /notice %}}


{{% notice style="warning" %}}
We found that [seq library](https://github.com/exaloop/seq) doesn't support fastq file with quality 
score larger than 40 (denoted as **J** in the fourth line). Please check the quality encoding
on [FASTQ wiki page](https://en.wikipedia.org/wiki/FASTQ_format). The error message is like:

```
KeyError: J

Raised from: std.internal.types.collections.dict.Dict.__getitem__:0
/pipeline/starscope/scATAC-seq/codon/lib/codon/stdlib/internal/types/collections/dict.codon:74:9
/scATAC_test/work/09/284782e6058425c6966542b7a70944/.command.sh: line 9: 684639 Aborted                 (core dumped) /pipeline/starscope/scATAC-seq/codon/bin/codon run -release -plugin seq /pipeline/starscope/scATAC-seq/bin/extract_and_correct_thunderbio_barcode_from_fastq.codon TB_v3_20240429.BC1.tsv,TB_v3_20240429.BC2.tsv,TB_v3_20240429.BC3.tsv test_sample_1.merged.fq.gz test_sample_2.merged.fq.gz test_sample_1.barcode.fq test_sample_2.barcode.fq test_sample_barcode_stats.tsv 8
```

User could use the command below to convert "J" (Q=41) to "I" (Q=40):

```bash
for i in *.fq.gz; do zcat $i | awk 'NR%4==1{print; getline; print; getline; print; getline; gsub("J", "I"); print}' | gzip -c > ${i%%.fq.gz}".modified.fq.gz"; done
```
{{% /notice %}}
 
## Command

### Invoke with config file

Since there are too many processes and options, we recommend to invoke pipeline with custom
configuration file, which gives users more control on resources management.

```
starscope atac --input sampleList.csv --config example_docker.config
```


```json { title="example_docker.config" }
params {
  bwaIndex = "/refdata/human/bwa2_index/GRCh38-2020-A"
  genomeGTF = "/refdata/human/refdata-gex-GRCh38-2020-A/genes/genes.gtf"
  whitelist = "/barcodes/BC1.tsv /barcodes/BC2.tsv /barcodes/BC3.tsv" // TB whitelist
  // trimming options used by cutadapt
  trimOpt = '-a AGATGTGTATAAGAGACAG...CTGTCTCTTATACACATCTCCGAGCCCACGAGAC -A GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAG...CTGTCTCTTATACACATCT'
  // cell filtration
  minCell = 10 // feature obeseved in at least "minCell" cells
  minFeature = 200 // cells with at least "minFeature" features
  publishSaturation = true
  platform = "TB" // TB or 10X
}

// uncomment line below if using slurm, see https://www.nextflow.io/docs/latest/executor.html
// process.executor = 'slurm'

// uncomment below chunk if using conda
// process.conda = "/home/xzx/Tools/mambaforge/envs/starscope_scATAC_env"
// conda.enabled = true

// docker setting, comment chunk below if using conda
process.container = "registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/starscope_scatac_env:0.0.6"
docker.enabled = true
docker.userEmulation = true
docker.runOptions = '--init -u $(id -u):$(id -g) $(for group in $(id -G); do echo "--group-add $group"; done)'

// Resouces for each process
process {
  withLabel: process_high {
    cpus = 16
    memory = 32.GB
  }
  withLabel: process_medium {
    cpus = 16
    memory = 20.GB
  }
  withLabel: process_low {
    cpus = 16
    memory = 20.GB
  }
  withName: CAT_FASTQ {
    cpus = 2
    memory = 10.GB
  }
  withName: CAT_FASTQ_10X {
    cpus = 2
    memory = 10.GB
  }
  withName: REPORT {
    cpus = 8
    memory = 40.GB
  }
  withName: CHECK_BARCODE {
    cpus = 16
    memory = 20.GB
  }
  CHECK_BARCODE_10X {
    cpus = 16
    memory = 20.GB
  }
  withName: TRIM_FASTQ {
    cpus = 16
    memory = 20.GB
  }
  withName: BWA_MAPPING {
    cpus = 16
    memory = 32.GB
  }
  withName: STATS {
    cpus = 4
    memory = 20.GB
  }
  withName: DEDUP {
    cpus = 2
    memory = 20.GB
  }
  withName: CHECK_SATURATION {
    cpus = 4
    memory = 20.GB
  }
  withName: MULTIQC {
    cpus = 4
    memory = 20.GB
  }
  withName: GENERATE_FRAGMENTS {
    cpus = 16
    memory = 40.GB
  }
  withName: SIGNAC {
    cpus = 4
    memory = 40.GB
  }
}
```

### Invoke with command line options

To invoke scATAC pipeline with conda environment:

```bash
starscope atac --conda \
               --conda_env /path/to/conda/env \
               --input sampleList.csv \
               --bwaIndex /path/to/STAR/reference/dir \
               --genomeGTF /path/to/genomeGTF \
               --whitelist "/path/to/BC1.tsv /path/to/BC2.tsv /path/to/BC3.tsv" \
               --refGenome hg38 \
               --platform TB
```

user will have to add `--conda` and indicate conda env path with `--conda_env`. To check
your env path, please use `mamba env list`: 

```bash
# conda environments:
#
base                     /home/xzx/Tools/mambaforge
starscope_scATAC_env     /home/xzx/Tools/mambaforge/envs/starscope_scATAC_env
```

and provide the second column (e.g. `/home/xzx/Tools/mambaforge/envs/starscope_scATAC_env`).


### Required Options

**`--bwaIndex`**: [bwa-mem2](https://github.com/bwa-mem2/bwa-mem2) reference index path and file prefix. 

For instance, a typical file structure of the index folder will be like:

```bash
## human hg38
/thunderData/refdata/human/bwa2_index/
├── GRCh38-2020-A.0123
├── GRCh38-2020-A.amb
├── GRCh38-2020-A.ann
├── GRCh38-2020-A.bwt.2bit.64
└── GRCh38-2020-A.pac
```

To create the index above, use the command below:

```bash
bwa-mem2 index -p GRCh38-2020-A genome.fa
```

user will have to provide `--bwaIndex /thunderData/refdata/human/bwa2_index/GRCh38-2020-A` to starscope command.

**`--genomeGTF`**: reference genome GTF file path.

**`--refGenome`**: reference genome assembly ID.

This parameter is used to extract genome size when calling peaks with `macs2`. Here we support 
hg38, hg19, mm9 and mm10 for human and mosue genome. User could use `--genomeSize` to indicate
genome size directly.

**`--platform`**: StarScope scATAC pipeline supports ATAC data from both the ThunderBio and 10X genomics. Use either
`TB` or `10X` here.

**`--whitelist`**: The white list file(s) path. For ThunerBio scATAC data, whitelist files were distributed with StarScope:

```
starscope/whitelist/
├── TB_v3_20240429.BC1.tsv
├── TB_v3_20240429.BC2.tsv
├── TB_v3_20240429.BC3.tsv
└── V2_barcode_seq_210407_concat.txt.gz
```

Please use the whilelist option below, and don't forget to add double quote.

```
--whitelsit "/path/to/starscope/whitelist/TB_v3_20240429.BC1.tsv /path/to/starscope/whitelist/TB_v3_20240429.BC2.tsv /path/to/starscope/whitelist/TB_v3_20240429.BC3.tsv"
```


## Outputs

Each sample will have a separated result folder named with sample ID. The subdirectory `final`
contains all the result files, including html report, fragments file (with all the barcodes)
and a list of cell associated barcodes identified (e.g. `TB_PBMC_s1_raw_cells.tsv`).

The `pipeline_info` directory contains statistics of the pipeline running resources.

```
results/
├── TB_PBMC_s1
│   ├── final
│   │   ├── TB_PBMC_s1_combined_stats.tsv
│   │   ├── TB_PBMC_s1_filtered_obj.rds
│   │   ├── TB_PBMC_s1.fragments.sorted.bed.gz
│   │   ├── TB_PBMC_s1.fragments.sorted.bed.gz.tbi
│   │   ├── TB_PBMC_s1_macs2_peaks.narrowPeak
│   │   ├── TB_PBMC_s1_raw_cells.tsv
│   │   ├── TB_PBMC_s1_raw_meta.tsv
│   │   └── TB_PBMC_s1_scATAC_report.html
│   ├── multiqc
│   │   └── TB_PBMC_s1_multiqc_report.html
│   └── saturation
│       └── TB_PBMC_s1.saturation_out.json
└── pipeline_info
    ├── execution_report_2024-05-02_22-34-11.html
    ├── execution_timeline_2024-05-02_22-34-11.html
    └── execution_trace_2024-05-02_22-34-11.txt

5 directories, 13 files
```

## WorkDir

By default, the intermediate files will be written to subdirectory of 
`work` under the pipeline running directory, please feel free to
remove it after all the processes finished successfully.
