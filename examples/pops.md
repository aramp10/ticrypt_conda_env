# Example: a real scientific environment (PoPS)

**`python=3.12 numpy pandas scipy scikit-learn statsmodels`** — 52 packages, 607 MB,
packing to 197 MB. Built on SCC and verified on tiCrypt end to end.

Same steps as [demo.md](demo.md), on a real five-package stack.

## 1. On BU SCC — build and pack

Run on a compute node, not a login node; the dependency solve takes several minutes.

```bash
module load miniconda/25.3.1

STAGE=/projectnb/<your_project>/conda_stage
mkdir -p $STAGE
export CONDA_PKGS_DIRS=$STAGE/pkgs

conda create -y -p $STAGE/packer -c conda-forge conda-pack

conda create -y -p $STAGE/pops \
    --override-channels -c conda-forge --no-default-packages \
    python=3.12 numpy pandas scipy scikit-learn statsmodels

du -sh $STAGE/pops                          # 607M  -- the prefix alone
conda list -p $STAGE/pops | grep -vc '^#'   # 52

conda list -p $STAGE/pops --explicit > pops.explicit.txt

$STAGE/packer/bin/conda-pack -p $STAGE/pops -o $STAGE/pops.tar.gz --n-threads 4
ls -lh $STAGE/pops.tar.gz                   # 197M
md5sum $STAGE/pops.tar.gz                   # record this
```

⚠️ Use `du -sh $STAGE/pops`, **not** `du -sh $STAGE/*`. The glob reported this
environment as 144 MB — less than the demo it's a superset of — because conda hardlinks
files from the package cache and one `du` invocation counts each inode once.

Six requested packages resolved to 52 total:

| python | numpy | pandas | scipy | scikit-learn | statsmodels |
|---|---|---|---|---|---|
| 3.12.14 | 2.5.3 | 3.0.6 | 1.18.1 | 1.9.1 | 0.15.0 |

[`pops.explicit.txt`](pops.explicit.txt) pins those 52 packages with conda-forge URLs.
Worth capturing even when no versions were requested — it's the only way to rebuild the
same set later:

```bash
conda create -y -p $STAGE/pops --file pops.explicit.txt
```

## 2. Dry run before transferring

```bash
mkdir -p packcheck && tar -xzf $STAGE/pops.tar.gz -C packcheck
env -i HOME=$HOME PATH=/usr/bin:/bin bash -c "
cd \$PWD/packcheck && source bin/activate && ./bin/conda-unpack && echo UNPACK_OK &&
python -c '
import numpy, pandas, scipy, sklearn, statsmodels
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
BLAS   ok: True
LAPACK ok: True
sklearn ok: True
statsmodels ok: True
```

**LAPACK is the line to watch.** A bad relocation imports cleanly and fails at the first
compiled call, and numpy alone never exercises LAPACK.

conda-pack printing no warnings is also the result you want — it warns on pip-installed
packages and refuses editable installs.

## 3. Transfer

Globus (SCC → your computer), then FileZilla "SFTP to VM" from the tiCrypt desktop app.
See the guide's [Step 2](../README.md#step-2--copy-the-archive-into-ticrypt).

## 4. On tiCrypt

```bash
cd ~/Downloads
md5sum pops.tar.gz              # must match SCC
df -h $HOME                     # needs room for tarball + unpacked env at once

mkdir -p ~/conda/envs/pops
tar -xzf ~/Downloads/pops.tar.gz -C ~/conda/envs/pops
source ~/conda/envs/pops/bin/activate
conda-unpack

which python                    # ~/conda/envs/pops/bin/python
du -sh ~/conda/envs/pops        # 625M
```

Then re-run the same `python -c` block from step 2, without the `env -i` wrapper. All
four checks passed at versions identical to SCC.

Leave the environment with `source ~/conda/envs/pops/bin/deactivate` — not
`conda deactivate`, since a packed environment has no `conda` in it.

## Result

| | demo | **PoPS** |
|---|---|---|
| Packages | 36 | **52** |
| On SCC | 338 MB | **607 MB** |
| Tarball | 118 MB | **197 MB** |
| Unpacked on tiCrypt | 351 MB | **625 MB** |
| Peak during unpack | ~470 MB | **~822 MB** |

Four packages on top of numpy added only 16 dependencies — they share OpenBLAS and
libgomp rather than each bringing their own. Check `df` against the **peak** figure:
during unpack the tarball and the unpacked environment exist at once.
