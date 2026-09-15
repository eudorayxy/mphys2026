function reset_origin_spm(fn)
% Sets an image's origin (the world-space translation in its header) to the
% centre of the volume, keeping voxel size/orientation unchanged. This is a
% quick fix for SPM coregistration converging badly when two images start
% with very different origins.
V = spm_vol(fn);
vs = sqrt(sum(V.mat(1:3,1:3).^2)); % voxel sizes from the existing affine
new_mat = V.mat;
new_mat(1:3,4) = -vs' .* ((V.dim(1:3)'+1)/2);
spm_get_space(fn, new_mat); % writes the new header only, no image data change
end