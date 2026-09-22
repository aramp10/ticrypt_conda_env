# Example: a minimal environment

**`python=3.12 numpy`** — 36 packages, 338 MB, packing to 118 MB.

The smallest environment worth transferring. Run this first to prove the pipeline works
before committing to a large one. For a real environment see [pops.md](pops.md).

## On BU SCC

```bash
module load miniconda/25.3.1

STAGE=/projectnb/<your_project>/conda_stage
mkdir -p $STAGE
export CONDA_PKGS_DIRS=$STAGE/pkgs

conda create -y -p $STAGE/packer -c conda-forge conda-pack

conda create -y -p $STAGE/demo \
    --override-channels -c conda-forge --no-default-packages \
    python=3.12 numpy

du -sh $STAGE/demo                    # 338M
conda list -p $STAGE/demo | wc -l     # 36

$STAGE/packer/bin/conda-pack -p $STAGE/demo -o $STAGE/demo.tar.gz --n-threads 4
ls -lh $STAGE/demo.tar.gz             # 118M
md5sum $STAGE/demo.tar.gz             # record this
```

## Dry run before transferring

```bash
mkdir -p packcheck && tar -xzf $STAGE/demo.tar.gz -C packcheck
env -i HOME=$HOME PATH=/usr/bin:/bin bash -c "
cd \$PWD/packcheck && source bin/activate && ./bin/conda-unpack && echo UNPACK_OK &&
python -c 'import numpy as np; print(\"numpy\", np.__version__)'"
```

```
UNPACK_OK
numpy 2.5.3
```

## On tiCrypt

```bash
cd ~/Downloads
md5sum demo.tar.gz              # must match SCC

mkdir -p ~/conda/envs/demo
tar -xzf ~/Downloads/demo.tar.gz -C ~/conda/envs/demo
source ~/conda/envs/demo/bin/activate
conda-unpack

python -c "
import numpy as np
print('numpy', np.__version__)
a = np.random.rand(400,400)
print('BLAS ok:', float((a@a.T).sum()) > 0)
"
du -sh ~/conda/envs/demo        # ~351M
```

```
numpy 2.5.3
BLAS ok: True
```

Leave the environment with `source ~/conda/envs/demo/bin/deactivate`.

## Result

| packages | on SCC | tarball | unpacked on tiCrypt |
|---|---|---|---|
| 36 | 338 MB | 118 MB | ~351 MB |

Note that "minimal" still means 36 packages — Python's own dependencies plus OpenBLAS
under numpy. That's the floor.
