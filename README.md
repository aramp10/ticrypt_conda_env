# Transferring a conda environment to tiCrypt (work in progress)

tiCrypt has no internet access, so you can't install conda packages there. Instead,
build the environment on the **BU SCC**, pack it into one file with
[conda-pack](https://conda.github.io/conda-pack/), copy that file into tiCrypt, and
unpack it.

Decide on the full package list first. To add a package later, you have to repeat all
the steps.

## Step 1 — On BU SCC, build and pack the environment

Replace the package list with yours. If you haven't used conda on SCC before, run
`setup_scc_condarc.sh` once after `module load` so your environments are stored in
project space.

```bash
module load miniconda/25.3.1

# one-time: install the packing tool
conda create -y -n packer -c conda-forge conda-pack

# build your environment
conda create -y -n myenv \
    --override-channels -c conda-forge --no-default-packages \
    python=3.12 numpy pandas scipy

# pack it into myenv.tar.gz
conda activate packer
conda-pack -n myenv -o myenv.tar.gz
```

## Step 2 — Copy the file into tiCrypt

Follow BU's
[tiCrypt file transfer guide](https://github.com/katgit/BU-tiCrypt/tree/main/doc/tiCrypt_FileTransfer_Guide).
For an overview of all upload methods, see tiCrypt's
[Data ingress](https://ticrypt.com/articles/data-ingress) article.

## Step 3 — On tiCrypt, unpack the environment

```bash
mkdir -p ~/conda/envs/myenv
tar -xzf ~/Downloads/myenv.tar.gz -C ~/conda/envs/myenv
source ~/conda/envs/myenv/bin/activate
conda-unpack
```

Run these in this order. `conda-unpack` is only needed once.

In later sessions, activate with:

```bash
source ~/conda/envs/myenv/bin/activate
```

## Step 4 — Check that it works

```bash
python -c "import numpy, pandas, scipy; print('ok')"
```

## Examples

- [examples/demo.md](examples/demo.md) — `python=3.12 numpy`
- [examples/pops.md](examples/pops.md) — `numpy pandas scipy scikit-learn statsmodels`
