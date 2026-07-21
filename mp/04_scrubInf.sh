#!/bin/bash
# Adapted from Cabalo et al, MICA MNI, https://github.com/donnagift/fast_scrubber
# MICA MNI
#
# DO NOT ITERATE THROUGH SUBJECTS!
# INFERENCE WILL OCCUR ON ALL SUBJECTS IN THE INPUT DIRECTORY
# works on bb-compx-04 (has GPU and access to percy/local_raid)


# USAGE:
# bash 04_ScrubberInference.sh <>
# run on host with GPU resources

set -e

source /host/verges/tank/data/daniel/99_varia/MPN_proc/processing/mp/00_setupEnv.sh
micapipe7t
04_fastscrubber
# Vars from 00_setupEnv.sh
# nnUNet_raw
# nnUNet_preprocessed
# nnUNet_results
# dir_imgTs
# dir_inf


echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
echo "[INFO] user=$(whoami)"
echo "[INFO] Running with the following directories:"
echo "[INFO] bids=$bids_dir"
echo "[INFO] fastsurfer=$dir_fs"
echo "[INFO] nnUNet_raw=$nnUNet_raw"
echo "[INFO] nnUNet_preprocessed=$nnUNet_preprocessed"
echo "[INFO] nnUNet_results=$nnUNet_results"
echo "[INFO] [fastscrubber input dir] dir_imgTs=$dir_imgTs"
echo "[INFO] [fastscrubber output dir] dir_inf=$dir_inf"

echo "[STEP] fastscrubber inference"

nnUNetv2_predict \
-i "${dir_imgTs}" \
-o "${dir_inf}" \
-d 500 \
-c 3d_fullres \
--save_probabilities

echo "[DONE] fastscrubber inference completed"
