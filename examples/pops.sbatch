#!/bin/bash
#SBATCH --job-name=pops
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=pops_%j.log
set -e

# EDIT: folder with code/ and data/ (from pops_data.md)
P=/drives/drive2/pops
# EDIT: conda environment (from pops.md)
ENV=$HOME/conda/envs/pops

source $ENV/bin/activate
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK NUMEXPR_NUM_THREADS=$SLURM_CPUS_PER_TASK
D=$P/data
C=$P/code
mkdir -p $P/run && cd $P/run
echo "== step 2 $(date)"
python $C/pops.feature_selection.py --features $D/PoPS.features.txt.gz --gene_results $D/PASS_Schizophrenia --out PASS_Schizophrenia
echo "== step 3 $(date)"
python $C/pops.predict_scores.py --gene_loc $D/gene_loc.txt --gene_results $D/PASS_Schizophrenia --features $D/PoPS.features.txt.gz --selected_features PASS_Schizophrenia.features --control_features $D/control.features --chromosome 1 --out PASS_Schizophrenia
echo "== done $(date)"
ls -l PASS_Schizophrenia.features PASS_Schizophrenia.1.results PASS_Schizophrenia.1.coefs
