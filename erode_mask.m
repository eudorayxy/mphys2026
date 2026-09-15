clear all
tic

onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';

addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

dataset = 'Data';
% change this
id_list = readtable([onedrive 'CE-ASL\' dataset '\Data_data.xlsx']).ID;
% id_list(strcmp(id_list,'053_no_contrast')) = [];
% select_row = find(strcmp(id_list, '056_no_contrast'));
% id_list = id_list(select_row);
% id_list(2) = [];

voxelsize = [1.719 1.719 4]; % check this is correct
voxelsize = [1 1 1];
mask_threshold = 0.9;

PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms

atlas_nii = 'DKTatlas.nii';
atlas_dataset = 'Visit 1';
atlas_nii = 'aparc.DKTatlas+aseg-in-rawavg_mgz2nii.nii';
% lateral ventricle 4 & 43
% choroid plexus 31 & 63
% tissue_type = {'lateral_ventricle', 'choroid_plexus'};
% tissue_idx = {[4 43], [31 63]};

gm = struct('name', 'GM', 't1w_nii', 'c13D_T1w.nii');
wm = struct('name', 'WM', 't1w_nii', 'c23D_T1w.nii');
csf = struct('name', 'CSF', 't1w_nii', 'c33D_T1w.nii'); % imerode csf & lateral ventricle?
choroid_plexus = struct('name', 'choroid plexus', 'atlas_idx', [31 63]);
lateral_ventricle = struct('name', 'lateral ventricles', ...
    'atlas_idx', [4 43]);

% csf.erode_num_vox = 1; % number of voxels
lateral_ventricle.erode_num_vox = 5;
tissue_type = {lateral_ventricle};

header = string(cellfun(@(x) x.name, tissue_type,"UniformOutput",false));

out_dir = {'ASL', 'CE-ASL'};

output_folder = [onedrive 'CE-ASL\Output\'];
write_dir = fullfile(onedrive, 'CE-ASL/Output/erode_mask', dataset);
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
if ~isfolder(write_dir)
    mkdir(write_dir);
end

sum_corrected_mask = zeros(length(id_list), numel(tissue_type));
sum_mask = zeros(length(id_list), numel(tissue_type));

for tis=1:numel(tissue_type)

    this_tissue_struct = tissue_type{tis};
    write_dir_tis = fullfile(write_dir, this_tissue_struct.name);
    if ~isfolder(write_dir_tis)
        mkdir(write_dir_tis)
    end

    % Initialize empty struct arrays
    eASL_mean = [];
    eASL_median = [];
    eASL_std = [];
    
    CeASL_mean = [];
    CeASL_median = [];
    CeASL_std = [];

    tissue_name = this_tissue_struct.name;

    logfile_name = fullfile(write_dir_tis, [dataset '_' ...
        this_tissue_struct.name '_erode_mask.txt']);
    logfile = fopen(logfile_name, 'a');
    
    for idx = 1:numel(id_list)
        
        id = char(id_list(idx))
        fprintf(logfile, '\nID: %s', id);
        rootdir = [onedrive 'CE-ASL\' dataset '\' id '\'];
        write_dir_id = fullfile(write_dir_tis, id);
        if ~isfolder(write_dir_id)
            mkdir(write_dir_id)
        end
        
        % Initialize structs for each dataset for this participant
        S_e_mean = struct('Participant_ID', char(id));
        S_e_median = struct('Participant_ID', char(id));
        S_e_std = struct('Participant_ID', char(id));
        S_c_mean = struct('Participant_ID', char(id));
        S_c_median = struct('Participant_ID', char(id));
        S_c_std = struct('Participant_ID', char(id));

        pre_data_exist = true;
        post_data_exist = true;

        % structural_dir = dir(fullfile(rootdir, 'structural'));
        
        %%
        if ~isfile(fullfile(rootdir, 'structural', atlas_nii))
            atlas_rootdir = [onedrive 'CE-ASL\' atlas_dataset '\' id '\'];
            atlas_rootdir_nocontrast = [onedrive 'CE-ASL\' atlas_dataset '\' id '_no_contrast\'];
            if isfile(fullfile(atlas_rootdir, 'structural', atlas_nii))
                atlas_nii_path = fullfile(atlas_rootdir, 'structural', atlas_nii);
            elseif isfile(fullfile(atlas_rootdir_nocontrast, 'structural', atlas_nii))
                atlas_nii_path = fullfile(atlas_rootdir_nocontrast, 'structural', atlas_nii);
            else
                error('DKTatlas file %s cannot be found', atlas_nii)
            end
        else
            atlas_nii_path = fullfile(rootdir, 'structural', atlas_nii);
        end

        %% select roi here!
        if isfield(this_tissue_struct, 't1w_nii')
            seg = double(load_nii(fullfile(rootdir, 'structural', this_tissue_struct.t1w_nii)).img);
            seg_mask = seg > mask_threshold;  
        elseif isfield(this_tissue_struct, 'atlas_idx')
            seg = double(load_nii(atlas_nii_path).img);
            seg_mask = zeros(size(seg)); 
            for atlas_idx=this_tissue_struct.atlas_idx
                seg_mask(seg==atlas_idx) = 1;
            end
        else
            fprintf(logfile, ['\nNo mask for' this_tissue_struct.name ' - ID:' id ...
                            '. Skip data extraction\n']);
            continue
        end
        
        %% some correction
        reject_mask = zeros(size(seg_mask));
        write_corrected_data = 0;
        if isfield(this_tissue_struct, 'erode_num_vox')

            erode_size_int = ceil(this_tissue_struct.erode_num_vox * voxelsize(1));
            erode_size_str = replace(num2str(erode_size_int), '.', '_');
            if idx == 1
               fprintf(logfile, '\nErode size:%s\n', erode_size_str); 
            end
            
            write_corrected_data = 1;

            se = strel('disk', erode_size_int);
            
            corrected_mask = zeros(size(seg_mask));
            for z = 1:size(seg_mask,3)
                corrected_mask(:,:,z) = imerode(seg_mask(:,:,z), se);
            end

            sum_corrected_mask(idx, tis) = sum(corrected_mask(:), 'omitnan');
            corrected_seg_mask_nii = make_nii(corrected_mask, voxelsize);
            save_nii(corrected_seg_mask_nii, fullfile(write_dir_id, ...
                [this_tissue_struct.name 'erode_size' erode_size_str ...
                '_corrected_mask.nii']));
            centre_header_file(fullfile(write_dir_id, ...
                [this_tissue_struct.name 'erode_size' erode_size_str ...
                '_corrected_mask.nii']))
        end

        sum_mask(idx, tis) = sum(seg_mask(:), 'omitnan');
        seg_mask_nii = make_nii(seg_mask, voxelsize);
        save_nii(seg_mask_nii, fullfile(write_dir_id, ...
            [this_tissue_struct.name '_mask.nii']));
        centre_header_file(fullfile(write_dir_id, ...
            [this_tissue_struct.name '_mask.nii']))
      
        %%
        for i=1:numel(out_dir)
            fprintf(logfile, ' dir %s \n', out_dir{i});
            read_dir = fullfile(rootdir, out_dir{i});
            files = dir(fullfile(read_dir, 'r*.nii'));
    
            if numel(files) == 0
                fprintf(logfile, 'No registered images found in %s\n', out_dir{i});
                if strcmp(out_dir{i}, 'ASL')
                    pre_data_exist = false;
                elseif strcmp(out_dir{i}, 'CE-ASL')
                    post_data_exist = false;
                end
                
            else
                for j = 1:numel(files)
                    nii_file = fullfile(read_dir, files(j).name);
                    image = double(load_nii(nii_file).img);
                    if contains(files(j).name, 'M0')
                        if contains(files(j).name, 'PLD700')
                            M0_image_PLD700 = image;
                        else
                            M0_image_PLD1000 = image;
                        end
                    end
                end
                
                for j = 1:numel(files)
                    if ~contains(files(j).name, 'M0')
                        nii_file = fullfile(read_dir, files(j).name);
                        nii = load_nii(nii_file);
                        image = double(nii.img);
                        % Make field name readable and valid
                        name = erase(files(j).name, '.nii');
                        fprintf(logfile, 'Extracting data from %s ...\n', name);
                        % Get the right M0 image for the series
                        if contains(files(j).name, 'PLD700')
                            M0_image = M0_image_PLD700;
                            PLDs = PLDs_eASL_PLD700;
                        elseif contains(files(j).name, 'PLD1000')
                            M0_image = M0_image_PLD1000;
                            PLDs = PLDs_eASL_PLD1000;
                        end
                        
                        parsed = split(name, '_');
                    
                        if ismember(str2num(parsed{end}), PLDs)
                            field_name = ['PLD' parsed{end}];
                        else
                            error([name '.nii: ' parsed{end} ' not in PLDs'])
                        end
                    %     field_name = name;
                    % 
                    % else
                        % keyname = [char(parsed(1)) '_' char(parsed(end))];
                        % field_name = keyname;
                        
                        fprintf(logfile, 'file name:%s, PLD: %s s\n', name, parsed{end});

                        % scale the data and re-calculate mean and median
                        % make sure size(seg_ratio_3D) == size(nii.img) !
                        ratio = (image ./ M0_image) / 32;
                        % seg_ratio = ratio(seg_mask == 1); % this extracts data directly returning a column vector
                        % we want masking!
                        seg_ratio_3D = ratio;
                        seg_ratio_3D(seg_mask ~= 1) = 0;
                        seg_ratio = seg_ratio_3D(seg_mask == 1);
                        % nii_out = nii;
                        % nii_out.img = seg_ratio_3D;
                        % nii_out = make_nii(seg_ratio_3D, voxelsize);
                        % % need PLD id in the name!
                        % save_nii(nii_out, fullfile(write_dir_id, [name '.nii']))
                        % ratio = ratio / lambda;

                        if write_corrected_data
                            corrected_ratio_3D = ratio;
                            corrected_ratio_3D(corrected_mask ~= 1) = 0;
                            corrected_ratio = corrected_ratio_3D(corrected_mask==1);
                            % nii_corr = nii;
                            % nii_corr.img = corrected_ratio_3D;
                            % nii_corr = make_nii(corrected_ratio_3D, voxelsize);
                            % save_nii(nii_corr, fullfile(write_dir_id, ...
                            %     [name '_erode_size' ...
                            %     erode_size_str '.nii']))
                            corrected_mean_val = mean(corrected_ratio, 'omitnan') % mean and median
                            corrected_median_val = median(corrected_ratio, 'omitnan')
                            corrected_std_val = std(corrected_ratio, 'omitnan');
                            fprintf(logfile, ...
                                '\ncorrected mean: %.3e, corrected median: %.3e\n', ...
                                corrected_mean_val, corrected_median_val);
                        end
                        mean_val = mean(seg_ratio, 'omitnan') % mean and median
                        median_val = median(seg_ratio, 'omitnan')
                        fprintf(logfile, ...
                                '\nmean: %.3e, median: %.3e\n', ...
                                mean_val, median_val);
                        
                    end

                    if write_corrected_data
                        % Assign based on dataset type
                        if strcmp(out_dir{i}, 'ASL')
                            S_e_mean.(field_name) = corrected_mean_val;
                            S_e_median.(field_name) = corrected_median_val;
                            S_e_std.(field_name) = corrected_std_val;
                           
                        else
                            S_c_mean.(field_name) = corrected_mean_val;
                            S_c_median.(field_name) = corrected_median_val;
                            S_c_std.(field_name) = corrected_std_val;
                        end
                    end
                end
            end
        end
        % Append to arrays
        if pre_data_exist
            if ~isempty(eASL_median)
                if numel(fieldnames(S_e_median)) == numel(fieldnames(eASL_median))
                    eASL_mean = [eASL_mean; S_e_mean];
                    eASL_median = [eASL_median; S_e_median];
                    eASL_std = [eASL_std; S_e_std];
                end
            else
                eASL_mean = [eASL_mean; S_e_mean];
                eASL_median = [eASL_median; S_e_median];
                eASL_std = [eASL_std; S_e_std];
            end
        end

        if post_data_exist
            if ~isempty(CeASL_median)
                if numel(fieldnames(S_c_median)) == numel(fieldnames(CeASL_median))
                    CeASL_mean = [CeASL_mean; S_c_mean];
                    CeASL_median = [CeASL_median; S_c_median];
                    CeASL_std = [CeASL_std; S_c_std];
                end
            else
                CeASL_mean = [CeASL_mean; S_c_mean];
                CeASL_median = [CeASL_median; S_c_median];
                CeASL_std = [CeASL_std; S_c_std];
            end
        end
        
    end
    
    deltaM_excel_workbook = fullfile(write_dir_tis, ...
        ['erode_size' erode_size_str '_deltaM.xlsx']);

    struct_holder = {eASL_mean, eASL_median, eASL_std, ...
        CeASL_mean, CeASL_median, CeASL_std};
    sheet_names = {'eASL_mean', 'eASL_median', 'eASL_std', ...
               'CeASL_mean', 'CeASL_median', 'CeASL_std'};

    is_struct_array = cellfun(@isstruct, struct_holder);
    struct_holder = struct_holder(is_struct_array);
    sheet_names = sheet_names(is_struct_array);

    for si=1:numel(struct_holder)
        T = struct2table(struct_holder{si});

        T.Properties.VariableNames(2:end) = cellfun(@(x) num2str(sscanf(x,'PLD%d')), ...
                                            T.Properties.VariableNames(2:end), ...
                                            'UniformOutput', false);
        numbers = str2double(T.Properties.VariableNames(2:end));
        
        % Sort numerically
        [sorted_numbers, idx] = sort(numbers);
        
        % Reorder PLD columns
        T = T(:, ['Participant_ID', T.Properties.VariableNames(1+idx)]);
        
        % Rename PLD columns to numeric strings for Excel
        T.Properties.VariableNames(2:end) = string(sorted_numbers);
        
        % Write to Excel
        % writetable(T, deltaM_excel_workbook, 'Sheet', sheet_names{si}, ...
        %     'WriteMode', 'append', 'WriteVariableNames', false)
        writetable(T, deltaM_excel_workbook, 'Sheet', sheet_names{si})
    end
    
   fclose(logfile);
   seg_table = array2table(sum_mask, 'VariableNames', header);
seg_table = addvars(seg_table, id_list, ...
                    'Before', 1, ...
                    'NewVariableNames', 'Participant_ID');

num_seg_voxel_workbook = fullfile(write_dir_tis, [dataset '_num_seg.xlsx']);
% writetable(seg_table, num_seg_voxel_workbook, ...
%             'WriteMode', 'append', 'WriteVariableNames', false)
writetable(seg_table, num_seg_voxel_workbook)

corrected_seg_table = array2table(sum_corrected_mask, 'VariableNames', header);
corrected_seg_table = addvars(corrected_seg_table, id_list, ...
                    'Before', 1, ...
                    'NewVariableNames', 'Participant_ID');
% writetable(seg_table, num_seg_voxel_workbook, ...
%             'WriteMode', 'append', 'WriteVariableNames', false)

corrected_num_seg_voxel_workbook = fullfile(write_dir_tis, [dataset ...
    'erode_size' erode_size_str '_corrected_num_seg.xlsx']);
writetable(corrected_seg_table, corrected_num_seg_voxel_workbook)
end



toc