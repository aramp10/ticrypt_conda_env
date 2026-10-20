# Example: run PoPS on tiCrypt

Runs the PoPS test as a SLURM job, using the environment from [pops.md](pops.md) and the
data from [pops_data.md](pops_data.md). Heavy work runs on a compute node created for the
job (8 CPUs, 64 GB), not on your VM.

## On BU SCC

Download the job script [pops.sbatch](pops.sbatch):

```bash
curl -fsSLO https://raw.githubusercontent.com/aramp10/ticrypt_conda_env/main/examples/pops.sbatch
```

Check the `# EDIT:` lines near the top (data folder and environment path) and change them
if yours differ.

## Copy to tiCrypt

Upload `pops.sbatch` to `/drives/drive2/pops`, the same way as the data.

## On tiCrypt

```bash
cd /drives/drive2/pops
sbatch pops.sbatch
squeue -u $USER
```

If `sbatch` reports `Unspecified error`, submit again.

The job may show `PENDING (ReqNodeNotAvail)` for 1–2 minutes while its node starts.
It then runs for about 2 hours (step 2 ~75 min, step 3 ~45 min).

## Done when

`pops_<jobid>.log` ends with `== done` followed by the three output files in
`/drives/drive2/pops/run`:

```
PASS_Schizophrenia.features
PASS_Schizophrenia.1.results
PASS_Schizophrenia.1.coefs
```

A `FutureWarning` from pandas and `SingularMatrixWarning`s in the log are expected.
