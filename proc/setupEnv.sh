micapipe7t() {
    PATH=$(IFS=':'; p=($PATH); unset IFS; p=(${p[@]%%*micapipe*}); IFS=':'; echo "${p[*]}"; unset IFS)
    
    # MICAPIPE
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
    export fs_licence="/data_/mica1/01_programs/freesurfer-7.3.2/license.txt"

}
