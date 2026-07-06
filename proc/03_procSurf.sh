#!/bin/bash
# qsub job: run micapipe -proc_surf using T1w_nlm

# uasge:
# bash 03_procSurf.sh <sub> <ses> [root] [out] [tmpDir] [micapipe_img] [fs_lic]

sub="${1:?missing sub}"
ses="${2:?missing ses}"
root="${3:-/host/verges/tank/data/BIDS_MPN}"
out="${4:-${root}/derivatives}"
tmpDir="${5:-/tmp}"
micapipe_img="${6:-/data_/mica1/01_programs/micapipe-v0.2.0/micapipe_v0.2.3.sif}"
fs_lic="${7:-/data_/mica1/01_programs/freesurfer-7.3.2/license.txt}"

sub="${sub#sub-}"
ses="${ses#ses-}"
id_prefix="sub-${sub}_ses-${ses}"
id_folders="sub-${sub}/ses-${ses}"

bids="${root}/rawdata"
mp_dir="${out}/micapipe_v0.2.0"
mp_sub_dir="${mp_dir}/${id_folders}"
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
echo "[INFO] mp_proc_csv=$mp_proc_csv"

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

surf_cmd=(
    singularity run --writable-tmpfs --containall
    -B "${bids}:/bids"
    -B "${out}:/out"
    -B "${tmpDir}:/tmp"
    -B "${fs_lic}:/opt/licence.txt"
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
