#!/bin/bash


# usage: call for each subject of interest
# NOTE. requires existence of micapipe T1w (results from mp 01_procStruc.sh)
# bash 01_hippunfold_pt.sh <sub> <ses> [bids_dir] [hu_img] [threads] [out_density]

export SINGULARITY_BINDPATH="/host/verges/tank/data:/host/verges/tank/data"

sub=${1:?missing sub}
sub="${sub#sub-}"
bids_dir=${3:-/host/verges/tank/data/BIDS_MPN}
hu_img=${hu_img:-/data/mica1/01_programs/singularity/hippunfold_v1.5.1.sif}
modality=T1w

out_density=${out_density:-0p5mm}

out_dir=${bids_dir}/derivatives/hippunfold_v1.5.1

echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
echo "[INFO] user=$(whoami)"
echo "[INFO] sub=$sub"
echo "[INFO] hu_img=$hu_img"
echo "[INFO] bids_dir=$bids_dir"
echo "[INFO] out_dir=$out_dir"

echo "[STEP] Running hippunfold for ${sub}"
hu_cmd=(
  singularity run -e "${hu_img}" \
  "${bids_dir}" "${out_dir}" participant \
  --participant_label ${sub} \
  -p --cores all \
  --modality "T1w" \
  --path-T1w "${bids_dir}/derivatives/micapipe_v0.2.0/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_space-nativepro_T1w.nii.gz" \
  --output-density "0p5mm" \
  --rerun-incomplete
)
echo "[INFO] Running command: ${hu_cmd[@]}"
"${hu_cmd[@]}"
echo "[DONE] hippunfold completed for ${sub}"
