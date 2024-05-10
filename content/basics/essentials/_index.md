---
title: Essentials
weight: 9
---

## Running Information

After invoking the pipeline, nextflow will report the progress
to stdout, with each row representing a process.

```
N E X T F L O W  ~  version 23.10.1
Launching `/thunderData/pipeline/starscope/scRNA-seq/main.nf` [adoring_ekeblad] DSL2 - revision: 8e27902b23
executor >  slurm (9)
[e0/1d00d4] process > scRNAseq:CAT_FASTQ (human_test)        [100%] 1 of 1 ✔
[37/8c0795] process > scRNAseq:TRIM_FASTQ (human_test)       [100%] 1 of 1 ✔
[20/1edf9b] process > scRNAseq:MULTIQC (human_test)          [100%] 1 of 1 ✔
[5a/e0becc] process > scRNAseq:STARSOLO (human_test)         [100%] 1 of 1 ✔
[02/15a3b1] process > scRNAseq:CHECK_SATURATION (human_test) [100%] 1 of 1 ✔
[09/e25428] process > scRNAseq:GET_VERSIONS (get_versions)   [100%] 1 of 1 ✔
[48/703c20] process > scRNAseq:FEATURESTATS (human_test)     [100%] 1 of 1 ✔
[79/cd2784] process > scRNAseq:GENECOVERAGE (human_test)     [100%] 1 of 1 ✔
[e6/808adf] process > scRNAseq:REPORT (human_test)           [100%] 1 of 1 ✔
Completed at: 09-May-2024 09:07:55
Duration    : 25m 9s
CPU hours   : 3.7
Succeeded   : 9
```

When encountering any error, nextflow will interrupt running and 
print error message to stderr directly.

User could also check the error message from running log file `.nextflow.log`

```bash
$ head .nextflow.log

May-09 08:42:37.523 [main] DEBUG nextflow.cli.Launcher - $> nextflow run /thunderData/pipeline/starscope/scRNA-seq -c /thunderData/pipeline/nf_scRNAseq_config/latest/thunderbio_human_config --input sampleList.csv
May-09 08:42:37.924 [main] INFO  nextflow.cli.CmdRun - N E X T F L O W  ~  version 23.10.1
May-09 08:42:38.096 [main] DEBUG nextflow.plugin.PluginsFacade - Setting up plugin manager > mode=prod; embedded=false; plugins-dir=/home/xzx/.nextflow/plugins; core-plugins: nf-amazon@2.1.4,nf-azure@1.3.3,nf-cloudcache@0.3.0,nf-codecommit@0.1.5,nf-console@1.0.6,nf-ga4gh@1.1.0,nf-google@1.8.3,nf-tower@1.6.3,nf-wave@1.0.1
May-09 08:42:38.147 [main] INFO  o.pf4j.DefaultPluginStatusProvider - Enabled plugins: []
May-09 08:42:38.150 [main] INFO  o.pf4j.DefaultPluginStatusProvider - Disabled plugins: []
May-09 08:42:38.163 [main] INFO  org.pf4j.DefaultPluginManager - PF4J version 3.4.1 in 'deployment' mode
May-09 08:42:38.234 [main] INFO  org.pf4j.AbstractPluginManager - No plugins
May-09 08:42:42.225 [main] DEBUG nextflow.config.ConfigBuilder - Found config base: /thunderData/pipeline/starscope/scRNA-seq/nextflow.config
May-09 08:42:42.231 [main] DEBUG nextflow.config.ConfigBuilder - User config file: /thunderData/pipeline/nf_scRNAseq_config/latest/thunderbio_human_config_v2
May-09 08:42:42.233 [main] DEBUG nextflow.config.ConfigBuilder - Parsing config file: /thunderData/pipeline/starscope/scRNA-seq/nextflow.config
```

## Nextflow Log CLI

After each invokation, the pipeline running information could be retrieved by `nextflow log` 
command, and user could check the `RUN NAME`, `STATUS` and `SESSION ID` from the command output.

```bash
$ nextflow log

TIMESTAMP          	DURATION	RUN NAME       	STATUS	REVISION ID	SESSION ID                          	COMMAND                                                                                                                                                      
2024-05-09 08:42:44	25m 12s 	adoring_ekeblad	OK    	8e27902b23 	8670925f-ce5a-4f7a-b327-a98b288e6aa6	nextflow run /thunderData/pipeline/starscope/scRNA-seq -c /thunderData/pipeline/nf_scRNAseq_config/latest/thunderbio_human_config --input sampleList.csv
```


## Work Dir and Intermediate Files

Each task of the process will be conducted in a sub-directory of the `workDir` set in
nextflow configuration file. By default, StarScope set this to **`work`** folder
under project running directory. To confirm each tasks' working directory, user
will have to check the task hash id with command below. The `adoring_ekeblad` is
the `RUN NAME` from `nextflow log` output.


```bash
$ nextflow log adoring_ekeblad -f hash,name,exit,status

e0/1d00d4	scRNAseq:CAT_FASTQ (human_test)	0	COMPLETED
09/e25428	scRNAseq:GET_VERSIONS (get_versions)	0	COMPLETED
37/8c0795	scRNAseq:TRIM_FASTQ (human_test)	0	COMPLETED
20/1edf9b	scRNAseq:MULTIQC (human_test)	0	COMPLETED
5a/e0becc	scRNAseq:STARSOLO (human_test)	0	COMPLETED
79/cd2784	scRNAseq:GENECOVERAGE (human_test)	0	COMPLETED
48/703c20	scRNAseq:FEATURESTATS (human_test)	0	COMPLETED
02/15a3b1	scRNAseq:CHECK_SATURATION (human_test)	0	COMPLETED
e6/808adf	scRNAseq:REPORT (human_test)	0	COMPLETED
```

To check **CAT_FASTQ** process task working directory, we could use it's hash_id (`e0/1d00d4`) to
locate the folder in `work`:

```bash
$ ls -a work/e0/1d00d49d7d562790a4d4f5993852ba/

.   .command.begin  .command.log  .command.run  .command.trace  human_test_1.merged.fq.gz  human_test.R1.fq.gz
..  .command.err    .command.out  .command.sh   .exitcode       human_test_2.merged.fq.gz  human_test.R2.fq.gz
```

The work directory always contains several important hidden files:

1. `.command.out` STDOUT from tool.
2. `.command.err` STDERR from tool.
3. `.command.log` contains both STDOUT and STDERR from tool.
4. `.command.begin` created as soon as the job launches.
5. `.exitcode` created when the job ends, with exit code.
6. `.command.trace` logs of compute resource usage.
7. `.command.run` wrapper script used to run the job.
8. `.command.sh` process command used for this task.

```bash
$ cat work/e0/1d00d49d7d562790a4d4f5993852ba/.command.sh 

#!/bin/bash -ue
ln -s human_test.R1.fq.gz human_test_1.merged.fq.gz
ln -s human_test.R2.fq.gz human_test_2.merged.fq.gz
```

## Running in Background

The nextflow pipeline could be execute in background, with `-bg` [option](https://www.nextflow.io/docs/latest/cli.html#options):

```bash
starscope gex --input sampleList.csv --config custom_config -bg
```

## Resume Previous Run

>One of the core features of Nextflow is the ability to cache task executions and re-use 
>them in subsequent runs to minimize duplicate work. Resumability is useful both for recovering 
>from errors and for iteratively developing a pipeline. 
>It is similar to [checkpointing](https://en.wikipedia.org/wiki/Application_checkpointing), 
>a common practice used by HPC applications.

To resume from previous run, please use the command below after entering the project running directory:

```bash
starscope gex --input sampleList.csv --config custom_config -bg -resume
```

Or resume from a specific run with session ID (check from `nextflow log` output):

```bash
starscope gex --input sampleList.csv --config custom_config -bg -resume 8670925f-ce5a-4f7a-b327-a98b288e6aa6
```

Additional resources:

- https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html
- https://www.nextflow.io/blog/2019/troubleshooting-nextflow-resume.html
- https://www.nextflow.io/docs/latest/cache-and-resume.html
