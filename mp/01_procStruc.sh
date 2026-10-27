#!/bin/bash

# ==============================================================
# Process a participant up until anatomical segmentation.
# This script prepares for fastscrubber segmentation.
# Scripts adapted from https://github.com/MICA-MNI/MICA-7t
#
# Daniel Mendelson, 2024-06-05
# MICA Lab, MNI, McGill University
#
# usage:
# bash 01_procStruc.sh "$sub" "$ses" "$root" "0.5"
# bash 01_procStruc.sh "$sub" "$ses" "$root" "0.7"
#
# root: directory to BIDS folder
# ==============================================================
set -e
sub="${1:?missing sub}"
ses="${2:?missing ses}"

# remove sub- and ses- prefixes if present
sub="${sub#sub-}"
ses="${ses#ses-}"
id_prefix="sub-${sub}_ses-${ses}"
id_folders="sub-${sub}/ses-${ses}"

root="${3:-/host/verges/tank/data/BIDS_MPN}"
t1_resolution="${4:?missing T1 resolution: choose 0.5 or 0.7}"

# ---- MP2RAGE file conventions: edit here ----
# Exclude "${id_prefix}_" and ".nii"/".nii.gz".

# MP2RAGE 0.5 mm
t1_05_uni="acq-05mm_UNIT1"
t1_05_inv1="acq-05mm_inv-1_MP2RAGE"
t1_05_inv2="acq-05mm_inv-2_MP2RAGE"

# MP2RAGE 0.5 mm, run-2
t1_05_run2_uni="acq-05mm_run-2_UNIT1"
t1_05_run2_inv1="acq-05mm_inv-1_run-2_MP2RAGE"
t1_05_run2_inv2="acq-05mm_inv-2_run-2_MP2RAGE"

# MP2RAGE 0.7 mm
t1_07_uni="UNIT1"
t1_07_inv1="inv-1_MP2RAGE"
t1_07_inv2="inv-2_MP2RAGE"

bids="${root}/rawdata"
out="${root}/derivatives"
mp_sub_dir="${out}/micapipe_v0.2.0/${id_folders}"

anat_dir="${bids}/sub-${sub}/ses-${ses}/anat"

threads=${threads:-6}

version=v0.2.3
micapipe_img=/data_/mica1/01_programs/micapipe-v0.2.0/micapipe_${version}.sif

fs_lic=${fs_lic:-"/data_/mica1/01_programs/freesurfer-7.3.2/license.txt"}
tmpDir=${tmpDir:-"/tmp"}

mp_proc_csv=/host/verges/tank/data/BIDS_MPN/derivatives/micapipe_v0.2.0/micapipe_processed_sub.csv
mp_string="proc_structural"

echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
echo "[INFO] user=$(whoami)"
echo "[INFO] sub=$sub ses=$ses"
echo "[INFO] root=$root"
echo "[INFO] bids=$bids"
echo "[INFO] out=$out"
echo "[INFO] threads=$threads"
echo "[INFO] tmpDir=$tmpDir"
echo "[INFO] micapipe_img=$micapipe_img"
echo "[INFO] mp_proc_csv=$mp_proc_csv"

echo
echo "[STEP] MICAPIPE: proc_structural"

# TODO. Do not reprocess if is module already completed
echo "[INFO] ${id_prefix} @ ${mp_string} NOT COMPLETE. Proceeding with proc_structural processing."

uni_flag=()

have_match() {
    compgen -G "$1" > /dev/null
}

# Identify appropriate T1w image triplets
# currently supports 0.5 and 0.7mm resolution MP2RAGE images (UNI, inv1, inv2)
# If multiple runs, uses run 2
have_05=false
if have_match "${anat_dir}/${id_prefix}_${t1_05_uni}.nii*" &&
   have_match "${anat_dir}/${id_prefix}_${t1_05_inv1}.nii*" &&
   have_match "${anat_dir}/${id_prefix}_${t1_05_inv2}.nii*"; then
    have_05=true
fi

have_05_run2=false
if have_match "${anat_dir}/${id_prefix}_${t1_05_run2_uni}.nii*" &&
   have_match "${anat_dir}/${id_prefix}_${t1_05_run2_inv1}.nii*" &&
   have_match "${anat_dir}/${id_prefix}_${t1_05_run2_inv2}.nii*"; then
    have_05_run2=true
fi

if [[ "${t1_resolution}" == "0.5" ]]; then

    # MP2RAGE 0.5 mm
    if [[ "${have_05}" == true ]]; then
        T1wStr="${t1_05_uni},${t1_05_inv1},${t1_05_inv2}"
        uni_flag=(-uni)
        t1_mode="MP2RAGE_05mm"

    # multiple runs of 0.5mm: use run-2
    elif [[ "${have_05_run2}" == true ]]; then
        T1wStr="${t1_05_run2_uni},${t1_05_run2_inv1},${t1_05_run2_inv2}"
        uni_flag=(-uni)
        t1_mode="MP2RAGE_05mm"
    else
        echo "[WARNING] No 0.5mm MP2RAGE. Not processing." >&2
        exit 1
    fi

elif [[ "${t1_resolution}" == "0.7" ]]; then

    # Skip this session if 0.5-mm inputs exist, to protect shared outputs.
    if [[ "${have_05}" == true || "${have_05_run2}" == true ]]; then
        echo "[SKIP] ${id_prefix}: 0.7 mm requested, but 0.5-mm inputs exist. Skipping to avoid overwriting outputs."
        exit 0
    fi

    # MP2RAGE 0.7 mm
    if have_match "${anat_dir}/${id_prefix}_${t1_07_uni}.nii*" &&
       have_match "${anat_dir}/${id_prefix}_${t1_07_inv1}.nii*" &&
       have_match "${anat_dir}/${id_prefix}_${t1_07_inv2}.nii*"; then

        T1wStr="${t1_07_uni},${t1_07_inv1},${t1_07_inv2}"
        uni_flag=(-uni)
        t1_mode="MP2RAGE_07mm"
    else
        echo "[WARNING] No 0.7mm MP2RAGE. Not processing." >&2
        exit 1
    fi

else
    echo "[ERROR] Invalid T1 resolution '${t1_resolution}': choose 0.5 or 0.7." >&2
    exit 1
fi

echo "[INFO] t1_mode=$t1_mode"
echo "[INFO] T1wStr=$T1wStr"

singularity_cmd=(
    singularity run --writable-tmpfs --containall
    -B "${bids}:/bids"
    -B "${out}:/out"
    -B "${tmpDir}:/tmp"
    -B "${fs_lic}:/opt/licence.txt"
    "${micapipe_img}"
    -bids /bids
    -out /out
    -fs_licence /opt/licence.txt
    -threads "${threads}"
    -sub "${sub}"
    -ses "${ses}"
    -proc_structural
    "${uni_flag[@]}"
    -T1wStr "${T1wStr}"
)

echo "[INFO] Running command:" "${singularity_cmd[@]}"
"${singularity_cmd[@]}"
echo "[DONE] Finished proc_structural script " "$(date)"
