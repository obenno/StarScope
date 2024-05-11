---
title: Invoke with StarScope
weight: 2
---

## Input

The input sample list file is csv file with five columns: `sample`,
`fastq_1`, `fastq_2`, `feature_types` and `expected_cells`. The 
fourth column represents library types: **GEX**, **VDJ-T** or **VDJ-B**.
A sample with only **VDJ-T** or **VDJ-B** library is supported, but
all the samples must have at least one VDJ library. Please
use **scRNA-seq** workflow if you only have **GEX** library.
The first column `sample` indicates sample IDs, and multiple fastq 
files with the same sample ID will be concatenated before further
processing (e.g. two pairs of `human_pbmc_s1` fastq files will be 
cat to a single pair). Multiple samples in one single sample list 
will be submitted parallelly and processed asynchronously. The
fourth column indicates expected number of cells used for
**starsolo** `--soloCellFilter` parameter.

```
sample,fastq_1,fastq_2,feature_types,expected_cells
human_test,human_test_gex.R1.fq.gz,human_test_gex.R2.fq.gz,GEX,3000
human_test,human_test_tcr.R1.fq.gz,human_test_tcr.R2.fq.gz,VDJ-T,2000
human_pbmc_s1,human_pbmc_s1_gex_R1_001.fastq.gz,human_pbmc_s1_gex_R2_001.fastq.gz,GEX,8000
human_pbmc_s1,human_pbmc_s1_gex_R1_002.fastq.gz,human_pbmc_s1_gex_R2_002.fastq.gz,GEX,8000
human_pbmc_s1,human_pbmc_s1_bcr.R1.fastq.gz,human_pbmc_s1,human_pbmc_s1_bcr.R2.fastq.gz,VDJ-B,1000
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
  
  // 5' VDJ specific params
  // trust4 reference
  trust4_vdj_refGenome_fasta = "/starscope/scRNA-seq/vdj/reference/hg38_bcrtcr.fa"
  trust4_vdj_imgt_fasta = "/starscope/scRNA-seq/vdj/reference/human_IMGT+C.fa"
  // strand reverse
  soloStrand = "Reverse"
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
  withName: VDJ_CELLCALLING_WITHOUTGEX {
    cpus = 10
    memory = 20.GB
  }
  withName: VDJ_CELLCALLING_WITHGEX {
    cpus = 10
    memory = 20.GB
  }
  withName: GET_VERSIONS_VDJ {
    cpus = 2
    memory = 10.GB
  }
  withName: VDJ_ASSEMBLY {
    cpus = 32
    memory = 30.GB
  }
  withName: VDJ_METRICS {
    cpus = 2
    memory = 10.GB
  }
  withName:REPORT_VDJ {
    cpus = 4
    memory = 40.GB
  }
}
```
{{% /tab %}}
{{< /tabs >}}

### Invoke with command line options

To invoke scATAC pipeline with conda environment:

{{< tabs >}}
{{% tab title="ThunderBio_v3" %}}
```bash
starscope vdj_gex --conda \
                  --conda_env /path/to/conda/env \
                  --input sampleList.csv \
                  --genomeDir /path/to/STAR/reference/dir \
                  --genomeGTF /path/to/genomeGTF \
                  --whitelist "/path/to/TB_v3_20240429.BC1.tsv /path/to/TB_v3_20240429.BC2.tsv /path/to/TB_v3_20240429.BC3.tsv" \
                  --trust4_vdj_refGenome_fasta /path/to/refGenome_vdj_fasta \
                  --trust4_vdj_imgt_fasta /path/to/imgt_vdj_fasta \
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

For instance, a typical file structure of the index folder will be like below:

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


## Outputs

Each sample will have a separated result folder named with sample ID. The sub-directory `final`
contains most of the result files:

- HTML report (e.g. TB\_pbmc\_test\_VDJ\_report.html)
- TCR/BCR trust4 report tsv file (e.g. TB\_pbmc\_test\_BCR\_results.tsv).
- TCR/BCR filtered report file, conains lineage information and only productive TCR/BCR (e.g. TB\_pbmc\_test\_BCR\_results.productiveOnly_withLineage.tsv).
- TCR/BCR cloneType table, with VDJ gene annotation (e.g. TB\_pbmc\_test\_BCR\_clonotypes.tsv)

gene expression matrix were strored under starsolo's result directory:

- **filtered** matrix, contains cell associated barcodes only:

```
results/sampelID/starsolo/GEX/sampleID_GEX.matrix_filtered
```

- **raw** matrix, contains all barcodes:

```
results/sampelID/starsolo/GEX/sampleID_GEX.matrix_raw
```

The `pipeline_info` directory contains statistics of the pipeline running resources.

Full output directory structure:

```
results/TB_pbmc_test/
├── cutqc
│   ├── TB_pbmc_test.cutadapt.json
│   ├── TB_pbmc_test_GEX.cutadapt.json
│   ├── TB_pbmc_test_VDJ-B.cutadapt.json
│   └── TB_pbmc_test_VDJ-T.cutadapt.json
├── final
│   ├── TB_pbmc_test_BCR_clonotypes.tsv
│   ├── TB_pbmc_test_BCR_results.productiveOnly_withLineage.tsv
│   ├── TB_pbmc_test_BCR_results.tsv
│   ├── TB_pbmc_test_GEX.saturation_out.json
│   ├── TB_pbmc_test_TCR_clonotypes.tsv
│   ├── TB_pbmc_test_TCR_results.productiveOnly_withLineage.tsv
│   ├── TB_pbmc_test_TCR_results.tsv
│   ├── TB_pbmc_test_VDJ-B.metrics.json
│   ├── TB_pbmc_test_VDJ-B.metrics.tsv
│   ├── TB_pbmc_test_VDJ_report.html
│   ├── TB_pbmc_test_VDJ-T.metrics.json
│   ├── TB_pbmc_test_VDJ-T.metrics.tsv
│   └── versions.json
├── multiqc
│   ├── TB_pbmc_test_GEX_multiqc_report.html
│   ├── TB_pbmc_test_multiqc_report.html
│   ├── TB_pbmc_test_VDJ-B_multiqc_report.html
│   └── TB_pbmc_test_VDJ-T_multiqc_report.html
├── saturation
│   └── TB_pbmc_test_GEX.saturation_out.json
├── starsolo
│   ├── GEX
│   │   ├── TB_pbmc_test_GEX.CellReads.stats
│   │   ├── TB_pbmc_test_GEX.Log.final.out
│   │   ├── TB_pbmc_test_GEX.Log.out
│   │   ├── TB_pbmc_test_GEX.Log.progress.out
│   │   ├── TB_pbmc_test_GEX.matrix_filtered
│   │   │   ├── barcodes.tsv.gz
│   │   │   ├── features.tsv.gz
│   │   │   └── matrix.mtx.gz
│   │   ├── TB_pbmc_test_GEX.matrix_raw
│   │   │   ├── barcodes.tsv.gz
│   │   │   ├── features.tsv.gz
│   │   │   └── matrix.mtx.gz
│   │   ├── TB_pbmc_test_GEX.SJ.out.tab
│   │   ├── TB_pbmc_test_GEX_summary.unique.csv
│   │   └── TB_pbmc_test_GEX_UMIperCellSorted.unique.txt
│   ├── VDJ-B
│   │   ├── TB_pbmc_test_VDJ-B.CellReads.stats
│   │   ├── TB_pbmc_test_VDJ-B.Log.final.out
│   │   ├── TB_pbmc_test_VDJ-B.Log.out
│   │   ├── TB_pbmc_test_VDJ-B.Log.progress.out
│   │   ├── TB_pbmc_test_VDJ-B.matrix_filtered
│   │   ├── TB_pbmc_test_VDJ-B.SJ.out.tab
│   │   ├── TB_pbmc_test_VDJ-B_summary.unique.csv
│   │   └── TB_pbmc_test_VDJ-B_UMIperCellSorted.unique.txt
│   └── VDJ-T
│       ├── TB_pbmc_test_VDJ-T.CellReads.stats
│       ├── TB_pbmc_test_VDJ-T.Log.final.out
│       ├── TB_pbmc_test_VDJ-T.Log.out
│       ├── TB_pbmc_test_VDJ-T.Log.progress.out
│       ├── TB_pbmc_test_VDJ-T.matrix_filtered
│       ├── TB_pbmc_test_VDJ-T.SJ.out.tab
│       ├── TB_pbmc_test_VDJ-T_summary.unique.csv
│       └── TB_pbmc_test_VDJ-T_UMIperCellSorted.unique.txt
└── trust4
    ├── VDJ-B
    │   ├── TB_pbmc_test_VDJ-B_barcode_airr.tsv
    │   ├── TB_pbmc_test_VDJ-B_barcode_report.filterDiffusion.tsv
    │   ├── TB_pbmc_test_VDJ-B.cloneType_out.tsv
    │   ├── TB_pbmc_test_VDJ-B_final.out
    │   ├── TB_pbmc_test_VDJ-B_readsAssign.out
    │   ├── TB_pbmc_test_VDJ-B.vdj_cellOut.tsv
    │   └── TB_pbmc_test_VDJ-B.vdj_metrics.json
    └── VDJ-T
        ├── TB_pbmc_test_VDJ-T_barcode_airr.tsv
        ├── TB_pbmc_test_VDJ-T_barcode_report.filterDiffusion.tsv
        ├── TB_pbmc_test_VDJ-T.cloneType_out.tsv
        ├── TB_pbmc_test_VDJ-T_final.out
        ├── TB_pbmc_test_VDJ-T_readsAssign.out
        ├── TB_pbmc_test_VDJ-T.vdj_cellOut.tsv
        └── TB_pbmc_test_VDJ-T.vdj_metrics.json

15 directories, 63 files
```

## WorkDir

By default, the intermediate files will be written to sub-directory of 
`work` under the pipeline running directory, please feel free to
remove it after all the processes finished successfully.
