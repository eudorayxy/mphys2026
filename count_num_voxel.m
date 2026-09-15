clear all
tic

onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';
stroke_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');

addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

dataset = 'Visit 2';
mask_threshold = 0.9;

atlas_nii = 'DKTatlas.nii';
atlas_dataset = 'Visit 1';
% atlas_nii = 'aparc.DKTatlas+aseg-in-rawavg_mgz2nii.nii';
atlas_nii = 'aseg-in-rawavg_mgz2nii.nii';

% 'c13D_T1w.nii' for grey matter, 'c23D_T1w.nii'for white matter
% gm = struct('name', 'gm', 't1w_nii', 'c13D_T1w.nii');
% wm = struct('name', 'wm', 't1w_nii', 'c23D_T1w.nii');
% csf = struct('name', 'csf', 't1w_nii', 'c33D_T1w.nii'); % imerode csf & lateral ventricle?
% choroid_plexus = struct('name', 'choroid plexus', 'atlas_idx', [31 63]);
% lateral_ventricle = struct('name', 'lateral ventricles', ...
%     'atlas_idx', [4 43]);
gm = struct('name', 'GM', 't1w_nii', 'c13D_T1w.nii');
wm = struct('name', 'WM', 't1w_nii', 'c23D_T1w.nii');
csf = struct('name', 'CSF', 't1w_nii', 'c33D_T1w.nii'); % imerode csf & lateral ventricle?
choroid_plexus = struct('name', 'choroid plexus', 'atlas_idx', [31 63]);
lateral_ventricle = struct('name', 'lateral ventricles', ...
    'atlas_idx', [4 43]);
tissue_prob = replace(num2str(mask_threshold), '.', '_');

tissue_type = {gm, wm, csf, choroid_plexus, lateral_ventricle};
header = string(cellfun(@(x) x.name, tissue_type,"UniformOutput",false));

% Loop over all participants
% id_list = readlines([onedrive 'CE-ASL\Data\CE-ASL_IDs.txt']);
% id_list = strip(id_list); % remove whitespace
% id_list = id_list(id_list ~= "" & ~startsWith(id_list, "#"));  % remove comments and empty lines

% change this
id_list = readtable([onedrive 'CE-ASL\' dataset '\visit2_data.xlsx']).ID;
% id_list(strcmp(id_list,'053_no_contrast')) = [];
% select_row = find(strcmp(id_list, '053_no_contrast'));
% id_list = id_list(select_row, :);
id_list = readtable(fullfile(stroke_impact_dir, "data_log.csv")).id;

% output_folder = fullfile(onedrive, 'CE-ASL/Output/count_num_voxel', dataset);
% if ~exist(output_folder, 'dir')
%     mkdir(output_folder);
% end

% num_seg_voxel_workbook = fullfile(output_folder, [dataset '_num_voxel.xlsx']);
num_seg_voxel_workbook = fullfile(stroke_impact_dir, 'Output', 'num_voxel.xlsx');

sum_seg_mask = zeros(length(id_list), numel(tissue_type));

for tis=1:numel(tissue_type)
    this_tissue_struct = tissue_type{tis};
    
    for idx = 1:numel(id_list)
        
        id = char(id_list(idx))
        % rootdir = [onedrive 'CE-ASL\' dataset '\' id '\'];
        rootdir = fullfile(stroke_impact_dir, id);

        % if ~isfile(fullfile(rootdir, 'structural', atlas_nii))
        %     atlas_rootdir = [onedrive 'CE-ASL\' atlas_dataset '\' id '\'];
        %     atlas_rootdir_nocontrast = [onedrive 'CE-ASL\' atlas_dataset '\' id '_no_contrast\'];
        %     if isfile(fullfile(atlas_rootdir, 'structural', atlas_nii))
        %         atlas_nii_path = fullfile(atlas_rootdir, 'structural', atlas_nii);
        %     elseif isfile(fullfile(atlas_rootdir_nocontrast, 'structural', atlas_nii))
        %         atlas_nii_path = fullfile(atlas_rootdir_nocontrast, 'structural', atlas_nii);
        %     else
        %         error('DKTatlas file %s cannot be found', atlas_nii)
        %     end
        % else
        %     atlas_nii_path = fullfile(rootdir, 'structural', atlas_nii);
        % end

        if ~isfile(fullfile(rootdir, 'roi', atlas_nii))
            disp('no atlas file')
            continue
        else
            atlas_nii_path = char(fullfile(rootdir, 'roi', atlas_nii));
        end
            
        %%
        if isfield(this_tissue_struct, 't1w_nii')
            seg = double(load_nii(fullfile(rootdir, 'structural', this_tissue_struct.t1w_nii)).img);
            seg_mask = seg > mask_threshold;
            seg_mask = double(seg_mask);
            sum_seg_mask(idx, tis) = sum(seg_mask(:), 'omitnan');     
        elseif isfield(this_tissue_struct, 'atlas_idx')
            seg = double(load_nii(atlas_nii_path).img);
            seg_mask = nan(size(seg)); % 
            for atlas_idx=this_tissue_struct.atlas_idx
                seg_mask(seg==atlas_idx) = 1;
            end
            sum_seg_mask(idx, tis) = sum(seg_mask(:), 'omitnan');
        end
    end
end

seg_table = array2table(sum_seg_mask, 'VariableNames', header);
seg_table = addvars(seg_table, id_list, ...
                    'Before', 1, ...
                    'NewVariableNames', 'Participant_ID');
% writetable(seg_table, num_seg_voxel_workbook, ...
%             'WriteMode', 'append', 'WriteVariableNames', false)
writetable(seg_table, num_seg_voxel_workbook)

toc