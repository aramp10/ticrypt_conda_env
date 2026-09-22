# Transferring a conda environment to tiCrypt

tiCrypt has no internet access, so `conda create` and `conda install` can't resolve
anything there. Instead you build the environment on the **BU SCC**, pack it into a
single relocatable tarball with [conda-pack](https://conda.github.io/conda-pack/),
carry that one file into tiCrypt, and unpack it. Nothing is solved or downloaded on
tiCrypt.

This is the same download → transfer → offline-install shape as the pip workflow in
[`install_python/ticrypt`](https://github.com/aramp10/install_python/tree/main/ticrypt),
one level up: there the unit that crosses the air gap is a folder of wheels, here it's
a whole built environment.

**Collect the full package list from the researcher before you start.** There is no
in-place install on tiCrypt — adding one package means rebuilding and re-transferring
the entire environment (see Options).

## Step 1 — On BU SCC, build the environment and pack it

`conda-pack` is not in SCC's base env, and that env is admin-owned and read-only, so
build a small helper env for the packing tool and keep it separate from the environment
you're shipping:

```bash
module load miniconda/25.3.1

STAGE=/projectnb/<your_project>/conda_stage
mkdir -p $STAGE
export CONDA_PKGS_DIRS=$STAGE/pkgs

# helper env -- the packing tool only; reusable, never transferred
conda create -y -p $STAGE/packer -c conda-forge conda-pack

# the deliverable
conda create -y -p $STAGE/myenv \
    --override-channels -c conda-forge --no-default-packages \
    python=3.12 numpy pandas scipy

du -sh $STAGE/myenv            # the prefix alone -- not `du -sh $STAGE/*`
conda list -p $STAGE/myenv | wc -l

$STAGE/packer/bin/conda-pack -p $STAGE/myenv -o $STAGE/myenv.tar.gz --n-threads 4
ls -lh $STAGE/myenv.tar.gz
md5sum $STAGE/myenv.tar.gz
```

`--override-channels` keeps everything off Anaconda's `defaults` channel (licensing);
`--no-default-packages` skips anything a stray `create_default_packages` setting would
otherwise add. Pin versions in the `conda create` line if the code was developed against
specific ones — an unpinned create gives you today's newest, and re-packing is the only
way to change it later.

**Measure before you pack.** Free space on tiCrypt is the binding constraint, not
bandwidth. Check what you have with `df -h $HOME` before you build, and budget for peak
usage during unpack being the tarball *plus* the unpacked environment at the same time.
Two measured points for reference:

| environment | packages | on SCC | tarball | unpacked |
|---|---|---|---|---|
| `python=3.12 numpy` | 36 | 338 MB | 118 MB | 351 MB |
| `+ pandas scipy scikit-learn statsmodels` | 52 | 607 MB | 197 MB | 625 MB |

A scientific stack grows more slowly than you'd expect — those four added only 16
packages, because they share OpenBLAS and libgomp rather than each bringing their own.

⚠️ **Measure the prefix on its own.** `du -sh $STAGE/*` under-reports an environment by
several-fold: conda hardlinks files from the package cache, and a single `du` invocation
counts each inode once, so walking `pkgs/` first attributes the shared content there. Use
`du -sh $STAGE/myenv`.

Note the package cache (`$STAGE/pkgs`) grows to several times the size of the
environment. It never crosses the gap; keep it while you're still building, then clear
it.

Optionally dry-run the pack on SCC before moving anything — it separates "bad pack" from
"tiCrypt problem" cheaply. `env -i` scrubs conda and the modules out of the shell so the
test resembles tiCrypt:

```bash
mkdir -p packcheck && tar -xzf $STAGE/myenv.tar.gz -C packcheck
env -i HOME=$HOME PATH=/usr/bin:/bin bash -c "
cd $PWD/packcheck && source bin/activate && ./bin/conda-unpack && echo UNPACK_OK &&
python -c 'import numpy as np; print(\"numpy\", np.__version__)'"
```

## Step 2 — Copy the archive into tiCrypt

Two hops; tiCrypt has no path to SCC directly.

**Hop 1 — SCC → your local computer.** Globus, from the BU SCC collection. Globus
checksums end-to-end, so this hop verifies itself.

**Hop 2 — local computer → tiCrypt.** FileZilla **Quickconnect → "SFTP to VM"**,
available only in the tiCrypt **desktop application**, not the browser version. Globus
cannot do this hop — it has no access to the VM. See BU's
[tiCrypt file transfer guide](https://github.com/katgit/BU-tiCrypt/tree/main/doc/tiCrypt_FileTransfer_Guide)
for the other supported transfer methods and their setup.

Hop 2 verifies nothing, so check the checksum on arrival and compare it to Step 1:

```bash
md5sum ~/Downloads/myenv.tar.gz
```

Check by the numbers, not by eye — a truncated 118 MB file looks entirely normal in a
directory listing.

## Step 3 — Inside tiCrypt, unpack and activate

In a shell with **nothing loaded** — the module is not required for any of this:

```bash
mkdir -p ~/conda/envs/myenv
tar -xzf ~/Downloads/myenv.tar.gz -C ~/conda/envs/myenv
source ~/conda/envs/myenv/bin/activate
conda-unpack
```

`conda-unpack` rewrites the absolute paths baked into the environment's scripts and
binaries to match where it actually landed. It runs **once**, ever.

**The order matters and is not stylistic.** `conda-unpack`'s shebang is bare `python`,
and there is no bare `python` anywhere on tiCrypt's `PATH` — it resolves only to the
environment's own interpreter, and only after `source bin/activate`. Activate first,
unpack second, or it fails on the shebang.

After that one-time unpack, use whichever activation you prefer in later sessions:

```bash
conda activate ~/conda/envs/myenv          # needs miniconda/25.3.1 loaded
source ~/conda/envs/myenv/bin/activate     # needs nothing
```

Both land in the same place. `conda activate` matches what you already do on SCC and
keeps conda's bookkeeping straight so `conda deactivate` behaves; `source bin/activate`
is the simpler mechanism and the fallback on VMs where the module isn't available.

You'll need to activate again at the start of each new tiCrypt session.

## Step 4 — Verify

Import is not enough. A bad relocation typically imports cleanly and fails at the first
*compiled* call, so exercise each package's compiled paths:

```bash
which python
python -c "
import numpy, pandas, scipy
print('numpy ', numpy.__version__)
print('pandas', pandas.__version__)
print('scipy ', scipy.__version__)

import numpy as np
a = np.random.rand(400, 400)
print('BLAS   ok:', float((a @ a.T).sum()) > 0)

from scipy import linalg
print('LAPACK ok:', linalg.svd(a, compute_uv=False)[0] > 0)
"
du -sh ~/conda/envs/myenv
```

`which python` should point inside `~/conda/envs/myenv`. The LAPACK line is the
important one — it's where a broken OpenBLAS relocation actually shows up.

## Options

- **Make `conda env list` show the environment.** It won't until the parent directory is
  registered: `conda config --append envs_dirs ~/conda/envs` (writes `~/.condarc`).
- **Adding a package.** Rebuild on SCC with the package added to `conda create`, re-pack,
  re-transfer. There is no in-place install; the tarball is opaque. This is the main cost
  of the approach.
- **Using conda against the environment.** With the module loaded and the env active,
  `conda list` and `conda info` work (local state only). Anything that resolves against
  channels — `conda install scipy` — fails. That's the air gap, not a misconfiguration.
- **Thread limits.** The `miniconda/25.3.1` modulefile sets the `OMP_NUM_THREADS` family
  to `1`, and that applies to a packed environment too. Loading the module you don't
  otherwise need makes numpy/scipy/scikit-learn run single-threaded. If you want threads,
  activate with `source bin/activate` and no module.
- **mamba.** With the module loaded, `MAMBA_ROOT_PREFIX` points at the read-only module
  tree even while your environment is active. Pass `-p <env>` explicitly to mamba.

## Caveats

- **Pack from a prefix, not the active environment.** conda-pack refuses to pack the
  environment you're currently in. Use `-p <path>` from outside.
- **pip-installed packages.** They pack, but conda-pack warns about them and
  `conda-unpack` only rewrites prefixes it knows about. Prefer conda-forge packages for
  anything with compiled extensions.
- **Editable (`-e`) installs** fail the pack outright rather than producing a silently
  broken bundle.

## Notes for RCS / admins

**SCC → tiCrypt is the safe direction for glibc.** SCC is AlmaLinux 8 (glibc 2.28),
tiCrypt is AlmaLinux 9 (glibc 2.34). conda-forge builds against a glibc 2.17 baseline —
below both — and glibc is backward compatible, so 2.17 binaries run on both. The
dangerous direction is the reverse, and since the connected side is always the older
machine here, this workflow never hits it. This is a property of *conda-forge packages*,
not of conda-pack — a `pip install` that compiled against SCC's system libraries carries
no such guarantee.

**`conda-unpack` ships inside the archive.** conda-pack generates `bin/conda-unpack`
into the tarball as a standalone script carrying a vendored copy of conda's
prefix-rewriting logic. It depends on neither conda nor conda-pack being present on the
target — which is why a packed environment works on tiCrypt with **no conda installed
and no module loaded**, and why the packing tool belongs in a helper env rather than in
researcher environments.

**The module does not interfere.** `miniconda/25.3.1`'s modulefile prepends only
`condabin` to `PATH`, never `bin`, so the module's own interpreter is never on `PATH` —
only the `conda` shim. An activated packed env wins, and `CONDA_PREFIX` points at it
correctly.

**VM module systems differ.** Older tiCrypt VMs don't carry the current module list, so
`miniconda/25.3.1` may not be available. The no-conda path (`source bin/activate`) works
everywhere; anything involving `module load` needs a VM with current modules.

**`quota -u` is meaningless on tiCrypt** — it mounts encrypted volumes rather than using
NFS quotas, so it reports nothing useful. Use `df -h`. Don't assume shared project
storage is available for environments either; confirm what's mounted on the VM you're
actually using before planning around it.

## Related

- [`install_python`](https://github.com/aramp10/install_python) — the same
  download → transfer → offline-install pattern for pip packages, when you need a few
  packages rather than a whole environment.
- [`BU-tiCrypt`](https://github.com/katgit/BU-tiCrypt) — BU's tiCrypt onboarding
  documentation: registration, file transfer, and remote desktop access.

The numbers quoted above were measured on a BU SCC → tiCrypt transfer of a
`python=3.12 numpy` environment. The full verification log is kept internally by BU RCS;
ask if you need the detail behind a specific figure.
