% To segment a structural brain image (usually T1-weighted MRI) into 
% different tissue types:
% Gray matter
% White matter
% Cerebrospinal fluid (CSF)
% Plus additional components like skull, soft tissue, and air/background.
% Input: fn : filename of the image to be segmented
function [  ] = Eu_segment(spm_dir, fn)
%-----------------------------------------------------------------------
% Job saved on 19-Oct-2023 16:'] patient [':24 by cfg_util (rev $Rev: 7'] patient ['5 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
clear jobs;
%% Channel settings
% jobs{1}.spm.spatial.preproc - SPM12 segmentation module, uses a
% probabilistic tissue model (TPM.nii) to classify voxels
jobs{1}.spm.spatial.preproc.channel.vols = {char(fn)}; % Specifies the image to segment.
% biasreg and biasfwhm control bias field correction (for intensity non-uniformity).
% write = [0 0] means no bias-corrected image will be saved.
jobs{1}.spm.spatial.preproc.channel.biasreg = 0.001;
jobs{1}.spm.spatial.preproc.channel.biasfwhm = 60;
jobs{1}.spm.spatial.preproc.channel.write = [0 0];
%% Tissue classes
% Each tissue has:
% ngaus: number of Gaussians used to model intensity distribution.
% native: [1 0] means save native space segmentation.
% warped: [0 0] means don't save warped versions.

% Gray matter
jobs{1}.spm.spatial.preproc.tissue(1).tpm = {[spm_dir 'spm12\tpm\TPM.nii,1']};
jobs{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
jobs{1}.spm.spatial.preproc.tissue(1).native = [1 0];
jobs{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
% White matter
% jobs{1}.spm.spatial.preproc.tissue(2).tpm = {'C:\MPhys10902195\spm12\tpm\TPM.nii,2'};
jobs{1}.spm.spatial.preproc.tissue(2).tpm = {[spm_dir 'spm12\tpm\TPM.nii,2']};
jobs{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
jobs{1}.spm.spatial.preproc.tissue(2).native = [1 0];
jobs{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
% CSF
jobs{1}.spm.spatial.preproc.tissue(3).tpm = {[spm_dir 'spm12\tpm\TPM.nii,3']};
jobs{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
jobs{1}.spm.spatial.preproc.tissue(3).native = [1 0];
jobs{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
% Bone
jobs{1}.spm.spatial.preproc.tissue(4).tpm = {[spm_dir 'spm12\tpm\TPM.nii,4']};
jobs{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
jobs{1}.spm.spatial.preproc.tissue(4).native = [1 0];
jobs{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
% Soft tissue
jobs{1}.spm.spatial.preproc.tissue(5).tpm = {[spm_dir 'spm12\tpm\TPM.nii,5']};
jobs{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
jobs{1}.spm.spatial.preproc.tissue(5).native = [1 0];
jobs{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
% Air/background
jobs{1}.spm.spatial.preproc.tissue(6).tpm = {[spm_dir 'spm12\tpm\TPM.nii,6']};
jobs{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
jobs{1}.spm.spatial.preproc.tissue(6).native = [0 0];
jobs{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
%% Warping settings
% These control spatial normalization:
% mrf: Markov Random Field cleanup.
jobs{1}.spm.spatial.preproc.warp.mrf = 1;
jobs{1}.spm.spatial.preproc.warp.cleanup = 1;
jobs{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2]; % regularization parameters.
jobs{1}.spm.spatial.preproc.warp.affreg = 'mni'; % affine registration to MNI space.
jobs{1}.spm.spatial.preproc.warp.fwhm = 0;
jobs{1}.spm.spatial.preproc.warp.samp = 3;
jobs{1}.spm.spatial.preproc.warp.write = [0 0]; % don't write deformation fields.
% vox and bb are left as NaN, meaning default voxel size and bounding box.
jobs{1}.spm.spatial.preproc.warp.vox = NaN;
jobs{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                              NaN NaN NaN];
%% Initializes SPM with PET defaults
spm('Defaults','pet');
spm_jobman('initcfg');
spm_jobman('run',jobs);
% oplist = spm_jobman('run',jobs);
spm quit;
end