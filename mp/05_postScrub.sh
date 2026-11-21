#!/bin/bash
set -e

# NOTE: most reliable when running locally

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

shift 2

bids_dir="/host/verges/tank/data/BIDS_MPN"
run=""

# Optional arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -run|--run)
            run="${2:?missing value for -run}"
            run="${run#run-}"
            shift 2
            ;;
        -bids|--bids)
            bids_dir="${2:?missing value for -bids}"
            shift 2
            ;;
        *)
            # Allow bids_dir as an optional positional argument
            if [[ "$1" != -* && "$bids_dir" == "/host/verges/tank/data/BIDS_MPN" ]]; then
                bids_dir="$1"
                shift
            else
                echo "[ERROR] Unknown argument: $1"
                exit 1
            fi
            ;;
    esac
done

bids=$bids_dir/rawdata
out=$bids_dir/derivatives

# Run configuration
run_suffix=""
run_flag=()

if [[ -n "$run" ]]; then
    run_suffix="_run-${run}"
    run_flag=(-run "$run")
fi

dir_fs="${out}/fastsurfer"
threads=${threads:-10}
tmpDir=${tmpDir:-"/tmp"}

echo
echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
echo "[INFO] user=$(whoami)"
echo "[INFO] sub=$sub ses=$ses"
echo "[INFO] Running with the following directories:"
echo "[INFO] bids=$bids_dir"
echo "[INFO] threads=$threads"
echo "[INFO] fastsurfer=$dir_fs"
echo "[INFO] [fastscrubber input dir] dir_imgTs=$dir_imgTs"

echo "[INFO] fastsurfer_img=$fastsurfer_img"
echo "[INFO] micapipe_img=$micapipe_img"
echo "[INFO] fs_licence=$fs_licence"

# --- c l e a n u p   f a s t s c r u b b e r   i n p u t ---
echo "[STEP] cleaning fastscrubber input ${sub}-${ses}"
04_inputNaming "$dir_fs" "$dir_imgTs" "$sub" "$ses"
echo "[INFO] Removing nii input fastscrubber file $input_nii"

if [ -f "$input_nii" ]; then
  rm "$input_nii"
  echo "[DONE] Cleaned fastscrubber input file"
else
  echo "[SKIP] File not found at provided path, not removing."
fi

# --- p o s t    s t r u c t u r a l ---
echo "[STEP] micapipe:post_structural, MPC, proc_flair,  ${sub}-${ses}"

t1map_path="${bids}/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_acq-05mm${run_suffix}_T1map.nii.gz"

echo "[INFO] t1map_path=$t1map_path"


post_struct_cmd=(
    singularity run --writable-tmpfs --containall
    -B "${bids}:/bids"
    -B "${out}:/out"
    -B "${tmpDir}:/tmp"
    -B "${fs_licence}:/opt/licence.txt"
    "${micapipe_img}"
    -bids /bids
    -out /out
    -fs_licence /opt/licence.txt
    -threads "${threads}"
    -sub "${sub}"
    -ses "${ses}"
    "${run_flag[@]}"
    -post_structural
    -MPC -mpc_acq T1map -regSynth
    -microstructural_img "/bids/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_acq-05mm${run_suffix}_T1map.nii.gz"
    -microstructural_reg FALSE
    -proc_flair
)

echo "[INFO] Running command:" "${post_struct_cmd[@]}"
"${post_struct_cmd[@]}"
echo "[DONE] micapipe:post_structural."

echo "[INFO] Post-scrubber script complete $(date)"
