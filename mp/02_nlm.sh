#!/bin/bash
# NLM denoise T1w image
# run locally on host with properly established minc utilities

# list_file="/host/verges/tank/data/daniel/99_varia/MPN/MPN_29jun2026.txt"
# mp_dir=/host/verges/tank/data/BIDS_MPN/derivatives/micapipe_v0.2.0
# logdir=/host/verges/tank/data/daniel/99_varia/MPN/logs

# usage:
# bash 02_nlm.sh $list_file $mp_dir $logdir [$test]

# environment
source /host/verges/tank/data/daniel/99_varia/MPN_proc/processing/mp/00_setupEnv.sh
micapipe7t

list_file=${1:-"/host/verges/tank/data/daniel/99_varia/MPN/MPN_29jun2026.txt"}
mp_dir=${2:-"/host/verges/tank/data/BIDS_MPN/derivatives/micapipe_v0.2.0"}
logdir=${3:-"/host/verges/tank/data/daniel/99_varia/MPN/logs"}
test=${4:-0}

echo "[INFO] Starting NLM denoising script."
echo
echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
echo "[INFO] user=$(whoami)"
echo "[INFO] logdir=$logdir"
echo "[INFO] mincnlm=$(which mincnlm)"
echo "[INFO] mri_convert=$(which mri_convert)"
echo "[INFO] list_file=$list_file"
echo "[INFO] mp_dir=$mp_dir"
echo "[INFO] test=$test"
echo 

# iterate through list
if [ "$test" -eq 1 ]; then
    # choose random line in list_file
    line=$(shuf -n 1 "$list_file")
    echo "[TEST] Randomly selected line: $line"
    echo "$line" > /tmp/test_list.txt
    list_file_orig="$list_file"
    list_file="/tmp/test_list.txt"
fi

while IFS=, read -r sub ses; do
    [ -n "$sub" ] || continue

    echo "==============================================================="
    echo "[STEP] MINC NLM denoising for ${id_prefix}"
    echo "[INFO] date=$(date)"
    echo "[INFO] hostname=$(hostname)"
    echo "[INFO] user=$(whoami)"
    echo "[INFO] sub=$sub ses=$ses"

    clean_sub="${sub#sub-}"
    clean_ses="${ses#ses-}"

    mp_sub_dir="${mp_dir}/sub-${sub}/ses-${ses}"
    logs="${logdir}/sub-${sub}_ses-${ses}"
    mkdir -p "$logs"

    id_prefix="sub-${sub}_ses-${ses}"

    T1w="${mp_sub_dir}/anat/${id_prefix}_space-nativepro_T1w.nii.gz"
    if [ ! -f "$T1w" ]; then
        echo "[ERROR] T1w nativepro file not found at expected path: $T1w"
        continue
    fi

    outdir="${mp_sub_dir}/anat"
    outStr="${id_prefix}_space-nativepro_T1w_nlm"
    nlm="${outdir}/${outStr}.nii.gz"

    if [ -f "$nlm" ]; then
        echo "[SKIP] NLM output already exists → $nlm"
        continue
    fi

    log="${logs}/proc_nlm_$(date +%F_%H.%M.%S).txt"

    echo "[INFO] Running denoiseNLM on ${T1w}" | tee -a "$log"
    bash /data/mica1/01_programs/MICA-7t/functions/denoiseNLM \
        "$T1w" "$outStr" "$outdir" 2>&1 | tee -a "$log"

done < "$list_file"

echo "[DONE] NLM denoise script finished."
