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

Nextflow binary was included in the StarScope directory. User could also download binary
from [nextflow's github release page](https://github.com/nextflow-io/nextflow/releases/latest).

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

