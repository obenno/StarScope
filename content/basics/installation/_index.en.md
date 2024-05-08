---
title: Installation
weight: 2
---

## Requirements

- Java 11 or higher
- Nextflow
- Conda/miniconda
- Docker

### Java

Nextflow will need java 11 or higher to be installed. The recommanded way to install
java is through [SDKMAN](https://sdkman.io/). Please use the command below:

Install SDKMAN:

```
curl -s https://get.sdkman.io | bash
```

Open a new terminal and install Java

```
sdk install java 17.0.10-tem
```

Check java installation and comfirm it's version

```
java -version
```

### Nextflow

Nextflow binary was already included in the StarScope directory. User also could download binary
from [nextflow's github release page](https://github.com/nextflow-io/nextflow/releases/latest).

By default, `starscope` will invoke the nextflow executable stored in the same directory, user
could add both of the two executables to `$PATH` (e.g. ~/.local/bin)

```
## starscope executable
ln -s starscope/starscope ~/.local/bin/starscope
## nextflow
ln -s starscope/nextflow ~/.local/bin/nextflow
```

Confirm that nextflow runs properly with the command below (require network access to github):

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

### Conda/miniconda

We usually use [miniforge's conda distro](https://github.com/conda-forge/miniforge), user also
could install via conda official installer, or use mamba directly, which is much faster.

Miniforge:

```
wget -c https://github.com/conda-forge/miniforge/releases/download/24.3.0-0/Mambaforge-24.3.0-0-Linux-x86_64.sh
bash Mambaforge-24.3.0-0-Linux-x86_64.sh
```

Official minicoda:

```
wget -c wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

Micromamba, user may need to put micromamba binary into $PATH

```
# Linux Intel (x86_64):
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
```

One could create conda environment with the yaml file in the workflow directory.

```
## scRNA-seq/VDJ environment
mamba create -f scRNA-seq/scRNAseq_env.yml

## scATAC-seq environment
mamba create -f scATAC-seq/scATAC_env.yml
```

### Docker

Using docker is much easier to integrate the workflow to large infrastructure
like cloud platforms or HPC, thus is recommended. To install:

```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

To use docker command without sudo, add your account to docker group:

```
sudo usermod -aG docker $(whoami)
```

Then login out and login again for the changes to take effect.

Please pull the pre-built image with:

```
## scATAC-seq image
docker pull registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/starscope_scatac_env:latest

## scRNA-seq/VDJ image
docker pull registry-intl.cn-hangzhou.aliyuncs.com/thunderbio/starscope_scrnaseq_env:latest
```
