#!/bin/bash

sub=$1
ses=$2
root=$3
mask_inference=$4
tmp=$5
threads=$6

# Preamble
bids=$root/rawdata/
out=$root/derivatives
fs_lic=/data_/mica1/01_programs/freesurfer-7.3.2/license.txt


# Generate surfaces - FastSurfer
fsdir=${out}/fastsurfer
fsdir_sub=${fsdir}/${id}

rm ${fsdir_sub}/mri/mask.mgz ${fsdir_sub}/mri/norm.mgz
## Replace mask
mri_convert $mask_inference ${fsdir_sub}/mri/mask.mgz
##  orig_nu.mgz * inference_mask
mrconvert ${fsdir_sub}/mri/orig_nu.mgz ${fsdir_sub}/mri/orig_nu.nii.gz
fslmaths $mask_inference -mul ${fsdir_sub}/mri/orig_nu.nii.gz ${fsdir_sub}/mri/norm.nii.gz
## norm.nii.gz -> .mgz
mrconvert ${fsdir_sub}/mri/norm.nii.gz ${fsdir_sub}/mri/norm.mgz
## rm Remove files previously created by the first run of recon-surf
rm ${fsdir_sub}/mri/wm.mgz ${fsdir_sub}/mri/aparc.DKTatlas+aseg.orig.mgz ${fsdir_sub}/mri/orig_nu.nii.gz
## FastSurfer call
post_qc_fastsurfer -sub ${sub} -ses ${ses} -out ${fsdir}

# Post Struc and associated modules
singularity run --writable-tmpfs --containall \
	-B ${bids}:/bids \
	-B ${out}:/out \
	-B ${tmp}:/tmp \
	-B ${fs_lic}:/opt/licence.txt \
	 ${micapipe_img} -bids /bids -out /out \
	-sub ${sub} -ses ${ses} -fs_licence /opt/licence.txt -threads ${threads} \
    -post_structural \

    -proc_dwi -dwi_main /bids/${id1}/dwi/${id}_acq-multib38_dir-AP_dwi.nii.gz,/bids/${id1}/dwi/${id}_acq-multib70_dir-AP_dwi.nii.gz \
    -dwi_rpe /bids/${id1}/dwi/${id}_acq-b0_dir-PA_dwi.nii.gz -regSynth \

    -GD -proc_func \
	-mainScanStr task-rest_echo-1_bold,task-rest_echo-2_bold,task-rest_echo-3_bold \
	-func_pe /bids/${id1}/fmap/${id}_acq-fmri_dir-AP_epi.nii.gz \
	-func_rpe /bids/${id1}/fmap/${id}_acq-fmri_dir-PA_epi.nii.gz \
	-MPC -mpc_acq T1map -regSynth \
	-microstructural_img /bids/${id1}/anat/${id}_acq-05mm_T1map.nii.gz \
	-microstructural_reg FALSE \
	-SC -tracts 40M

# cleanup
echo "cleaning up"
micapipe_cleanup -sub ${sub} -ses ${ses} \
        -bids ${bids} \
        -out ${out} \
        -post_structural

