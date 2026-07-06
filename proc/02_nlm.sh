#!/bin/bash
# performs NLM denoising

# list_file="/host/verges/tank/data/daniel/99_varia/MPN/MPN_29jun2026.txt"
# mp_dir=/host/verges/tank/data/BIDS_MPN/derivatives/micapipe_v0.2.0
# logdir=/host/verges/tank/data/daniel/99_varia/MPN/logs

# usage:
# bash 02_nlm.sh <list_file> <mp_dir> <logdir> [$test]

# setup environment
source /host/verges/tank/data/daniel/99_varia/MPN/processing/proc/setupEnv.sh
micapipe7t
echo $(which mincnlm)
echo $(which mri_convert)

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
echo "[INFO] list_file=$list_file"
echo "[INFO] mp_dir=$mp_dir"
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

    mp_sub_dir="${mp_dir}/${sub}/${ses}"
    logs="${logdir}/${sub}_${ses}"
    mkdir -p "$logs"

    id_prefix="${sub}_${ses}"

    T1w="${mp_sub_dir}/anat/${id_prefix}_space-nativepro_T1w.nii.gz"
    if [ ! -f "$T1w" ]; then
        echo "[ERROR] T1w nativepro file not found at expected path: $T1w"
        continue
    fi

    outdir="${mp_sub_dir}/anat"
    outStr="${id_prefix}_space-nativepro_T1w_nlm"
    nlm="${outdir}/${outStr}.nii.gz"

    log="${logs}/proc_nlm_$(date +%F_%H.%M.%S).txt"

    echo "[INFO] Running denoiseNLM on ${T1w}" | tee -a "$log"
    bash /data/mica1/01_programs/MICA-7t/functions/denoiseNLM \
        "$T1w" "$outStr" "$outdir" 2>&1 | tee -a "$log"

done < "$list_file"

echo "[INFO] Script finished."
