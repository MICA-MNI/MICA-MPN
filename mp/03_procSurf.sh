#!/bin/bash
# Compute original surface segmentation
# NOTE. Requires T1w_nlm to exist (produced by 02_nlm.sh)

# uasge:
# bash 03_procSurf.sh <sub> <ses> [root:/host/verges/tank/data/BIDS_MPN] [out:/host/verges/tank/data/BIDS_MPN/derivatives] [tmpDir:/tmp]

source /host/verges/tank/data/daniel/99_varia/MPN_proc/processing/mp/00_setupEnv.sh
micapipe7t
04_fastscrubber

# variables from env file:
# micapipe_img
# mp_v_string
# fs_licence

sub="${1:?missing sub}"
ses="${2:?missing ses}"
root="${3:-/host/verges/tank/data/BIDS_MPN}"
out="${4:-${root}/derivatives}"
tmpDir="${5:-/tmp}"

sub="${sub#sub-}"
ses="${ses#ses-}"
id_prefix="sub-${sub}_ses-${ses}"
id_folders="sub-${sub}/ses-${ses}"

bids="${root}/rawdata"
mp_dir="${out}/micapipe_${mp_v_string}"
mp_sub_dir="${mp_dir}/${id_folders}"
dir_fs="${out}/fastsurfer"
fs_sub_dir="${dir_fs}/${id_prefix}"
threads="${threads:-6}"

anat_dir="${mp_sub_dir}/anat"
t1w="${anat_dir}/${id_prefix}_space-nativepro_T1w.nii.gz"
t1nlm="${anat_dir}/${id_prefix}_space-nativepro_T1w_nlm.nii.gz"

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
echo "[INFO] fs_license=$fs_licence"
echo "[INFO] fastsurfer=$dir_fs"
echo "[INFO] [fastscrubber input dir] dir_imgTs=$dir_imgTs"

# --- mp : p r o c _ s u r f ---
echo "[STEP] proc_surf for ${id_prefix}"
# wait up to 90 min for NLM if T1w exists
max_wait_sec=$((90 * 60))
sleep_sec=$((10 * 60))
waited_sec=0

if [ -f "$t1nlm" ]; then
    echo "[INFO] Found NLM file: $t1nlm"
elif [ -f "$t1w" ]; then
    echo "[INFO] T1w exists but NLM does not. Waiting for NLM to appear..."
    while [ ! -f "$t1nlm" ] && [ "$waited_sec" -lt "$max_wait_sec" ]; do
        echo "[INFO] Waiting 10 min... elapsed=$((waited_sec / 60)) min"
        sleep "$sleep_sec"
        waited_sec=$((waited_sec + sleep_sec))
    done
else
    echo "[ERROR] Neither T1w nor T1w_nlm found:"
    echo "        T1w:   $t1w"
    echo "        T1nlm: $t1nlm"
    exit 1
fi

if [ ! -f "$t1nlm" ]; then
    echo "[ERROR] Timed out after 90 min waiting for NLM file: $t1nlm"
    exit 1
fi

# if fastsurfer file does not exist, then run micapipe cleanup to ensure the case properly runs
if [ ! -d "$fs_sub_dir" ]; then
    echo "[INFO] fastsurfer output directory does not exist. Running micapipe_cleanup to ensure clean state before calling micapipe."
    clean_cmd=(
        singularity run --writable-tmpfs --containall
        -B "${bids}:/bids"
        -B "${out}:/out"
        -B "${tmpDir}:/tmp"
        -B "${fs_licence}:/opt/licence.txt"
        "${micapipe_img}"
        -cleanup
        -sub "${sub}"
        -out /out
        -fs_licence /opt/licence.txt
        -bids /bids
        -ses "${ses}"
        -proc_surf
    )
    echo "[INFO] Running cleanup command:" "${clean_cmd[@]}"
    "${clean_cmd[@]}"
fi

surf_cmd=(
    singularity run --writable-tmpfs --containall
    -B "${bids}:/bids"
    -B "${out}:/out"
    -B "${tmpDir}:/tmp"
    -B "${fs_licence}:/opt/licence.txt"
    -B "${t1nlm}:/opt/T1.nii.gz"
    "${micapipe_img}"
    -bids /bids
    -out /out
    -fs_licence /opt/licence.txt
    -threads "${threads}"
    -sub "${sub}"
    -ses "${ses}"
    -proc_surf
    -T1 /opt/T1.nii.gz
)

echo "[INFO] Running command:" "${surf_cmd[@]}"
"${surf_cmd[@]}"

echo "[DONE] Finished proc_surf script " "$(date)"

# --- .m g z -> .n i i  for fastscrubber input---
# NOTE. fastscrubber will run inference on all images in its input directory.
# Adapted from Cabalo et al, MICA MNI, https://github.com/donnagift/fast_scrubber

echo "[STEP] Converting mgz->nii for fastscrubber input"

04_inputNaming "$dir_fs" "$dir_imgTs" "$sub" "$ses"
echo "[INFO] input=$input_mgz"
echo "[INFO] output=$input_nii"

if [ -f "${dir_fs}/sub-${sub}_ses-${ses}/qc_done.txt" ]; then
    echo "[SKIP] fastscrubber already run for $sub $ses"
    
    # remove nii volume from fastscrubber input it is present
    if [ -f "$input_nii" ]; then
        rm "$input_nii"
        echo "[INFO] Removed fastscrubber input file $input_nii"
    fi
elif [ -f "$input_nii" ]; then
    echo "[SKIP] Converted output already exists: $input_nii"
elif [ -f "$input_mgz" ]; then

    mri_convert "$input_mgz" "$input_nii"

    if [ -f "$input_nii" ]; then
        echo "[DONE] Saved: $input_nii"
    else
        echo "[ERROR] Failed to save $input_nii"
    fi
else
    echo "[ERROR] $input_mgz not found for $sub $ses"
fi
echo "[DONE] Finished procSurf script " "$(date)"
