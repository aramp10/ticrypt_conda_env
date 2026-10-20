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
conda create -y -n packer conda-pack

# build your environment
conda create -y -n myenv python=3.12 numpy pandas scipy

# pack it into myenv.tar.gz
conda activate packer
conda-pack -n myenv -o myenv.tar.gz
```

## Step 2 — Copy the file into tiCrypt

See tiCrypt's [Data Ingress and Egress](https://ticrypt.com/articles/data-ingress) guide
(see section for [Direct SFTP to VM](https://ticrypt.com/articles/data-ingress#direct-sftp-to-vm)).
Upload `myenv.tar.gz` to `~/Downloads` on the VM.

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

To leave the environment: `source ~/conda/envs/myenv/bin/deactivate`

## Step 4 — Check that it works

```bash
python -c "import numpy, pandas, scipy; print('ok')"
```

## Step 5 — Clean up (optional)

On tiCrypt, delete the archive once the environment works:

```bash
rm ~/Downloads/myenv.tar.gz
```

On SCC, you can delete the environment after packing it (keep `packer` for next time):

```bash
conda env remove -n myenv
```

## Examples

See [examples/](examples/README.md).
