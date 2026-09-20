clear all

onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';
stroke_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');

%% clinical measure
MCI = struct('name', 'MCI', 'at_risk', 'Y', 'label', 'MCI', ...
    'control_label', 'NC', 'risk_label', 'MCI');
MoCA = struct('name', 'MoCA', 'at_risk', 25, 'label', 'MoCA', ...
    'control_label', 'MoCA>25', 'risk_label', 'MoCA\leq25');
Amyloid = struct('name', 'Amyloid', 'at_risk', 'Y', 'label', 'Amyloid', ...
    'control_label', 'Amyloid -', 'risk_label', 'Amyloid +');
QRisk = struct('name', 'QRISK category', 'at_risk', 'Y', 'label', 'QRisk', ...
    'control_label', 'QRisk low', 'risk_label', 'QRisk high');
clinical_measures = {MCI,...
    ...MoCA, 
    Amyloid, QRisk
    };

%% 
% roi_num_voxel_workbook = fullfile(onedrive, ...
%     'CE-ASL/Output/count_num_voxel/combined_data_num_voxel.xlsx');
roi_num_voxel_workbook = fullfile(onedrive, ...
    'CE-ASL/Output/count_num_voxel/SIDD_num_voxel.xlsx');
% roi_num_voxel_workbook = fullfile(stroke_impact_dir, 'Output/num_voxel.xlsx');
% roi_str = "lateral ventricles";
% roi_str = "choroid plexus";
% roi_str = "interior lateral ventricles";
roi_str_arr = {'lateral ventricles', 'inferior lateral ventricles'};
lbl_arr = {'LV', 'ILV'};

% roi_nc = readtable(roi_num_voxel_workbook, 'Sheet', 'NC', 'VariableNamingRule', 'preserve').(roi_str);
% roi_mci = readtable(roi_num_voxel_workbook, 'Sheet', 'MCI', 'VariableNamingRule', 'preserve').(roi_str);

% participant_details = readtable(fullfile(stroke_impact_dir, ...
%     'Stroke_Impact_Controls_MoCA.xlsx'), 'VariableNamingRule', 'preserve', ...
%     ReadRowNames=true);
% participant_details.Study_ID = cellfun(@(x) replace(x, '11189', '1189'), participant_details.Study_ID, 'UniformOutput', false);
% moca_scores = participant_details(:, ...
%     "MOCA_Normed_Total_Score_(1pt_added_to_raw_total_score_if_<_=12_years_of_educaion).x");
% 
roi_num_voxel_tbl = readtable(roi_num_voxel_workbook, 'VariableNamingRule', 'preserve', 'ReadRowNames', true);
ids_temp = cellfun(@(x) split(x, '_'), roi_num_voxel_tbl.Participant_ID, 'UniformOutput', false);
roi_num_voxel_tbl.Participant_ID = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);

% roi_num_voxel = roi_num_voxel_tbl(:, roi_str);
% roi_num_voxel = roi_num_voxel(roi_num_voxel.(roi_str)~=0 & ~isnan(roi_num_voxel.(roi_str)), :);
% common_ids = intersect(roi_num_voxel.Participant_ID, participant_details.Study_ID);
% 
% nc_ids = common_ids(~isnan(moca_scores{common_ids, :}) & moca_scores{common_ids, :} > 25);
% mci_ids = common_ids(~isnan(moca_scores{common_ids, :}) & moca_scores{common_ids, :} <= 25);
% 
% roi_nc = roi_num_voxel{nc_ids, :};
% roi_mci = roi_num_voxel{mci_ids, :};

%% Group ids
participant_details = readtable(fullfile(onedrive, ...
    'CE-ASL/ParticipantDetails.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);
id_list_source = fullfile(onedrive, "CE-ASL/Output/extract_summed_signal/newnew/SIDD_gm_0_9_summed_delta_M.xlsx");
id_list = readtable(id_list_source).Participant_ID;
ids_temp = cellfun(@(x) split(x, '_'), id_list, 'UniformOutput', false);
id_list = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);

control_ids = cell(numel(clinical_measures), 1);
risk_ids = cell(numel(clinical_measures), 1);
for i=1:numel(id_list)
    id = id_list{i};
    % Exclude data
    if strcmp(id, '15') || strcmp(id, '53')
        continue
    end
    % if strcmp(id, '27')
    %     continue
    % end

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

whole_brain = ["gm", "wm", "csf"];
% whole_brain = ["GM", "WM", "CSF"];

%%
for meas=1:numel(clinical_measures)
    ctrl_common_ids = intersect(control_ids{meas}, roi_num_voxel_tbl.Participant_ID);
    num_ctrl = numel(ctrl_common_ids);
    
    risk_common_ids = intersect(risk_ids{meas}, roi_num_voxel_tbl.Participant_ID);
    num_risk = numel(risk_common_ids);

    fig = figure;
    for tis=1:numel(roi_str_arr)
        roi_str = roi_str_arr{tis};
        roi_num_voxel = roi_num_voxel_tbl(:, roi_str);
        roi_num_voxel = roi_num_voxel(roi_num_voxel.(roi_str)~=0 & ~isnan(roi_num_voxel.(roi_str)), :);
        
        roi_ctrl = roi_num_voxel{ctrl_common_ids, :};
        roi_risk = roi_num_voxel{risk_common_ids, :};
    
        brain_volume_ctrl = zeros(size(roi_ctrl));
        brain_volume_risk = zeros(size(roi_risk));
        for roi=whole_brain
            % brain_volume_nc = brain_volume_nc + ...
            % readtable(roi_num_voxel_workbook, 'Sheet', 'NC', 'VariableNamingRule', 'preserve').(roi);
            % brain_volume_mci = brain_volume_mci + ...
            %     readtable(roi_num_voxel_workbook, 'Sheet', 'MCI', 'VariableNamingRule', 'preserve').(roi);
            brain_volume_ctrl = brain_volume_ctrl + roi_num_voxel_tbl{ctrl_common_ids,roi};
            brain_volume_risk = brain_volume_risk + roi_num_voxel_tbl{risk_common_ids,roi};
        end

        roi_ctrl = roi_ctrl ./ brain_volume_ctrl;
        roi_risk = roi_risk ./ brain_volume_risk;

        p_val = ranksum(roi_ctrl,roi_risk,"Tail","both", "method", "exact");
        if p_val < 0.001
            star= '***';
        elseif p_val < 0.01
            star = '**';
        elseif p_val < 0.05
            star = '*';
        else
            star = '';
        end
        
        all_data = [roi_ctrl; roi_risk];
        xGroup = [ones(length(roi_ctrl), 1);
                  ones(length(roi_risk), 1).*2];

        ax = subplot(1, numel(roi_str_arr), tis);
        ax.Box = 'on';
        hold(ax, 'on')
        title(ax, lbl_arr{tis})

        b = boxchart(ax, xGroup, all_data);

        names = {sprintf('%s (N=%d)', ...
                clinical_measures{meas}.control_label, num_ctrl), ...
                sprintf('%s (N=%d)', ...
                clinical_measures{meas}.risk_label, num_risk)};
        xticks(ax, 1:2)
        xticklabels(ax, names) 

        text(1.5, max(all_data, [], 'all')*1.1, star, 'HorizontalAlignment','center')
        ylim([0 max(all_data, [], 'all')*1.2])
        
        hold(ax, 'off')
        ylabel(ax,'Volume Fraction')
    end  
end

%%

MCI = struct('name', 'MCI', 'at_risk', 'Y', 'control_label', 'NC', 'atrisk_label', 'MCI');
MoCA = struct('name', 'MoCA', 'at_risk', 25, 'control_label', 'MoCA>25', 'atrisk_label', 'MoCA\leq25');
Amyloid = struct('name', 'Amyloid', 'at_risk', 'Y', 'control_label', 'Amyloid -', 'atrisk_label', 'Amyloid +');
QRisk = struct('name', 'QRISK category', 'at_risk', 'Y','control_label', 'QRisk low', 'atrisk_label', 'QRisk high');

dataset = 'combined_data';
calc_akaike_weights_combineddata_dir = fullfile(onedrive, ...
    'CE-ASL/Output/calc_akaike_weights/wider_grid/', dataset);

% read sbcm f and ttr for gm and wm, stcm for f and ttr for cp and lv
fit_set = 'prepost';
this_tis_name = 'choroid_plexus';
this_tis_name = 'lateral_ventricle';
% this_tis_name = 'gm';
% this_tis_name = 'wm';
model_name = 'SBCMpre_KBT1Bpost';
model_name = 'STCMpre_KBT1Bpost';
clinical_measures = {MCI};
for meas=1:numel(clinical_measures)
    model_name
    measure_name = clinical_measures{meas}.name
    this_tis_name
    path1 = fullfile(calc_akaike_weights_combineddata_dir, ...
        this_tis_name, clinical_measures{meas}.name, ...
        [fit_set '_control.xlsx']);
    path2 = fullfile(calc_akaike_weights_combineddata_dir, ...
        this_tis_name, measure_name, ...
        [fit_set '_at_risk.xlsx']);
    table1 = readtable(path1, 'Sheet', model_name, ReadRowNames=true);
    table2 = readtable(path2, 'Sheet', model_name, ReadRowNames=true);

    if ismember('15', table1.Participant_ID)
        table1('15',:) = [];
    end
    if ismember('15', table2.Participant_ID)
        table2('15',:) = [];
    end

    f_val_1 = table1.f;
    f_val_2 = table2.f;
    ttr_val_1 = table1.ttr;
    ttr_val_2 = table2.ttr;

    % disp('MCI')
    % [~,~,~,~,stats] = regress(roi_mci, ones(size(f_val_2,1),1))
    % disp('NC')
    % [~,~,~,~,stats] = regress(roi_nc, ones(size(f_val_1,1),1))


    figure
    subplot(1,2,1);
    hold on
    scatter(roi_risk, f_val_2, 'DisplayName', 'MCI')
    % scatter(roi_nc, f_val_1,'DisplayName', 'NC')
    xlabel('LV volume fraction')
    ylabel('LV f')
    legend
    hold off

    subplot(1,2,2);
    hold on
    scatter(roi_risk, ttr_val_2, 'DisplayName', 'MCI')
    % scatter(roi_nc, ttr_val_1,'DisplayName', 'NC' )
    xlabel('LV volume fraction')
    ylabel('LV t_A')
    legend
    hold off
end