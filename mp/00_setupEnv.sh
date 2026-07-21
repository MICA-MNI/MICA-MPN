# Environment variables for micapipe processing
micapipe7t() {
    PATH=$(IFS=':'; p=($PATH); unset IFS; p=(${p[@]%%*micapipe*}); IFS=':'; echo "${p[*]}"; unset IFS)
    
    # MICAPIPE
    mp_version=v0.2.3
    export mp_v_string="v0.2.0"
    export micapipe_img=/data_/mica1/01_programs/micapipe-v0.2.0/micapipe_${mp_version}.sif

    export MICAPIPE=/data_/mica1/01_programs/micapipe-v0.2.0
    PATH=$PATH:${MICAPIPE}:${MICAPIPE}/functions
    
    # MINC  
    export MINC1_CIVET=/data/mica1/01_programs/minc1-civet
    PATH=${MINC1_CIVET}:$PATH
    # alternative
    #source /opt/minc/1.9.18/minc-toolkit-config.sh

    # FreeSurfer (7.3.2)
    export FREESURFER_HOME=/data_/mica1/01_programs/freesurfer-7.3.2
    source "${FREESURFER_HOME}/SetUpFreeSurfer.sh"
    # alternative
    #export FREESURFER_HOME=/data/mica1/01_programs/Freesurfer-6.0
    #source "${FREESURFER_HOME}/SetUpFreeSurfer.sh"

    # fastsurfer
    export FASTSURFER_HOME="/data_/mica1/01_programs/fastsurfer"
    export fastsurfer_img="/data_/mica1/01_programs/fastsurfer/fastsurfer-cpu-v2.0.0.sif"
    export fs_licence="/data_/mica1/01_programs/freesurfer-7.3.2/license.txt"

}

04_fastscrubber(){
    export nnUNet_raw="/host/verges/tank/data/fast_scrubber/nnUNet_raw"
    export nnUNet_preprocessed="/host/verges/tank/data/fast_scrubber/nnUNet_preprocessed"
    export nnUNet_results="/host/verges/tank/data/fast_scrubber/nnUNet_results"
    export dir_imgTs="${nnUNet_raw}/Dataset500_Segmentation/imagesTs"
    export dir_inf="${nnUNet_results}/Dataset500_Segmentation/nnUNetTrainer__nnUNetPlans__3d_fullres/inference"
    
    # Activate conda environment
    source /host/percy/local_raid/donna/anaconda/etc/profile.d/conda.sh
    conda activate fastscrubber_env
}

04_inputNaming(){
    local dir_fs="$1"
    local dir_imgTs="$2"
    local sub="$3"
    local ses="$4"

    export input_mgz="${dir_fs}/sub-${sub}_ses-${ses}/mri/orig.mgz"
    export input_nii="${dir_imgTs}/sub-${sub}_ses-${ses}_0000.nii.gz"
}
