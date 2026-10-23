# Example: PoPS code and test data

Downloads the 2020 PoPS scripts and public test data (~7.6 GB) on BU SCC, then copies
them to tiCrypt. These are the exact inputs of the tested run; the md5 check confirms it.

## On BU SCC

Work in your `/projectnb` space, not your home directory (10 GB quota).

```bash
mkdir -p pops/code pops/data && cd pops

# scripts, pinned to the 2020 version
SHA=332cfc821c6fd26288d3262669df604672813695
G=https://raw.githubusercontent.com/FinucaneLab/pops
curl -fsSL -o code/pops.feature_selection.py $G/$SHA/pops.feature_selection.py
curl -fsSL -o code/pops.predict_scores.py    $G/$SHA/pops.predict_scores.py

# test data
cd data
curl -fsSLO $G/master/example/data/magma_scores/PASS_Schizophrenia.genes.out
curl -fsSLO $G/master/example/data/magma_scores/PASS_Schizophrenia.genes.raw
curl -fsSL -o control.features $G/master/example/data/utils/features_jul17_control.txt
curl -fsSL $G/master/example/data/utils/gene_annot_jun10.txt \
  | awk '{print $1"\t"$3"\t"$4"\t"$5}' > gene_loc.txt

# feature matrix, 7.5 GB
wget -O PoPS.features.txt.gz \
  "https://www.dropbox.com/scl/fo/ne7xhxkt4dwhvd52a59ub/AFKkJu7ACaun1uuE99kmTkc/data/PoPS.features.txt.gz?rlkey=ltdbcld1enyr1zefg1lfqm61i&dl=1"
cd ..

# check
curl -fsSLO https://raw.githubusercontent.com/aramp10/ticrypt_conda_env/main/examples/pops_data.md5
md5sum -c pops_data.md5
```

All 7 files must print `OK`.

## Disk space on tiCrypt

Paths on this page use `/drives/drive2/pops` as an example; use the drive and folder on
your own VM.

You need ~10 GB free on a drive attached to your VM. Check:

```bash
df -h /drives/drive2
```

If you have no drive, or too little space, add one: see tiCrypt's
[Create and Manage Drives](https://ticrypt.com/docs/user-guide/virtual-machines/create-and-manage-drives).

A new drive is owned by root; create your folder first:

```bash
sudo mkdir /drives/drive2/pops && sudo chown $USER: /drives/drive2/pops
```

## Copy to tiCrypt

Upload the whole `pops` folder to your drive (e.g. `/drives/drive2/pops`). See tiCrypt's
[Data Ingress and Egress](https://ticrypt.com/articles/data-ingress) guide
(see section for [Direct SFTP to VM](https://ticrypt.com/articles/data-ingress#direct-sftp-to-vm)).

## On tiCrypt

```bash
cd /drives/drive2/pops
md5sum -c pops_data.md5
```

All 7 files must print `OK`.
