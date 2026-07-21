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
# bash 01_procStruc.sh "$sub" "$ses" "$root" "$T1wStr"
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
# Do not reprocess is module already completed
echo "[INFO] ${id_prefix} @ ${mp_string} not COMPLETE. Proceeding with procStructural processing."

uni_flag=()

have_match() {
    compgen -G "$1" > /dev/null
}

# MP2RAGE 0.5 mm
if have_match "${anat_dir}/${id_prefix}_acq-05mm_UNIT1.nii*" &&
    have_match "${anat_dir}/${id_prefix}_acq-05mm_inv-1_MP2RAGE.nii*" &&
    have_match "${anat_dir}/${id_prefix}_acq-05mm_inv-2_MP2RAGE.nii*"; then

    T1wStr="acq-05mm_UNIT1,acq-05mm_inv-1_MP2RAGE,acq-05mm_inv-2_MP2RAGE"
    uni_flag=(-uni)
    t1_mode="MP2RAGE_05mm"
# multiple runs of 0.5mm: use run-2
elif have_match "${anat_dir}/${id_prefix}_acq-05mm_run-2_UNIT1.nii*" &&
    have_match "${anat_dir}/${id_prefix}_acq-05mm_inv-1_run-2_MP2RAGE.nii*" &&
    have_match "${anat_dir}/${id_prefix}_acq-05mm_inv-2_run-2_MP2RAGE.nii*"; then

    T1wStr="acq-05mm_run-2_UNIT1,acq-05mm_inv-1_run-2_MP2RAGE,acq-05mm_inv-2_run-2_MP2RAGE"
    uni_flag=(-uni)
    t1_mode="MP2RAGE_05mm"
else
    echo "[WARNING] No 05mm MP2RAGE. Not processing." >&2
    exit 1
fi

# MP2RAGE 0.7 mm
#elif have_match "${anat_dir}/${id_prefix}_UNIT1.nii*" &&
#      have_match "${anat_dir}/${id_prefix}_inv-1_MP2RAGE.nii*" &&
#      have_match "${anat_dir}/${id_prefix}_inv-2_MP2RAGE.nii*"; then

#    T1wStr="UNIT1,inv-1_MP2RAGE,inv-2_MP2RAGE"
#    uni_flag=(-uni)
#    t1_mode="MP2RAGE_07mm"

# MPRAGE
#elif have_match "${anat_dir}/${id_prefix}_T1w.nii*"; then

#    T1wStr="T1w"
#    uni_flag=()
#    t1_mode="MPRAGE"

#else
#    echo "[ERROR] No supported anatomical input (.nii/.nii.gz) found in ${anat_dir}" >&2
#    exit 1
#fi

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
