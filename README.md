# MICA-MPN
Processing of MPN (Montreal Paris Neurobank) dataset

# Contents:

00_qsubCall.sh    - generic wrapper to call scripts for each participant in a list text file via qsub or locally

process.ipynb     - python scripts to establish sub-ses combinations (saved as one visit per line in text file)
setupEnv.sh       - bash environment specifications used in nlm steps
mp/		  - micapipe processing scripts
	00_setupEnv.sh    - functions to export relevant environment variables for function calls.
	01_procStruc.sh   - calls MICAPIPE's proc-struc function
	02_nlm.sh	  - performs NLM denoising on micapipe T1w output. 
	   NOTE. This step cannot be run on the queue.
	   NOTE. The minc and freesurfer environment of this step currently work when calling the function defined in setupenv.sh
	03_procSurf.sh    - surface fitting on denoised T1w
	04_scrubInf.sh    - run fastscrubber inference (automated surface QC)
	05_postScrub.sh   - run micapipe post-structural on fastscrubber surfaces
hu/               - hippunfold processing scripts
	01_hippunfold_pt.sh - run hippunfold segmentations on individuals
