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

dir_fs="${bids_dir}/derivatives/fastsurfer"
threads=${threads:-15}
tmpDir=${tmpDir:-"/tmp"}

echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
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
fs_cmd=(/host/verges/tank/data/fast_scrubber/run_fastscrubber_qsub.sh \
  "sub-${sub}" "ses-${ses}" "${dir_fs}" "${dir_inf}")
echo "[INFO] Running command:" "${fs_cmd[@]}"
$("${fs_cmd[@]}")
echo "[DONE] fastscrubber masks applied."

# --- s u r f   r e c o n ----
echo "[STEP] Reconstructing surfaces from fastscrubber corrections ${sub}-${ses}"

unset TMPDIR
# previously caused errors when set
recon_cmd=(
    singularity exec --nv -B "${dir_fs}/sub-${sub}_ses-${ses}:/data" \
                      -B "${dir_fs}":/output \
                      -B "${fs_licence}":/fs \
                       ${fastsurfer_img} \
                       /fastsurfer/recon_surf/recon-surf.sh \
                      --fs_license /fs/license.txt \
                      --t1 /data/mri/orig.mgz \
                      --sid sub-${sub}_ses-${ses} --sd /output --no_fs_T1 \
                      --parallel --threads ${threads}
)
echo "[INFO] Running command:" "${recon_cmd[@]}"
"${recon_cmd[@]}"
echo "[DONE] Recon completed."

echo "[STEP] Creating qc_done.txt"
touch ${dir_fs}/sub-${sub}_ses-${ses}/qc_done.txt

chmod aug+wr -R ${dir_fs}/sub-${sub}_ses-${ses}

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
echo "[STEP] micapipe:post_structural ${sub}-${ses}"

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
    -post_structural
)

echo "[INFO] Running command:" "${post_struct_cmd[@]}"
"${post_struct_cmd[@]}"
echo "[DONE] micapipe:post_structural."

# --- m i c a p i p e cleanup ---
echo "[STEP] micapipe-cleaning ${sub}-${ses}"

cleanup_cmd=(
    singularity run --writable-tmpfs --containall
	-B "${bids}:/bids"
    -B "${out}:/out"
    -B "${tmpDir}:/tmp"
    -B "${fs_licence}:/opt/licence.txt"
    "${micapipe_img}"
    -cleanup
    -out /out
    -fs_licence /opt/licence.txt
    -bids /bids
    -sub "${sub}"
    -ses "${ses}"
    -post_structural
)

echo "[INFO] Running command:" "${cleanup_cmd[@]}"
"${cleanup_cmd[@]}"
echo "[DONE] micapipe-cleaning ${sub}-${ses}"

echo "[INFO] Post-scrubber script complete $(date)"
