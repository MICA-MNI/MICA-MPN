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
# bash 00_PreScrubber.sh "$sub" "$ses" "$root" "$T1wStr" "$micapipe_img"
# ==============================================================

sub="$1"
ses="$2"
root="$3"
T1wStr="$4"
micapipe_img="$5"

tmp="${JOB_TMPDIR:-${TMPDIR:-/tmp}}"
threads="${THREADS:-${NSLOTS:-1}}"

# Preamble
bids=$root/rawdata
out=$root/derivatives
fs_lic=/data_/mica1/01_programs/freesurfer-7.3.2/license.txt

# CLEAN SUB, SES
if [[ "$sub" == sub-* ]]; then
    sub="${sub#sub-}"
fi

if [[ "$ses" == ses-* ]]; then
    ses="${ses#ses-}"
fi

echo "Host           : $(hostname)"
echo "Subject        : sub-${sub}"
echo "Session        : ses-${ses}"
echo "TMPDIR         : ${tmp}"
echo "Threads        : ${threads}"
echo "Micapipe image : ${micapipe_img}"

## MP version
mp_version_line="$(singularity exec "$micapipe_img" micapipe -v)"
echo "$mp_version_line"
MICAPIPE_VER="$(printf '%s\n' "$mp_version_line" | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*')"
echo 
mp_dir="${out}/micapipe_${MICAPIPE_VER}"

# Struc proc
singularity run --writable-tmpfs --containall \
	-B ${bids}:/bids \
	-B ${out}:/out \
	-B ${tmp}:/tmp \
	-B ${fs_lic}:/opt/licence.txt \
	${micapipe_img} \
	-bids /bids -out /out -fs_licence /opt/licence.txt -threads ${threads} -sub ${sub} -ses ${ses} \
	-proc_structural -uni -T1wStr ${T1wStr}

# NLM Denoise
cd ${mp_dir}

id1=sub-${sub}/ses-${ses}
id=sub-${sub}_ses-${ses}

T1w_nii=${id1}/anat/${id/\//_}_space-nativepro_T1w.nii.gz
NLMoutdir=${id1}/anat
NLMoutStr=${id/\//_}_space-nativepro_T1w_nlm
bash /host/yeatman/local_raid/rcruces/git_here/MRI_analytic_tools/Freesurfer_preprocessing/denoiseN4 ${T1w_nii} ${NLMoutStr} ${NLMoutdir} ${threads}
NLM_path=${mp_dir}/${NLMoutdir}/${NLMoutStr}.nii.gz

# Surf proc
singularity run --writable-tmpfs --containall \
	-B ${bids}:/bids \
	-B ${out}:/out \
	-B ${tmp}:/tmp \
	-B ${fs_lic}:/opt/licence.txt \
    -B ${NLM_path}:/opt/T1.nii.gz \
	${micapipe_img} \
	-bids /bids -out /out -fs_licence /opt/licence.txt -threads ${threads} -sub ${sub} -ses ${ses} \
	-proc_surf -fastsurfer -T1 /opt/T1.nii.gz

