clear all
tic

onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

dataset = 'Visit 2';
mask_threshold = 0.9;
lambda = 0.9; % mL/g (Alsop 2015)

strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');

% change this
id_list = readtable([onedrive 'CE-ASL\' dataset '\visit2_data.xlsx']).ID;
% id_list(strcmp(id_list,'053_no_contrast')) = [];
% select_row = find(strcmp(id_list, '053_no_contrast'));
% id_list = id_list(select_row, :);
id_list = readtable(fullfile(strokes_impact_dir, "data_log.csv")).id;

out_dir = {'ASL', ...
    ...'CE-ASL'
    };

% output_folder = fullfile(onedrive,'CE-ASL','Output');
output_folder = fullfile(strokes_impact_dir,'Output');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Initialize empty struct arrays
eASL_mean = [];
eASL_median = [];
eASL_std = [];

CeASL_mean = [];
CeASL_median = [];
CeASL_std = [];

% M0_excel_workbook = [onedrive 'CE-ASL\Output\' ...
%      dataset '_M0.xlsx'];

M0_excel_workbook = fullfile(output_folder, 'M0.xlsx');

% logfile_name = [onedrive 'CE-ASL\Output\' ...
%     dataset '_extract_M0.txt'];
% logfile = fopen(logfile_name, 'a');

for idx = 1:numel(id_list)
    
    id = char(id_list(idx))
    % fprintf(logfile, '\nID: %s', id);
    % rootdir = [onedrive 'CE-ASL\' dataset '\' id '\'];
    rootdir = fullfile(strokes_impact_dir, id);
    % Initialize structs for each dataset for this participant
    S_e_mean = struct('Participant_ID', char(id));
    S_e_median = struct('Participant_ID', char(id));
    S_e_std = struct('Participant_ID', char(id));
    % S_c_mean = struct('Participant_ID', char(id));
    % S_c_median = struct('Participant_ID', char(id));
    % S_c_std = struct('Participant_ID', char(id));

    pre_data_exist = true;
    % post_data_exist = true;
        
    %% Create GM+WM mask
    if ~exist(fullfile(rootdir, 'structural', 'c13D_T1w.nii'), "file")
        S_e_mean.('M0') = nan;
        S_e_median.('M0') = nan;
        S_e_std.('M0') = nan;
        disp('T1w img not exist')
        continue
    end

    seg_gm = double(load_nii(fullfile(rootdir, 'structural', 'c13D_T1w.nii')).img);
    seg_wm = double(load_nii(fullfile(rootdir, 'structural', 'c23D_T1w.nii')).img);
    seg_mask = seg_gm > mask_threshold | seg_wm > mask_threshold;


    for i=1:numel(out_dir)
        % fprintf(logfile, ' dir %s \n', out_dir{i});
        read_dir = fullfile(rootdir, out_dir{i});
        files = dir(fullfile(read_dir, 'r*M0*.nii'));

        if numel(files) == 0
            % fprintf(logfile, 'No registered M0 images found in %s\n', out_dir{i});
            disp('No registered M0 images')
            if strcmp(out_dir{i}, 'ASL')
                pre_data_exist = false;
            % elseif strcmp(out_dir{i}, 'CE-ASL')
            %     post_data_exist = false;
            end
        else
            for j = 1:numel(files)
                nii_file = fullfile(read_dir, files(j).name);
                image = double(load_nii(nii_file).img);
                % if contains(files(j).name, 'M0')
                %     if contains(files(j).name, 'PLD700')
                %         M0_image = image;
                %         size(M0_image)
                %         field_name = 'M0_PLD700';
                %     else
                        M0_image = image;
                %         size(M0_image)
                %         field_name = 'M0_PLD1000';
                %     end
                % end
                field_name = 'M0';
                 % Assign based on dataset type
                if strcmp(out_dir{i}, 'ASL')
                    M0_image = M0_image(seg_mask==1);
                    S_e_mean.(field_name) = mean(M0_image, "all", "omitnan");
                    S_e_median.(field_name) = median(M0_image, "all", "omitnan");
                    S_e_std.(field_name) = std(M0_image, "omitnan");
                   
                % elseif post_data_exist
                %     M0_image = M0_image(seg_mask==1);
                %     S_c_mean.(field_name) = mean(M0_image, "all", "omitnan");
                %     S_c_median.(field_name) = median(M0_image, "all", "omitnan");
                %     S_c_std.(field_name) = std(M0_image, "omitnan");
                end
            end
        end

       
    end
    % Append to arrays
    if pre_data_exist
        eASL_mean = [eASL_mean; S_e_mean];
        eASL_median = [eASL_median; S_e_median];
        eASL_std = [eASL_std; S_e_std];
    end

    % if post_data_exist
    %     CeASL_mean = [CeASL_mean; S_c_mean];
    %     CeASL_median = [CeASL_median; S_c_median];
    %     CeASL_std = [CeASL_std; S_c_std];
    % end
    
end

struct_holder = {eASL_mean, eASL_median, eASL_std, ...
    CeASL_mean, CeASL_median, CeASL_std};
sheet_names = {'eASL_mean', 'eASL_median', 'eASL_std', ...
           'CeASL_mean', 'CeASL_median', 'CeASL_std'};

is_struct_array = cellfun(@isstruct, struct_holder);
struct_holder = struct_holder(is_struct_array);
sheet_names = sheet_names(is_struct_array);

for si=1:numel(struct_holder)
    T = struct2table(struct_holder{si});
    writetable(T, M0_excel_workbook, 'Sheet', sheet_names{si});
end

% fclose(logfile);

toc