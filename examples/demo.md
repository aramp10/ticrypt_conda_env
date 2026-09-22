# Example: a minimal environment

**Python 3.12 + numpy — 36 packages, 338 MB, packing to 118 MB.**

The smallest environment worth transferring. Use this to prove the pipeline works end to
end before committing to a large one: it moves in a few minutes instead of an hour, and
if something is wrong you find out cheaply. For a real environment see
[pops.md](pops.md).

Every command below is from [the guide](../README.md); this page just fills in one
concrete environment and shows what it produced.

## On BU SCC

```bash
module load miniconda/25.3.1

STAGE=/projectnb/<your_project>/conda_stage
mkdir -p $STAGE
export CONDA_PKGS_DIRS=$STAGE/pkgs

# helper env for the packing tool -- build once, reuse for every environment
conda create -y -p $STAGE/packer -c conda-forge conda-pack

# the environment being transferred
conda create -y -p $STAGE/demo \
    --override-channels -c conda-forge --no-default-packages \
    python=3.12 numpy

du -sh $STAGE/demo                    # 338M
conda list -p $STAGE/demo | wc -l     # 36 packages

$STAGE/packer/bin/conda-pack -p $STAGE/demo -o $STAGE/demo.tar.gz --n-threads 4
ls -lh $STAGE/demo.tar.gz             # 118M
md5sum $STAGE/demo.tar.gz             # record this -- you check it after the transfer
```

Note that "minimal" still means **36 packages**. Python's own dependencies plus OpenBLAS
and libgomp under numpy is the floor, not bloat.

The package cache (`$STAGE/pkgs`) grows to roughly three times the size of the
environment. It never crosses the air gap, and it makes later builds much faster, so
keep it until you are done building.

## Dry run on SCC before transferring

Worth the two minutes — it separates "bad pack" from "tiCrypt problem" before you move
anything.

```bash
mkdir -p packcheck && tar -xzf $STAGE/demo.tar.gz -C packcheck
env -i HOME=$HOME PATH=/usr/bin:/bin bash -c "
cd \$PWD/packcheck && source bin/activate && ./bin/conda-unpack && echo UNPACK_OK &&
python -c '
import numpy as np
print(\"numpy\", np.__version__)
a = np.random.rand(400,400)
print(\"BLAS ok:\", float((a@a.T).sum()) > 0)
from numpy.linalg import svd
print(\"LAPACK ok:\", svd(a, compute_uv=False)[0] > 0)
'"
```

```
UNPACK_OK
numpy 2.5.3
BLAS ok: True
LAPACK ok: True
```

`env -i` scrubs the shell completely — no conda, no modules, `PATH=/usr/bin:/bin`. That
is the point: it is the environment standing on its own, exactly as it will on tiCrypt.

## On tiCrypt

```bash
cd ~/Downloads
md5sum demo.tar.gz              # must match what SCC printed
df -h $HOME                     # confirm room for tarball + unpacked env at once

mkdir -p ~/conda/envs/demo
tar -xzf ~/Downloads/demo.tar.gz -C ~/conda/envs/demo
source ~/conda/envs/demo/bin/activate
conda-unpack

which python
python -c "
import numpy as np
print('numpy', np.__version__)
a = np.random.rand(400,400)
print('BLAS ok:', float((a@a.T).sum()) > 0)
"
du -sh ~/conda/envs/demo        # ~351M
```

`conda-unpack` prints nothing on success and runs once, ever. Activate **before**
running it — there is no bare `python` on tiCrypt's `PATH`, so its shebang only resolves
once the environment is active.

To leave the environment:

```bash
source ~/conda/envs/demo/bin/deactivate
```

## Result

| | |
|---|---|
| Packages | 36 |
| Environment on SCC | 338 MB |
| Tarball | 118 MB |
| Unpacked on tiCrypt | ~351 MB |

**This works with no conda installed on tiCrypt and no module loaded.** `conda-unpack`
ships inside the archive as a standalone script, so the environment depends on nothing
being present on the far side.
