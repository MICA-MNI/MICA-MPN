#!/bin/bash
set -e

# E N V  setup
source /host/verges/tank/data/daniel/99_varia/MPN_proc/processing/mp/00_setupEnv.sh
micapipe7t
04_fastscrubber
# Vars required from 00_setupEnv.sh
# dir_imgTs
# dir_inf
# fastsurfer_img
# micapipe_img
# fs_licence

sub=${1:?missing sub}
ses=${2:?missing ses}
sub="${sub#sub-}"
ses="${ses#ses-}"

bids_dir=${3:-/host/verges/tank/data/BIDS_MPN}
bids=$bids_dir/rawdata
out=$bids_dir/derivatives

dir_fs="${out}/fastsurfer"
threads=${threads:-15}
tmpDir=${tmpDir:-"/tmp"}

echo
echo "[INFO] date=$(date)"
echo "[INFO] user=$(whoami)"
echo "[INFO] sub=$sub ses=$ses"
echo "[INFO] Running with the following directories:"
echo "[INFO] bids=$bids_dir"
echo "[INFO] threads=$threads"
echo "[INFO] fastsurfer=$dir_fs"
echo "[INFO] [fastscrubber input dir] dir_imgTs=$dir_imgTs"
echo "[INFO] [fastscrubber output masks dir] dir_inf=$dir_inf"

echo "[INFO] fastsurfer_img=$fastsurfer_img"
echo "[INFO] micapipe_img=$micapipe_img"
echo "[INFO] fs_licence=$fs_licence"

# ---- a p p l y   f a s t s c r u b b e r   m a s k s ----
echo "[STEP] Applying fastscrubber corrected masks"

# check qc_done.txt
# if exists, then can skip this processing


conda activate base
fs_cmd=(bash /host/verges/tank/data/fast_scrubber/run_fastscrubber_qsub.sh \
  "sub-${sub}" "ses-${ses}" "${dir_fs}" "${dir_inf}")

fastscrubber_LOGS=/host/verges/tank/data/fast_scrubber/tmp_logs/sub-${sub}_ses-${ses}
echo "[INFO] Running command:" "${fs_cmd[@]}"
echo "[NOTE] qsub logs will be directed to the following files: "
echo "[NOTE] stdout: ${fastscrubber_LOGS}.o"
echo "[NOTE] stderr: ${fastscrubber_LOGS}.e"

"${fs_cmd[@]}"

echo "[INFO] run_fastscrubber_qsub run."
/host/verges/tank/data/fast_scrubber/applyCNNmask.sh