%% Inputs:
% reffn: filename of the reference image (target space).
% movingfn: filename of the source image (to be aligned).
% otherfn: optional list of filenames for other images to transform using the same parameters.
function [output_filename] = Eu_register_x(reffn, movingfn, otherfn)

% Job saved on 21-Jul-2022 14:58:27 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
clear jobs;
%% SPM Job Configuration:
% jobs{1}.spm.spatial.coreg.estwrite % first job in the list
% Above: This is the SPM job for coregistration with estimation and writing.
% ref: the reference image.
% source: the image to be aligned.
% other: other images to apply the same transformation.
jobs{1}.spm.spatial.coreg.estwrite.ref = {[reffn ',1']}; % use the first volume of the reference image.
jobs{1}.spm.spatial.coreg.estwrite.source = {[movingfn ',1']}; % use the first volume of the moving image.
if ~isempty(otherfn)
    for i=1:length(otherfn)
        otherfn(i) = {[char(otherfn(i)) ',1']};
    end
    transpose(otherfn);
    jobs{1}.spm.spatial.coreg.estwrite.other = otherfn;
end
%% eoptions: estimation options:
% cost_fun = 'nmi': uses normalized mutual information as the cost function.
jobs{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
jobs{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2]; % sampling separation
% tol: tolerance for optimization.
jobs{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
jobs{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7]; % smoothing kernel.
%% roptions: reslicing options:
% interp = 4: 4th-degree B-spline interpolation.
jobs{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
jobs{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0]; % no wrapping
jobs{1}.spm.spatial.coreg.estwrite.roptions.mask = 0; % no masking
% prefix = 'r': output files will be prefixed with 'r'.
jobs{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
%% SPM Initialization and Execution:
spm('Defaults','pet'); % sets defaults for PET imaging.
spm_jobman('initcfg'); % initializes job manager.
spm_jobman('run',jobs); % runs the job.
% oplist = spm_jobman('run',jobs);
%% Compute output filename - from Copilot
[folder, name, ext] = fileparts(movingfn);
output_filename = fullfile(folder, ['r' name ext]);
disp(['Coregistered output file: ' output_filename]);
%%
spm quit; % closes SPM
end