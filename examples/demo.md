# Example: a minimal environment (`python=3.12 numpy`)

A small environment for trying out the steps before building a larger one.

## On BU SCC

```bash
module load miniconda/25.3.1

conda create -y -n packer conda-pack

conda create -y -n demo python=3.12 numpy

conda activate packer
conda-pack -n demo -o demo.tar.gz
```

## Copy to tiCrypt

See the [tiCrypt file transfer guide](https://github.com/katgit/BU-tiCrypt/tree/main/doc/tiCrypt_FileTransfer_Guide).

## On tiCrypt

```bash
mkdir -p ~/conda/envs/demo
tar -xzf ~/Downloads/demo.tar.gz -C ~/conda/envs/demo
source ~/conda/envs/demo/bin/activate
conda-unpack

python -c "import numpy as np; print('numpy', np.__version__)"
```

```
numpy 2.5.3
```

## Size

| packages | on SCC | packed | unpacked on tiCrypt |
|---|---|---|---|
| 36 | 338 MB | 118 MB | ~351 MB |

Sizes vary with the package versions conda installs.
