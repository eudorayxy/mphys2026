clear all
tic

onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

participant_details = readtable(fullfile(onedrive, ...
    'CE-ASL/ParticipantDetails.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);

% dataset = 'Visit 1';
% read_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', dataset);
% id_list_source = fullfile(onedrive, "CE-ASL/Output/extract_roi_T1/", dataset, "gm_0_9.xlsx");
% id_list = readtable(id_list_source).Participant_ID;

strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
read_dir = fullfile(strokes_impact_dir, 'Output/extract_roi_T1');
id_list = readtable(fullfile(strokes_impact_dir, "data_log.csv")).id;
participant_details = readtable(fullfile(strokes_impact_dir, ...
    'Stroke_Impact_Controls_MoCA.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);
participant_details.Study_ID = cellfun(@(x) replace(x, '11189', '1189'), participant_details.Study_ID, 'UniformOutput', false);
common_ids = intersect(id_list, participant_details.Study_ID);
participant_details = participant_details(common_ids,:);
id_list = common_ids;
%%
% lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
%     'erode_size', {{'_mask',...
%     'erode_size1_corrected_mask', 'erode_size2_corrected_mask', ...
%     'erode_size3_corrected_mask', 'erode_size4_corrected_mask', ...
%     'erode_size5_corrected_mask'
%     }}, 'erode_size_mm', 0:5, 'ylim', [3.85 5.25]);
% choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
%     'erode_size', {{'_mask',...
%     'erode_size1_corrected_mask'
%     }},'erode_size_mm', [0 1], 'ylim', [2.3 2.735]);

lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
    'erode_size', {{'_mask',...
    '_erode1mm', '_erode2mm', '_erode3mm', '_erode4mm', '_erode5mm'
    }}, 'erode_size_mm', 0:5, 'ylim', [3.85 5.25]);
choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
    'erode_size', {{'_mask', '_erode1mm'
    }},'erode_size_mm', [0 1], 'ylim', [2.3 2.735]);

tissue_type = {lateral_ventricle, choroid_plexus};

% MCI = struct('name', 'MCI', 'at_risk', 'Y', 'label', 'MCI', ...
%     'control_label', 'NC', 'risk_label', 'MCI');
% MoCA = struct('name', 'MoCA', 'at_risk', 25, 'label', 'MoCA', ...
%     'control_label', 'MoCA>25', 'risk_label', 'MoCA\leq25');
MoCA = struct('name', ...
    'MOCA_Normed_Total_Score_(1pt_added_to_raw_total_score_if_<_=12_years_of_educaion).x', ...
    'at_risk', 25, 'label', 'MoCA', ...
    'control_label', 'MoCA>25', 'risk_label', 'MoCA\leq25');
% Amyloid = struct('name', 'Amyloid', 'at_risk', 'Y', 'label', 'Amyloid', ...
%     'control_label', 'Amyloid -', 'risk_label', 'Amyloid +');
% QRisk = struct('name', 'QRISK category', 'at_risk', 'Y', 'label', 'QRisk', ...
%     'control_label', 'low QRisk', 'risk_label', 'high QRisk');
clinical_measures = {...MCI,
    MoCA, ...Amyloid, QRisk
    };

subplot_num_row = 4;
subplot_num_column = 4;

for tis=1:numel(tissue_type)

    erode_size_arr = tissue_type{tis}.erode_size;
    erosion_size = tissue_type{tis}.erode_size_mm;
    
    % get an array of T1 vs erode size
    mean_T1_vs_erode_size_tbl = [];
    std_T1_vs_erode_size_tbl = [];
    for ei=1:numel(erode_size_arr)
        out_file_str = [tissue_type{tis}.name erode_size_arr{ei}];
        read_workbook = fullfile(read_dir, [out_file_str '.xlsx']);
        mean_tbl = readtable(read_workbook, 'Sheet', 'mean', 'ReadRowNames', true)./1000;
        std_tbl = readtable(read_workbook, 'Sheet', 'std', 'ReadRowNames', true)./1000;

        mean_tbl.Properties.VariableNames = {num2str(tissue_type{tis}.erode_size_mm(ei))};
        std_tbl.Properties.VariableNames = {num2str(tissue_type{tis}.erode_size_mm(ei))};

        mean_T1_vs_erode_size_tbl = [mean_T1_vs_erode_size_tbl mean_tbl];
        std_T1_vs_erode_size_tbl = [std_T1_vs_erode_size_tbl std_tbl];
    end

    control_ids = cell(numel(clinical_measures), 1);
    risk_ids = cell(numel(clinical_measures), 1);
    count = 0;
    count_fig = 1;
    for i=1:numel(id_list)
        % id = split(char(id_list{i}), '_');
        % id = strip(id{1}, 'left', '0');

        id = split(char(id_list{i}), '-');
        id = strip(id{end}, 'left', '0')
        
        % count = count+1;
        % if count == 1
        %     fig = figure;
        %     tiled = tiledlayout(subplot_num_row, subplot_num_column, "Parent", fig,...
        %     "TileSpacing","tight", "Padding","tight");
        %     sgtitle(fig, tissue_type{tis}.name)
        % elseif mod(i-1, subplot_num_column*subplot_num_row) == 0
        %     count = 1;
        %     fig = figure;
        %     tiled = tiledlayout(subplot_num_row, subplot_num_column, "Parent", fig,...
        %         "TileSpacing","tight", "Padding","tight");
        %     sgtitle(fig, tissue_type{tis}.name)
        % end
        % 
        % ax = nexttile(tiled);
        % hold(ax, 'on')
        % title(ax, id)
        % xlabel(ax, 'erosion radius (mm)')
        % ylabel(ax, 'T_1 (s)')
        % xlim(ax, [erosion_size(1)-0.5, erosion_size(end)+0.5])
        % yline(ax, mean(mean_T1_vs_erode_size_tbl{i, :}), '--')
        % errorbar(ax, erosion_size, ...
        %     mean_T1_vs_erode_size_tbl{i, :}, std_T1_vs_erode_size_tbl{i, :}, ...
        %   'Marker', 'x',...
        %   'LineStyle', 'none', 'HandleVisibility', 'off')
        % 
        % hold(ax, 'off')

        % exclude data
        % if strcmp(id, '15') || strcmp(id, '53')
        %     continue
        % end
        if strcmp(id, '27')
            continue
        end
    
        person_details_table = participant_details(id_list{i}, :);
        details_header = person_details_table.Properties.VariableNames;

        for meas=1:numel(clinical_measures)
            this_struct_name = clinical_measures{meas}.name;
            this_struct_risk = clinical_measures{meas}.at_risk;
            
            if ismember(this_struct_name, details_header)
                content = person_details_table.(this_struct_name);
                if iscell(content)
                    content = char(content);
                    is_at_risk = strcmp(content, this_struct_risk);
                elseif isnumeric(content) 
                    is_at_risk = content <= this_struct_risk;
                end
                    
                if ~strcmp(content,'N/A') && ~all(isnan(content)) && ~strcmp(content,'NA')
                    if is_at_risk
                        risk_ids{meas}{end+1} = id_list{i};
                    else
                        control_ids{meas}{end+1} = id_list{i};
                    end
                end
            else
                fprintf('\n%s not available', this_struct_name)
            end
        end % End of loop over clinical measures
    end % End of loop over id

    figure
    sgtitle(tissue_type{tis}.name)
    nan_present_ids = mean_T1_vs_erode_size_tbl(any(isnan(mean_T1_vs_erode_size_tbl{:, :}), 2),:).Participant_ID

    for meas=1:numel(clinical_measures)
        ax = subplot(1,numel(clinical_measures),meas);
        hold(ax, 'on')
        xlabel(ax, 'erosion radius (mm)')
        if meas == 1
        ylabel(ax, 'T_1 (s)')
        end
        title(ax, clinical_measures{meas}.label)

        c_ids = setdiff(control_ids{meas}, nan_present_ids)
        r_ids = setdiff(risk_ids{meas}, nan_present_ids)
        num_ctrl = numel(c_ids);
        num_risk = numel(r_ids);
        control_T1 = mean(mean_T1_vs_erode_size_tbl{c_ids, :}, 'omitnan');
        se_control = std(mean_T1_vs_erode_size_tbl{c_ids, :}, 'omitnan') / sqrt(num_ctrl);
        risk_T1 = mean(mean_T1_vs_erode_size_tbl{r_ids, :}, 'omitnan');
        se_risk = std(mean_T1_vs_erode_size_tbl{r_ids, :}, 'omitnan') / sqrt(num_risk);

        errorbar(ax, erosion_size, control_T1, se_control, ...
            'Marker', 'x', 'Color', 'b', 'LineStyle', 'none', ...
            'DisplayName', [clinical_measures{meas}.control_label ' (N=' num2str(num_ctrl) ')'])
        errorbar(ax, erosion_size, risk_T1, se_risk, ...
            'Marker', 'x', 'Color', 'r', 'LineStyle', 'none', ...
            'DisplayName', [clinical_measures{meas}.risk_label ' (N=' num2str(num_risk) ')'])
        xlim(ax, [erosion_size(1)-0.5 erosion_size(end)+0.5])
        grid on
        % ylim(ax, tissue_type{tis}.ylim)
        legend(ax, 'show', 'Location', 'best')
        hold(ax, 'off')
    end
end


toc