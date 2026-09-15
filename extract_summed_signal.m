clear all
tic

onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

dataset = 'Visit 1';
% voxelsize = [1.719 1.719 4]; % check this is correct
voxelsize = [1 1 1]; 
mask_threshold = 0.9;
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
PLDs = [890 1300 1700 2100 2500]; %ms

% change this
id_list = readtable([onedrive 'CE-ASL\' dataset '\visit1_data.xlsx']).ID;
% id_list(strcmp(id_list,'053_no_contrast')) = [];
% select_row = find(strcmp(id_list, '053_no_contrast'));
% id_list = id_list(select_row, :);
% id_list(2) = [];

stroke_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
id_list = readtable(fullfile(stroke_impact_dir, "data_log.csv")).id;

% atlas_nii = 'DKTatlas.nii';
% atlas_dataset = 'Visit 1';
% atlas_nii = 'aparc.DKTatlas+aseg-in-rawavg_mgz2nii.nii';

% gm = struct('name', 'gm', 't1w_nii', 'c13D_T1w.nii');
% wm = struct('name', 'wm', 't1w_nii', 'c23D_T1w.nii');
% csf = struct('name', 'csf', 't1w_nii', 'c33D_T1w.nii'); % imerode csf & lateral ventricle?
% choroid_plexus = struct('name', 'choroid plexus', 'atlas_idx', [31 63]);
% lateral_ventricle = struct('name', 'lateral ventricles', ...
%     'atlas_idx', [4 43]);

% num_voxel_workbook = fullfile(onedrive, 'CE-ASL/Output/count_num_voxel', ...
%     dataset, [dataset '_num_voxel.xlsx']);
num_voxel_workbook = fullfile(stroke_impact_dir, 'Output', 'num_voxel.xlsx');
num_voxel_tbl = readtable(num_voxel_workbook, 'ReadRowNames', true, 'VariableNamingRule','preserve');

%% tissue
tissue_prob = '0_9';
% gm = struct('name', 'gm', 'label', 'GM', 't1w_nii', 'c13D_T1w.nii', 'erode_size', {{['_' tissue_prob]}});
% wm = struct('name', 'wm','label', 'WM', 't1w_nii', 'c23D_T1w.nii', 'erode_size', {{['_' tissue_prob]}});
% csf = struct('name', 'csf', 'label', 'CSF');
% lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
%     'erode_size', {{'_mask', 'erode_size1_corrected_mask', 'erode_size2_corrected_mask'...
%     'erode_size3_corrected_mask', 'erode_size4_corrected_mask','erode_size5_corrected_mask'
%     }});
% choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
%     'erode_size', {{'_mask',...
%     'erode_size1_corrected_mask'
%     }});

gm = struct('name', 'GM', 'label', 'GM', 't1w_nii', 'c13D_T1w.nii', 'erode_size', {{['_' tissue_prob]}});
wm = struct('name', 'WM','label', 'WM', 't1w_nii', 'c23D_T1w.nii', 'erode_size', {{['_' tissue_prob]}});
lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
    'erode_size', {{'_mask', '_erode1mm', '_erode2mm',...
    '_erode3mm', '_erode4mm', '_erode5mm', ...
    }});
choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
    'erode_size', {{'_mask', '_erode1mm',
    }});
tissue_type = {...gm, wm, 
    lateral_ventricle, choroid_plexus};

% tissue = wm;
% 
% mask_dir = fullfile(onedrive, 'CE-ASL/Output/erode_mask', dataset, tissue.name);
% % mask_file_str = [tissue.name '_mask'];
% % mask_file_str = [tissue.name 'erode_size1_corrected_mask'];
% mask_file_str = tissue.t1w_nii;
% % out_file_str = mask_file_str;
% out_file_str = [tissue.name '_' replace(num2str(mask_threshold), '.', '_')];

%% Loop through tissue type
for tis=1:numel(tissue_type)
    tissue = tissue_type{tis};
    % mask_dir = fullfile(onedrive, 'CE-ASL/Output/erode_mask', dataset, tissue.name);
    mask_dir = fullfile(stroke_impact_dir, 'Output/erode_mask', tissue.name);

    erode_size_arr = tissue_type{tis}.erode_size;
    for ei=1:numel(erode_size_arr)
        out_file_str = [tissue_type{tis}.name erode_size_arr{ei}];

        % write_dir = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', dataset);
        write_dir = fullfile(stroke_impact_dir, 'Output/extract_summed_signal/newnew');
        if ~isfolder(write_dir)
            mkdir(write_dir);
        end
        
        num_seg_voxel_workbook = fullfile(write_dir, [out_file_str '_num_seg.xlsx']);
        deltaM_excel_workbook = fullfile(write_dir, [out_file_str '_summed_delta_M.xlsx']);
        
        out_dir = {'ASL',...
            ... 'CE-ASL'
            };
        % Initialize empty struct arrays
        % eASL_sum = [];
        % eASL_ave_sum = [];
        eASL_mean = [];
        eASL_median = [];
        eASL_mean_times_vol = [];
        eASL_median_times_vol = [];
        eASL_std = [];
        
        % CeASL_sum = [];
        % CeASL_ave_sum = [];
        % CeASL_mean = [];
        % CeASL_median = [];
        % CeASL_mean_times_vol = [];
        % CeASL_median_times_vol = [];
        % CeASL_std = [];
        
        % logfile_name = fullfile(write_dir, 'extract_summed_signal.txt');
        % logfile = fopen(logfile_name, 'a');
        % fprintf(logfile, '\n%s\n', out_file_str);
        
        num_seg = nan(numel(id_list), 1);
            
        for idx = 1:numel(id_list)
            
            id = char(id_list(idx))
            % fprintf(logfile, '\nID: %s', id);
            
            % rootdir = fullfile(onedrive, 'CE-ASL', dataset, id);
            rootdir = fullfile(stroke_impact_dir, id);

            num_voxel = num_voxel_tbl{id, tissue.name};
            
            % Initialize structs for each dataset for this participant
            % S_e_sum = struct('Participant_ID', char(id));
            % S_e_ave_sum = struct('Participant_ID', char(id));
            S_e_mean = struct('Participant_ID', char(id));
            S_e_median = struct('Participant_ID', char(id));
            S_e_mean_times_vol = struct('Participant_ID', char(id));
            S_e_median_times_vol = struct('Participant_ID', char(id));
            S_e_std = struct('Participant_ID', char(id));

            % S_c_sum = struct('Participant_ID', char(id));
            % S_c_ave_sum = struct('Participant_ID', char(id));
            % S_c_mean = struct('Participant_ID', char(id));
            % S_c_median = struct('Participant_ID', char(id));
            % S_c_mean_times_vol = struct('Participant_ID', char(id));
            % S_c_median_times_vol = struct('Participant_ID', char(id));
            % S_c_std = struct('Participant_ID', char(id));

            pre_data_exist = true;
            % post_data_exist = true;

            mask_exist = true;
        
            % structural_dir = dir(fullfile(rootdir, 'structural'));
            
            %%
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
        
            %% create mask
            if ~exist(fullfile(mask_dir, id, [out_file_str '.nii']), "file")
                if isfield(tissue, 't1w_nii')
                    if exist(fullfile(rootdir, 'structural', tissue.t1w_nii), 'file')
                        seg = double(niftiread(fullfile(rootdir, 'structural', tissue.t1w_nii)));
                        seg_mask = seg > mask_threshold;
                    else
                        mask_exist = false;
                        disp([fullfile(rootdir, 'structural', tissue.t1w_nii) ' not exist'])
                    end
                else
                mask_exist = false;
                disp([out_file_str ' mask not exist'])
                end
            else
                roi_mask_nii = fullfile(mask_dir, id, [out_file_str '.nii']);
                seg_mask = double(niftiread(roi_mask_nii));
            end
            num_seg(idx) = sum(seg_mask(:));
            %%
            for i=1:numel(out_dir)
                % fprintf(logfile, ' dir %s \n', out_dir{i});
                registered_img_dir = fullfile(rootdir, out_dir{i});
                files = dir(fullfile(registered_img_dir, 'r*PLD*.nii'));
        
                if numel(files) == 0
                    % fprintf(logfile, 'No registered images found in %s\n', out_dir{i});
                    if strcmp(out_dir{i}, 'ASL')
                        pre_data_exist = false;
                    % elseif strcmp(out_dir{i}, 'CE-ASL')
                    %     post_data_exist = false;
                    end
                    
                else
                    for j = 1:numel(files)
                        if ~contains(files(j).name, 'M0')
                            nii_file = fullfile(registered_img_dir, files(j).name);
                            image = double(niftiread(nii_file));
                            % Make field name readable and valid
                            name = erase(files(j).name, '.nii');
                            % fprintf(logfile, 'Extracting data from %s ...\n', name);
                            % Get the right M0 image for the series
                            % if contains(files(j).name, 'PLD700')
                            %     PLDs = PLDs_eASL_PLD700;
                            % elseif contains(files(j).name, 'PLD1000')
                            %     PLDs = PLDs_eASL_PLD1000;
                            % end
                            
                            parsed = split(name, '_');
                            PLD_str = replace(parsed{end-1}, 'PLD', '');

                            if ismember(str2double(PLD_str), PLDs)
                                field_name = ['PLD' PLD_str];
                            else
                                error([name '.nii: ' PLD_str ' not in PLDs'])
                            end
                        
                            % if ismember(str2double(parsed{end}), PLDs)
                            %     field_name = ['PLD' parsed{end}];
                            % else
                            %     error([name '.nii: ' parsed{end} ' not in PLDs'])
                            % end
                            % field_name = name;
                        % 
                        % else
                            % keyname = [char(parsed(1)) '_' char(parsed(end))];
                            % field_name = keyname;
                            
                            % fprintf(logfile, 'file name:%s, PLD: %s s\n', name, parsed{end});
                           
                            if mask_exist
                                % image = image  ./ 32; % scaling factor for GE scanner
                                image = image(seg_mask==1);
                                image(isnan(image))=[]; % remove nan
    
                                mean_val = mean(image); % mean and median
                                median_val = median(image);
                                mean_val_times_vol = mean_val * num_voxel;
                                median_val_times_vol = median_val * num_voxel;
                                % sum_val = sum(image,"all"); % sum
                                % ave_sum_val = sum_val/sum(seg_mask(:));
                                std_val = std(image);
                            end
                            
                        end
            
                        if mask_exist
                            % Assign based on dataset type
                            if strcmp(out_dir{i}, 'ASL')
                                % S_e_sum.(field_name) = sum_val;
                                % S_e_ave_sum.(field_name) = ave_sum_val;
                                S_e_mean.(field_name) = mean_val;
                                S_e_mean_times_vol.(field_name) = mean_val_times_vol;
                                S_e_median.(field_name) = median_val;
                                S_e_median_times_vol.(field_name) = median_val_times_vol;
                                S_e_std.(field_name) = std_val;
                            % else
                            %     S_c_sum.(field_name) = sum_val;
                            %     S_c_ave_sum.(field_name) = ave_sum_val;
                            %     S_c_mean.(field_name) = mean_val;
                            %     S_c_mean_times_vol.(field_name) = mean_val_times_vol;
                            %     S_c_median.(field_name) = median_val;
                            %     S_c_median_times_vol.(field_name) = median_val_times_vol;
                            %     S_c_std.(field_name) = std_val;
                           
                            end
                        else
                            % S_e_sum.(field_name) = nan;
                            % S_e_ave_sum.(field_name) = nan;
                            S_e_mean.(field_name) = nan;
                            S_e_mean_times_vol.(field_name) = nan;
                            S_e_median.(field_name) = nan;
                            S_e_median_times_vol.(field_name) = nan;
                            S_e_std.(field_name) = nan;
                        end
                    end
                end
            end
            % Append to arrays
            if pre_data_exist
                % eASL_sum = [eASL_sum; S_e_sum];
                % eASL_ave_sum = [eASL_ave_sum; S_e_ave_sum];
                eASL_mean = [eASL_mean; S_e_mean];
                eASL_mean_times_vol = [eASL_mean_times_vol; S_e_mean_times_vol];
                eASL_median = [eASL_median; S_e_median];
                eASL_median_times_vol = [eASL_median_times_vol; S_e_median_times_vol];
                eASL_std = [eASL_std; S_e_std];
            end
        
            % if post_data_exist
            %     CeASL_sum = [CeASL_sum; S_c_sum];
            %     CeASL_ave_sum = [CeASL_ave_sum; S_c_ave_sum];
            %     CeASL_mean = [CeASL_mean; S_c_mean];
            %     CeASL_mean_times_vol = [CeASL_mean_times_vol; S_c_mean_times_vol];
            %     CeASL_median = [CeASL_median; S_c_median];
            %     CeASL_median_times_vol = [CeASL_median_times_vol; S_c_median_times_vol];
            %     CeASL_std = [CeASL_std; S_c_std];
            % end
            
        end
        
        struct_holder = {...eASL_sum, eASL_ave_sum, 
            eASL_std, ...
            eASL_mean, eASL_mean_times_vol, eASL_median, eASL_median_times_vol, ...
           ... CeASL_sum, CeASL_ave_sum, CeASL_std, ...
           ... CeASL_mean, CeASL_mean_times_vol, CeASL_median, CeASL_median_times_vol
           };
        % sheet_names = {'eASL_sum', 'eASL_ave_sum', 'eASL_std',...
        %        'eASL_mean', 'eASL_mean_times_vol', 'eASL_median', 'eASL_median_times_vol', ...
        %        'CeASL_sum', 'CeASL_ave_sum', 'CeASL_std', ...
        %        'CeASL_mean', 'CeASL_mean_times_vol', 'CeASL_median', 'CeASL_median_times_vol'
        %            };

        sheet_names = {...'sum', 'ave_sum', 
            'std',...
               'mean', 'mean_times_vol', 'median', 'median_times_vol'
                   };
        
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
        
        % fclose(logfile);
        
        seg_table = table(id_list, num_seg, 'VariableNames', ["Participant_ID", "num_voxel"]);
        writetable(seg_table, num_seg_voxel_workbook)
    end
end

toc