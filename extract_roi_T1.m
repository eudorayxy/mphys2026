% workbook corresponds to roi T1
% sheet: mean median std

clear all
tic

onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

dataset = 'Visit 1';
voxelsize = [1.719 1.719 4]; % check this is correct
voxelsize = [1 1 1];
mask_threshold = 0.9;

strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');

% change this
id_list = readtable([onedrive 'CE-ASL\' dataset '\visit1_data.xlsx']).ID;
% id_list = id_list(2);
% id_list(strcmp(id_list,'053_no_contrast')) = [];
% select_row = find(strcmp(id_list, '053_no_contrast'));
% id_list = id_list(select_row);
% id_list(2) = [];
id_list = readtable(fullfile(strokes_impact_dir, "data_log.csv")).id;

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

tissue = choroid_plexus;
tissue = lateral_ventricle;

% read_dir = fullfile(onedrive, 'CE-ASL/Output/erode_mask', dataset, tissue.name);
read_dir = fullfile(strokes_impact_dir, 'Output/erode_mask');
% read_file_str = [tissue.name '_mask'];
% read_file_str = [tissue.name '_erode1mm'];
% read_file_str = [tissue.name '_erode2mm'];
% read_file_str = [tissue.name '_erode3mm'];
% read_file_str = [tissue.name '_erode4mm'];
% read_file_str = [tissue.name '_erode5mm'];
% read_file_str = [tissue.name '_0_9'];
% read_file_str = tissue.t1w_nii;

list = {[tissue.name '_erode1mm'],...
        [tissue.name '_erode2mm'], [tissue.name '_erode3mm'], ...
        [tissue.name '_erode4mm'], [tissue.name '_erode5mm']};
for i=1:numel(list)
    read_file_str = list{i};
out_file_str = read_file_str;
% out_file_str = [tissue.name '_' replace(num2str(mask_threshold), '.', '_')];

% write_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', dataset);
write_dir = fullfile(strokes_impact_dir, 'Output/extract_roi_T1');
if ~isfolder(write_dir)
    mkdir(write_dir);
end

mean_T1 = nan(numel(id_list), 1);
median_T1 = nan(numel(id_list), 1);
std_T1 = nan(numel(id_list), 1);
write_workbook = fullfile(write_dir, [out_file_str '.xlsx']);

for idx = 1:numel(id_list)
    id = char(id_list(idx))
    rootdir = fullfile(strokes_impact_dir, id);
    % read registered T1 map
    t1_dir = fullfile(rootdir, 'ASL');
    r_t1_nii = fullfile(t1_dir, 'rT1.nii');
    if ismember('rT1.nii', {dir(t1_dir).name})
        % r_t1_map = double(load_nii(r_t1_nii).img); % old code
        r_t1_map = double(niftiread(r_t1_nii));
    
        % read mask
        mask_dir = fullfile(read_dir, tissue.name, id);
        roi_mask_nii = fullfile(mask_dir, [read_file_str '.nii']);
        if exist(roi_mask_nii, 'file') == 0
            disp('file not exist')
            continue
        end
        % roi_mask_nii = fullfile(structural_dir, read_file_str)
        % roi_mask = double(load_nii(roi_mask_nii).img); % old code
        roi_mask = double(niftiread(roi_mask_nii));
        % roi_mask = roi_mask > mask_threshold;
        
        % extract roi T1 map
        r_t1_map = r_t1_map(roi_mask == 1);
    
        % calculate mean, median, std
        mean_T1(idx) = mean(r_t1_map, "all", "omitnan");
        median_T1(idx) = median(r_t1_map, "all", "omitnan");
        std_T1(idx) = std(r_t1_map, "omitnan");
    else
        disp('no registered T1 map')
    end
end

mean_T1_tbl = table(id_list, mean_T1, VariableNames=["Participant_ID","T1"]);
median_T1_tbl = table(id_list, median_T1, VariableNames=["Participant_ID","T1"]);
std_T1_tbl = table(id_list, std_T1, VariableNames=["Participant_ID","T1"]);

writetable(mean_T1_tbl, write_workbook, 'Sheet', 'mean')
writetable(median_T1_tbl, write_workbook, 'Sheet', 'median')
writetable(std_T1_tbl, write_workbook, 'Sheet', 'std')
end

toc