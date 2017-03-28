
#!/bin/sh
# eddy processing 

# 1/25/17 - changed name of output zip file from DKI_results to EddyReports. Left intermediate folder names even though they are misleading. BS
# 2/20/17 - changed from fsl/5.0.6 to fsl/5.0.9. 5.0.6 was missing some outputs. Revised final outputs to v2. BS
# 3/23/17 - created this notopup.sh by eliminating topup related things from DWIpreprocessing -EZ 

module load fsl/5.0.9
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
module load dcm2niix/052016

echo_time() {
    date +"%R $*"
}

echo_time "Current directory: " 
pwd

# $1 is subject directory, $2 is DKI dicoms, $3 is DWI dicoms $4 and $5 is Series number and description (modality), $6 T(use generated B vals) F(use provided B vals), $7 is the
# path tothe config files (.txt) files, $8 is the acquisition parameter file to use 

echo_time “##########  Converting DICOM to NIFTI”
mkdir $1/AP
#dcm2nii -o $1/AP/ $2
dcm2niix -o $1/AP/ -z y $2
mv $1/AP/*.nii.gz $1/AP/A2P.nii.gz
cp $1/AP/*.bvec $1/AP/bvecs.txt
cp $1/AP/*.bval $1/AP/bvals.txt
mv $2/*.nii.gz $1/AP/A2P.nii.gz
cp $2/*.bvec $1/AP/bvecs.txt
cp $2/*.bval $1/AP/bvals.txt
###########mkdir $1/PA
###########dcm2nii -o $1/PA/ $3
###########dcm2niix -o $1/PA/ -z y $3
############mv $1/PA/*.nii.gz $1/PA/P2A.nii.gz
############mv $3/*.nii.gz $1/PA/P2A.nii.gz

echo_time “##########  Pulling a2p images”
fslroi $1/AP/A2P.nii.gz $1/a2p.nii.gz 0 1
#############fslroi $1/PA/P2A.nii.gz $1/p2a.nii.gz 0 1

############echo_time  "##########  Merging PE and reverse-PE images"
############fslmerge -t $1/a2p_p2a $1/a2p.nii.gz $1/p2a.nii.gz 
############echo "Merged image created"

############echo_time "#######  Estimating susceptibility induced distortions with <topup>"
############topup --imain=$1/a2p_p2a.nii.gz --datain=$7/$8 --config=${FSLDIR}/etc/flirtsch/b02b0.cnf --out=$1/topup_results --iout=$1/hifi_b0 --verbose


echo_time "#######  Running BET"
bet $1/a2p.nii.gz $1/hifi_b0_brain -m -n -f 0.35

mkdir $1/DKI_results
mkdir $1/Reconstructions

echo_time "#######  Running eddy correction"
# Use generated bvals and bvecs for Siemens systems
#if [ $6 == 'T' ]; then
#eddy_openmp --imain=$1/AP/A2P.nii.gz --mask=$1/hifi_b0_brain_mask --acqp=/rcc/stor1/users/bswearingen/DWIonCluster/acqparams.txt --index=/rcc/stor1/users/bswearingen/DWIonCluster/index.txt --bvecs=$1/AP/bvecs.txt --bvals=$1/AP/bvals.txt --topup=$1/topup_results --out=$1/DKI_results/DKI_ECC --very_verbose
#eddy --imain=$1/AP/A2P.nii.gz --mask=$1/hifi_b0_brain_mask --acqp=$7/$8 --index=$7/index.txt --bvecs=$1/AP/bvecs.txt --bvals=$1/AP/bvals.txt --topup=$1/topup_results --out=$1/DKI_results/DKI_ECC --very_verbose
#fi
# Use provided bvals and bvecs for GE systems
#if [ $6 == 'F' ]; thena
#eddy_openmp --imain=$1/AP/A2P.nii.gz --mask=$1/hifi_b0_brain_mask --acqp=/rcc/stor1/users/bswearingen/DWIonCluster/acqparams.txt --index=/rcc/stor1/users/bswearingen/DWIonCluster/index.txt --bvecs=/rcc/stor1/users/bswearingen/DWIonCluster/bvecs.txt --bvals=/rcc/stor1/users/bswearingen/DWIonCluster/bvals.txt --topup=$1/topup_results --out=$1/DKI_results/DKI_ECC --very_verbose

eddy_openmp --imain=$1/AP/A2P.nii.gz --mask=$1/hifi_b0_brain_mask --acqp=$7/$8 --index=$7/index.txt --bvecs=$7/bvecs.txt --bvals=$7/bvals.txt --topup=$1/topup_results --out=$1/DKI_results/DKI_ECC --very_verbose

#fi

# rename output files for naming convention
cp $1/AP/A2P.nii.gz $1/Reconstructions/$4__nat__orig__orig__all__0__v2.nii.gz
############# cp $1/PA/P2A.nii.gz $1/Reconstructions/$5__nat__orig__orig__all__0__v2.nii.gz
#############mv $1/topup_results_fieldcoef.nii.gz $1/Reconstructions/$4__nat__other__DTI_TOPUP_RESULTS__all__0__v2.nii.gz
mv $1/DKI_results/DKI_ECC.nii.gz $1/Reconstructions/$4__nat__other__FINAL_DTI_PREPROCESS_NOTOPUP__all__0__v2.nii.gz

# put output txt files in one folder and zip it to reconstructions 
mv $1/topup_results_movpar.txt $1/DKI_results/ 
zip -r $1/Reconstructions/$4_EddyWithoutTopupReports.zip $1/DKI_results

#chmod 770 ./*

echo_time "Finished"
Contact GitHub API Training Shop Blog About
© 2017 GitHub, Inc. Terms Privacy Security Status Help