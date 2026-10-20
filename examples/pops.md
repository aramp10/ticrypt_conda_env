# Example: a scientific environment (PoPS)

Builds the exact environment tested with the 2020 PoPS scripts (pandas 2.3.3; the
scripts fail on pandas 3), from the pinned list [pops.explicit.txt](pops.explicit.txt).

## On BU SCC

First time using conda on SCC? Set up your `.condarc` first, following
[Miniconda Modules](https://www.bu.edu/tech/support/research/software-and-programming/common-languages/python/python-software/miniconda-modules/)
(`setup_scc_condarc.sh`).

> **Warning:** without a properly set up `.condarc`, conda stores environments in your
> SCC home directory (10 GB quota), which a few environments can easily fill.

```bash
module load miniconda/25.3.1

curl -fsSLO https://raw.githubusercontent.com/aramp10/ticrypt_conda_env/main/examples/pops.explicit.txt

conda create -y -n packer conda-pack

conda create -y -n pops --file pops.explicit.txt

conda activate packer
conda-pack -n pops -o pops.tar.gz
```

## Copy to tiCrypt

See tiCrypt's [Data Ingress and Egress](https://ticrypt.com/articles/data-ingress) guide
(see section for [Direct SFTP to VM](https://ticrypt.com/articles/data-ingress#direct-sftp-to-vm)).
Upload `pops.tar.gz` to `~/Downloads` on the VM.

## On tiCrypt

```bash
mkdir -p ~/conda/envs/pops
tar -xzf ~/Downloads/pops.tar.gz -C ~/conda/envs/pops
source ~/conda/envs/pops/bin/activate
conda-unpack

python -c "import numpy, pandas, scipy, sklearn, statsmodels; print('ok')"
```

## Size

| packages | on SCC | packed | unpacked on tiCrypt |
|---|---|---|---|
| 53 | 564 MB | 189 MB | 587 MB |

Sizes vary with the package versions conda installs.
