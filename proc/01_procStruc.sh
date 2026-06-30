#!/usr/bin/bash

# ==============================================================
# Process a participant up until anatomical segmentation.
# This script prepares for fastscrubber segmentation.
# Scripts adapted from https://github.com/MICA-MNI/MICA-7t
#
# Daniel Mendelson, 2024-06-05
# MICA Lab, MNI, McGill University
#
# usage:
# bash 00_PreScrubber.sh "$sub" "$ses" "$root" "$T1wStr" "$micapipe_img"
# ==============================================================

sub="${1:?missing sub}"
ses="${2:?missing ses}"
root="${3:-/host/verges/tank/data/BIDS_MPN}"

bids="${root}/rawdata"
out="${root}/derivatives"

anat_dir="${bids}/sub-${sub}/ses-${ses}/anat"
idBIDS="sub-${sub}_ses-${ses}"

threads=${threads:-6}

version=v0.2.3
micapipe_img=/data_/mica1/01_programs/micapipe-v0.2.0/micapipe_${version}.sif

fs_lic=${fs_lic:-"/data_/mica1/01_programs/freesurfer-7.3.2/license.txt"}
tmpDir=${tmpDir:-"/tmp"}

singularity_command="singularity run --writable-tmpfs --containall -B ${bids}:/bids -B ${out}:/out -B ${tmpDir}:/tmp -B ${fs_lic}:/opt/licence.txt ${micapipe_img}"

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
echo "[INFO] singularity_command=$singularity_command"

uni_flag=()

have_match() {
    compgen -G "$1" > /dev/null
}

# MP2RAGE 0.5 mm
if have_match "${anat_dir}/${idBIDS}_acq-05mm_UNIT1.nii*" &&
   have_match "${anat_dir}/${idBIDS}_acq-05mm_inv-1_MP2RAGE.nii*" &&
   have_match "${anat_dir}/${idBIDS}_acq-05mm_inv-2_MP2RAGE.nii*"; then

    T1wStr="acq-05mm_UNIT1,acq-05mm_inv-1_MP2RAGE,acq-05mm_inv-2_MP2RAGE"
    uni_flag=(-uni)
    t1_mode="MP2RAGE_05mm"
# multiple runs of 0.5mm: use run-2
elif have_match "${anat_dir}/${idBIDS}_acq-05mm_run-2_UNIT1.nii*" &&
     have_match "${anat_dir}/${idBIDS}_acq-05mm_inv-1_run-2_MP2RAGE.nii*" &&
     have_match "${anat_dir}/${idBIDS}_acq-05mm_inv-2_run-2_MP2RAGE.nii*"; then

    T1wStr="acq-05mm_run-2_UNIT1,acq-05mm_run-2_inv-1_MP2RAGE,acq-05mm_run-2_inv-2_MP2RAGE"
    uni_flag=(-uni)
    t1_mode="MP2RAGE_05mm"
else
    echo "[WARNING] No 05mm MP2RAGE. Not processing." >&2
    exit 1
fi
:'
# MP2RAGE 0.7 mm
elif have_match "${anat_dir}/${idBIDS}_UNIT1.nii*" &&
      have_match "${anat_dir}/${idBIDS}_inv-1_MP2RAGE.nii*" &&
      have_match "${anat_dir}/${idBIDS}_inv-2_MP2RAGE.nii*"; then

    T1wStr="UNIT1,inv-1_MP2RAGE,inv-2_MP2RAGE"
    uni_flag=(-uni)
    t1_mode="MP2RAGE_07mm"

# MPRAGE
elif have_match "${anat_dir}/${idBIDS}_T1w.nii*"; then

    T1wStr="T1w"
    uni_flag=()
    t1_mode="MPRAGE"

else
    echo "[ERROR] No supported anatomical input (.nii/.nii.gz) found in ${anat_dir}" >&2
    exit 1
fi
'

echo "[INFO] t1_mode=$t1_mode"
echo "[INFO] T1wStr=$T1wStr"

${singularity_command} \
    -bids /bids -out /out -fs_licence /opt/licence.txt -threads ${threads} -sub ${sub} -ses ${ses} \
    -proc_structural ${uni_flag[@]} -T1wStr ${T1wStr}