# Example: a real scientific environment (PoPS)

**Python 3.12 + numpy, pandas, scipy, scikit-learn, statsmodels — 52 packages, 607 MB,
packing to 197 MB.**

A complete run of [the guide](../README.md) on a real five-package scientific stack,
taken from an empty staging directory to a verified environment on tiCrypt in a single
day. Every command is reproduced below in the order it was actually run, with its real
output.

For the minimal version of the same workflow, see [demo.md](demo.md).

## 1. On BU SCC — build

```bash
module load miniconda/25.3.1

STAGE=/projectnb/<your_project>/conda_stage
mkdir -p $STAGE
export CONDA_PKGS_DIRS=$STAGE/pkgs

# helper env for the packing tool -- build once, reuse for every environment
conda create -y -p $STAGE/packer -c conda-forge conda-pack

conda create -y -p $STAGE/pops \
    --override-channels -c conda-forge --no-default-packages \
    python=3.12 numpy pandas scipy scikit-learn statsmodels
```

Run this on a compute node, not a login node — the dependency solve is the slow part and
takes several minutes.

`--override-channels` keeps everything off Anaconda's `defaults` channel (licensing);
`--no-default-packages` skips anything a stray `create_default_packages` setting would
add.

## 2. Measure

```bash
du -sh $STAGE/pops                          # 607M
conda list -p $STAGE/pops | grep -vc '^#'   # 52
```

⚠️ **Measure the prefix on its own.** `du -sh $STAGE/*` reported this environment as
**144 MB** — less than the minimal demo it is a superset of. Conda hardlinks files from
the package cache, and a single `du` invocation counts each inode once, so walking
`pkgs/` first attributes all the shared content there. The natural way to run this step
silently gives the wrong answer.

Six requested packages pulled in 52 total:

| package | version | build |
|---|---|---|
| python | 3.12.14 | `h5f976f7_3_cpython` |
| numpy | 2.5.3 | `py312he827f4e_0` |
| pandas | 3.0.6 | `np2py312h91ec553_0` |
| scipy | 1.18.1 | `py312h106c528_1` |
| scikit-learn | 1.9.1 | `np2py312h91ec553_0` |
| statsmodels | 0.15.0 | `np2py312h32d774f_2` |

Only 16 packages more than `python + numpy` alone, because pandas, scipy, scikit-learn
and statsmodels share OpenBLAS, libgomp and the rest of the compiled stack rather than
each bringing its own. **A scientific stack grows far more slowly than the package count
suggests.**

## 3. Capture the pinned spec

```bash
conda list -p $STAGE/pops --explicit > pops.explicit.txt
```

[`pops.explicit.txt`](pops.explicit.txt) — 52 packages with build strings and conda-forge
URLs. Do this even when no versions were requested: an unpinned `conda create` next month
resolves to whatever is newest then, and this file is the only way to get the same set
back.

```bash
conda create -y -p $STAGE/pops --file pops.explicit.txt   # rebuilds it exactly
```

## 4. Pack

```bash
$STAGE/packer/bin/conda-pack -p $STAGE/pops -o $STAGE/pops.tar.gz --n-threads 4
ls -lh $STAGE/pops.tar.gz    # 197M
md5sum $STAGE/pops.tar.gz
```

```
-rw------- 206273981 pops.tar.gz
a8c3beb6fe7da5b71aa70ea0f3dd1fbb  pops.tar.gz
```

Record both — you check them after the transfer. Your own build will produce a different
checksum; what matters is that it is unchanged on arrival.

**conda-pack printed no warnings, which is the result you want.** It warns on
pip-installed packages and refuses editable installs outright, so silence confirms the
environment is pure conda-forge.

## 5. Dry run on SCC before transferring

```bash
mkdir -p packcheck && tar -xzf $STAGE/pops.tar.gz -C packcheck
env -i HOME=$HOME PATH=/usr/bin:/bin bash -c "
cd \$PWD/packcheck && source bin/activate && ./bin/conda-unpack && echo UNPACK_OK &&
python -c '
import numpy, pandas, scipy, sklearn, statsmodels
print(\"numpy       \", numpy.__version__)
print(\"pandas      \", pandas.__version__)
print(\"scipy       \", scipy.__version__)
print(\"scikit-learn\", sklearn.__version__)
print(\"statsmodels \", statsmodels.__version__)

import numpy as np
a = np.random.rand(400, 400)
print(\"BLAS   ok:\", float((a @ a.T).sum()) > 0)

from scipy import linalg
print(\"LAPACK ok:\", linalg.svd(a, compute_uv=False)[0] > 0)

from sklearn.linear_model import LinearRegression
X = np.random.rand(200, 5); y = X @ np.arange(5) + 0.1
print(\"sklearn ok:\", LinearRegression().fit(X, y).coef_.shape == (5,))

import statsmodels.api as sm
print(\"statsmodels ok:\", sm.OLS(y, sm.add_constant(X)).fit().params.shape == (6,))
'"
```

```
UNPACK_OK
numpy        2.5.3
pandas       3.0.6
scipy        1.18.1
scikit-learn 1.9.1
statsmodels  0.15.0
BLAS   ok: True
LAPACK ok: True
sklearn ok: True
statsmodels ok: True
```

This matters more for a scientific stack than for numpy alone. **The LAPACK line is the
one to watch** — a broken OpenBLAS relocation typically imports cleanly and fails at the
first compiled call, and numpy alone never exercises LAPACK.

### Optional: confirm the glibc baseline

```bash
find packcheck -name '*.so*' -type f | while read f; do
    objdump -T "$f" 2>/dev/null | grep -o 'GLIBC_[0-9.]*'
done | sort -u -V | tail -1
```

```
GLIBC_2.17
```

Across **390 shared objects**, the highest glibc symbol version required is 2.17 —
conda-forge's baseline, below both SCC (2.28) and tiCrypt (2.34). Identical to the
two-package demo, so the guarantee holds at scale rather than being luck on a small
environment.

## 6. Transfer

Globus from the BU SCC collection to your local machine, then FileZilla
**Quickconnect → "SFTP to VM"** from the tiCrypt desktop application. See the guide's
Step 2.

## 7. On tiCrypt — verify, unpack, verify again

```bash
cd ~/Downloads
ls -l pops.tar.gz
md5sum pops.tar.gz
df -h $HOME
```

Byte count and checksum both matched SCC exactly. Check by the numbers, not by eye — a
truncated 197 MB file looks entirely normal in a directory listing.

```bash
mkdir -p ~/conda/envs/pops
tar -xzf ~/Downloads/pops.tar.gz -C ~/conda/envs/pops
source ~/conda/envs/pops/bin/activate
conda-unpack
```

`conda-unpack` prints nothing on success; the prompt gains a `(pops)` prefix. **Activate
before running it** — there is no bare `python` on tiCrypt's `PATH`, so its shebang only
resolves once the environment is active.

```bash
which python                    # ~/conda/envs/pops/bin/python
```

Then the same five-package check as step 5 (drop the `env -i` wrapper — just run the
`python -c` block):

```
numpy        2.5.3
pandas       3.0.6
scipy        1.18.1
scikit-learn 1.9.1
statsmodels  0.15.0
BLAS   ok: True
LAPACK ok: True
sklearn ok: True
statsmodels ok: True
```

```bash
du -sh ~/conda/envs/pops        # 625M
```

Identical versions, all compiled paths working, **with no conda installed and no module
loaded**.

## 8. Optional: check the thread limits

If the `miniconda` module is loaded, its modulefile sets `OMP_NUM_THREADS` and friends to
`1`, and **those apply to a packed environment too** — silently, with no warning. To see
what that costs:

```bash
nproc
python -c "
import time, numpy as np
a = np.random.rand(2000,2000)
t = time.time(); a @ a.T; print('matmul %.2fs' % (time.time()-t))
"
OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 python -c "
import time, numpy as np
a = np.random.rand(2000,2000)
t = time.time(); a @ a.T; print('matmul %.2fs' % (time.time()-t))
"
```

```
2
matmul 0.24s      # unthrottled
matmul 0.36s      # throttled to one thread
```

Setting the variables by hand is better than comparing two machines — it changes one
thing instead of confounding it with different hardware.

**`nproc` is the number that matters, not the timing.** On 2 cores the throttle can never
cost more than 2x, and measured it costs 1.5x. On a many-core machine it would hurt far
more. So check `nproc` before worrying about it, and don't load a module you don't need.

## 9. Leaving the environment

```bash
source ~/conda/envs/pops/bin/deactivate
```

Not `conda deactivate` — a packed environment has no `conda` binary in it at all.

## Result

| | demo | **PoPS** |
|---|---|---|
| Packages | 36 | **52** |
| Environment on SCC | 338 MB | **607 MB** (prefix) / 625 MB (extracted) |
| Tarball | 118 MB | **197 MB** |
| Unpacked on tiCrypt | 351 MB | **625 MB** |
| Peak during unpack | ~470 MB | **~822 MB** |
| Max glibc symbol | 2.17 | **2.17** (390 objects) |

Two notes on those numbers. The unpacked size on tiCrypt matched the SCC extraction
**exactly** — 625 MB both places; the 607 MB prefix figure is lower only because of
hardlink sharing with the package cache, so **quote the extracted size when planning
space**, not the prefix size. And peak usage during unpack is the tarball *plus* the
unpacked environment at once, which is the figure to check `df` against.
