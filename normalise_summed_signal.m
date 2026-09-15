clear all
onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';
stroke_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');

PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
PLDs = [890 1300 1700 2100 2500]; %ms
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
tissue_type = {gm, wm, ...
    lateral_ventricle, choroid_plexus};

% sheet_names = {'eASL_sum', 'eASL_ave_sum', ...
%            'CeASL_sum', 'CeASL_ave_sum'};
% 
% sheet_names = {'eASL_sum', 'eASL_ave_sum', ...
%                'eASL_mean', 'eASL_mean_times_vol', 'eASL_median', 'eASL_median_times_vol', ...
%                'CeASL_sum', 'CeASL_ave_sum', ...
%                'CeASL_mean', 'CeASL_mean_times_vol', 'CeASL_median', 'CeASL_median_times_vol'
%                    };

sheet_names = {...'sum', 'ave_sum',...
               'std', 'mean', 'mean_times_vol', 'median', 'median_times_vol'
                   };

% read_M0_sheet = {'eASL_mean', 'eASL_mean', 'eASL_mean', 'eASL_mean', 'eASL_mean', 'eASL_mean',...
%            'CeASL_mean', 'CeASL_mean', 'CeASL_mean', 'CeASL_mean', 'CeASL_mean', 'CeASL_mean'};

read_M0_sheet = {'eASL_mean', 'eASL_mean', 'eASL_mean', 'eASL_mean', 'eASL_mean', 'eASL_mean'};

dataset = 'Visit 1';

for tis=1:numel(tissue_type)
    
    erode_size_arr = tissue_type{tis}.erode_size;
    for ei=1:numel(erode_size_arr)
        out_file_str = [tissue_type{tis}.name erode_size_arr{ei}];
        % workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal', ...
        %     ['combined_data_' out_file_str '_summed_delta_M.xlsx']);
        % workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', dataset, ...
        %     [out_file_str '_summed_delta_M.xlsx']);
        workbook = fullfile(stroke_impact_dir, 'Output/extract_summed_signal/newnew', ...
            [out_file_str '_summed_delta_M.xlsx']);
    
        % M0_source_dir = fullfile(onedrive, ['CE-ASL/Output/' dataset '_M0.xlsx']);
        M0_source_dir = fullfile(stroke_impact_dir, 'Output', 'M0.xlsx');
        
        for si=1:numel(sheet_names)
            M0_tbl = readtable(M0_source_dir, 'Sheet', read_M0_sheet{si}, 'ReadRowNames', true);

            tbl = readtable(workbook, 'Sheet', sheet_names{si}, 'VariableNamingRule', 'preserve');
            normalised_tbl = tbl;
            % if ismember(string(PLDs_eASL_PLD700), normalised_tbl.Properties.VariableNames)
            %     for i=string(PLDs_eASL_PLD700)
            %         normalised_tbl(:, i) = normalised_tbl(:, i) ./ M0_tbl{:, "M0_PLD700"};
            %     end
            % end
            % 
            % for i=string(PLDs_eASL_PLD1000)
            %     normalised_tbl(:, i) = normalised_tbl(:, i) ./ M0_tbl{:, "M0_PLD1000"};
            % end

            for i=string(PLDs)
                normalised_tbl(:, i) = normalised_tbl(:, i) ./ M0_tbl{normalised_tbl.Participant_ID, 'M0'};
            end
            normalised_sheetname = [sheet_names{si} '_normalised'];
            normalised_sheetname = normalised_sheetname(1:min(end, 31));
            writetable(normalised_tbl, workbook, 'Sheet', normalised_sheetname)
        end
    
        
    end
end