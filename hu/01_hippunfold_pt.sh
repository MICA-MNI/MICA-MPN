
#!/bin/bash
set -e

# Usage:
# bash 01_hippunfold_pt.sh <sub> <ses> [-bids DIR] [-version VERSION] [-hu_img IMG] [-threads N] [-out_density DENSITY]

export SINGULARITY_BINDPATH="/host/verges/tank/data:/host/verges/tank/data"

sub=${1:?missing sub}
ses=${2:?missing ses}
sub="${sub#sub-}"
ses="${ses#ses-}"

# Defaults
bids_dir="/host/verges/tank/data/BIDS_MPN"
hi_vers="1.5.1"
hu_img="/data/mica1/01_programs/singularity/hippunfold_v${hi_vers}.sif"
threads="all"
out_density="0p5mm"

# Optional arguments
shift 2

while [[ $# -gt 0 ]]; do
    case "$1" in
        -version|--version)
            hi_vers="${2:?missing value for -version}"
            shift 2
            ;;
        -bids|--bids)
            bids_dir="${2:?missing value for -bids}"
            shift 2
            ;;
        -hu_img|--hu_img)
            hu_img="${2:?missing value for -hu_img}"
            shift 2
            ;;
        -threads|--threads)
            threads="${2:?missing value for -threads}"
            shift 2
            ;;
        -out_density|--out_density)
            out_density="${2:?missing value for -out_density}"
            shift 2
            ;;
        *)
            echo "[ERROR] Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Automatically set image if not explicitly provided
if [[ "$hu_img" == "/data/mica1/01_programs/singularity/hippunfold_v1.5.1.sif" ]]; then
    hu_img="/data/mica1/01_programs/singularity/hippunfold_v${hi_vers}.sif"
fi

modality="T1w"

# Output directory follows selected version
out_dir="${bids_dir}/derivatives/hippunfold_v${hi_vers}"

echo
echo "[INFO] date=$(date)"
echo "[INFO] hostname=$(hostname)"
echo "[INFO] user=$(whoami)"
echo "[INFO] sub=$sub ses=$ses"
echo "[INFO] HippUnfold version=$hi_vers"
echo "[INFO] hu_img=$hu_img"
echo "[INFO] bids_dir=$bids_dir"
echo "[INFO] out_dir=$out_dir"
echo "[INFO] threads=$threads"
echo "[INFO] out_density=$out_density"

echo "[STEP] Running hippunfold for ${sub}"

hu_cmd=(
    singularity run -e "${hu_img}"
    "${bids_dir}" "${out_dir}" participant
    --participant_label "${sub}"
    -p --cores "${threads}"
    --modality "${modality}"
    --path-T1w "${bids_dir}/derivatives/micapipe_v0.2.0/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_space-nativepro_T1w.nii.gz"
    --output-density "${out_density}"
    --rerun-incomplete
)

echo "[INFO] Running command: ${hu_cmd[*]}"
"${hu_cmd[@]}"

echo "[DONE] hippunfold completed for ${sub}"

