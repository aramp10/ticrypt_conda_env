# Example: a scientific environment (PoPS)

`python=3.12 numpy "pandas<3" scipy scikit-learn statsmodels`

The 2020 PoPS scripts (`pops.feature_selection.py`, `pops.predict_scores.py`) need
**pandas < 3**. With pandas 3 they fail: `TypeError: read_table() got an unexpected
keyword argument 'delim_whitespace'`.

## On BU SCC

```bash
module load miniconda/25.3.1

conda create -y -n packer conda-pack

conda create -y -n pops python=3.12 numpy "pandas<3" scipy scikit-learn statsmodels

conda activate packer
conda-pack -n pops -o pops.tar.gz
```

To build exactly the versions tested here (pandas 2.3.3), use the pinned list
[pops.explicit.txt](pops.explicit.txt) instead of the package list:

```bash
conda create -y -n pops --file pops.explicit.txt
```

## Copy to tiCrypt

See the [tiCrypt file transfer guide](https://github.com/katgit/BU-tiCrypt/tree/main/doc/tiCrypt_FileTransfer_Guide).

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
