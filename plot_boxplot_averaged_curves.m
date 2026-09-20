clear all;
onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

set(groot, 'DefaultAxesFontSize', 13)
set(groot, 'DefaultTextFontSize', 13)
set(groot, 'DefaultLegendFontSize', 13)
set(groot, 'DefaultAxesFontName', 'Arial')
set(groot, 'DefaultTextFontName', 'Arial')
set(groot, 'DefaultLineLineWidth', 1.5)
set(groot, 'DefaultScatterSizeData', 80)

tissue_prob = '0_9';
fitNames = {'f', 'tA', 'k'
    };
ylabels = {'F (mL/s)', 't_A (s)' , 'k_{out} (s^{-1})'
    };

% models
SBCM = struct('name', 'SBCM', 'label', 'SBCM');
STCM = struct('name', 'STCM', 'label', 'STCM');
STCM_csf = struct('name', 'STCM_LV', 'label', 'STCM\newline+outflow');
% STCM_csf = struct('name', 'STCM_LV', 'label', 'STCM+outflow');
TCM = struct('name', 'TCM', 'label', 'TCM');
CPLV = struct('name', 'CP_LV', 'label', 'blood-\newlineCP-LV');

%% GE scans
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
LD_arr = [0.573 0.885 2.042];
PLD = sort([PLDs_eASL_PLD1000 PLDs_eASL_PLD700]) ./ 1000; % seconds
LD = sort([LD_arr LD_arr]);

gm = struct('name', 'gm', 'label', 'GM', 'erode_size', ['_' tissue_prob], ...
    'model', {{SBCM, STCM, TCM}});
wm = struct('name', 'wm','label', 'WM', 'erode_size', ['_' tissue_prob], ...
    'model', {{SBCM, STCM, TCM}});
lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
    'erode_size', 'erode_size3_corrected_mask', ...
    'model', {{STCM, STCM_csf, CPLV}});
choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
    'erode_size', 'erode_size1_corrected_mask', ...
    'model', {{SBCM, STCM, TCM}});
inf_lateral_ventricle = struct('name', 'inferior lateral ventricles', 'label', 'ILV', ...
    'erode_size', 'erode_size1_corrected_mask', ...
    'model', {{STCM, STCM_csf, CPLV}});

calc_akaike_weights_dir = fullfile(onedrive, ...
    'CE-ASL/Output/calc_akaike_weights_centralT1');
participant_details = readtable(fullfile(onedrive, ...
    'CE-ASL/ParticipantDetails.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);
id_list_source = fullfile(onedrive, "CE-ASL/Output/extract_summed_signal/newnew/SIDD_gm_0_9_summed_delta_M.xlsx");
id_list = readtable(id_list_source).Participant_ID;
ids_temp = cellfun(@(x) split(x, '_'), id_list, 'UniformOutput', false);
id_list = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);

% MCI = struct('name', 'MCI', 'at_risk', 'Y', 'label', 'MCI', ...
%     'control_label', 'NC', 'risk_label', 'MCI');
MCI = struct('name', 'MCI', 'at_risk', 'Y', 'label', 'Cognitive status', ...
    'control_label', 'NC', 'risk_label', 'MCI');
MoCA = struct('name', 'MoCA', 'at_risk', 25, 'label', 'MoCA', ...
    'control_label', '>25', 'risk_label', '\leq25');
Amyloid = struct('name', 'Amyloid', 'at_risk', 'Y', 'label', 'Amyloid', ...
    'control_label', '-', 'risk_label', '+');
QRisk = struct('name', 'QRISK category', 'at_risk', 'Y', 'label', 'QRisk', ...
    'control_label', 'low', 'risk_label', 'high');

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
write_dir = fullfile(onedrive, 'CE-ASL/Output/plot_boxplot_averaged_curves');
%% Philips scans
% PLD = [890 1300 1700 2100 2500] ./ 1000; % seconds
% LD = 1.8 * ones(size(PLD));
% 
% gm = struct('name', 'GM', 'label', 'GM', 'erode_size', ['_' tissue_prob], ...
%     'model', {{SBCM, STCM, TCM}});
% wm = struct('name', 'WM','label', 'WM', 'erode_size', ['_' tissue_prob], ...
%     'model', {{SBCM, STCM, TCM}});
% lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
%     'erode_size','_erode3mm',  ...
%     'model', {{STCM, STCM_csf}});
% choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
%     'erode_size','_erode1mm', ...
%     'model', {{SBCM, STCM, TCM}});
% 
% strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
% calc_akaike_weights_dir = fullfile(strokes_impact_dir, 'Output/calc_akaike_weights_centralT1');
% participant_details = readtable(fullfile(strokes_impact_dir, ...
%     'Stroke_Impact_Controls_MoCA.xlsx'), 'VariableNamingRule', 'preserve', ...
%     ReadRowNames=true);
% ids_temp = cellfun(@(x) split(x, '-'), participant_details.Study_ID, 'UniformOutput', false);
% participant_details.Study_ID = cellfun(@(x) strip(x{end}, 'left', '0'), ids_temp, 'UniformOutput', false);
% 
% id_list = readtable(fullfile(strokes_impact_dir, "data_log.csv")).id;
% ids_temp = cellfun(@(x) split(x, '-'), id_list, 'UniformOutput', false);
% id_list = cellfun(@(x) strip(x{end}, 'left', '0'), ids_temp, 'UniformOutput', false);
% 
% common_ids = intersect(id_list, participant_details.Study_ID);
% participant_details = participant_details(common_ids,:);
% id_list = common_ids;
% 
% MoCA = struct('name', ...
%     'MOCA_Normed_Total_Score_(1pt_added_to_raw_total_score_if_<_=12_years_of_educaion).x', ...
%     'at_risk', 25, 'label', 'MoCA', ...
%     'control_label', '>25', 'risk_label', '\leq25');
% 
% clinical_measures = {MoCA
%     };
% 
% write_dir = fullfile(strokes_impact_dir, 'Output/plot_boxplot_averaged_curves');
%%

if ~isfolder(write_dir)
    mkdir(write_dir)
end

gm.selected_model = SBCM;
wm.selected_model = SBCM;
choroid_plexus.selected_model = SBCM;
lateral_ventricle.selected_model = STCM_csf;
inf_lateral_ventricle.selected_model = STCM;

read_sheet = 'median_times_vol_normalised';
read_sheet = 'median_normalised';
% read_sheet = 'mean_times_vol_normalised';
tissue_type = {gm, wm, ...
    choroid_plexus, ...
   ... lateral_ventricle, inf_lateral_ventricle
    };
%% Group ids
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

%% Plot Boxplots
for meas=1:numel(clinical_measures)
    write_png = fullfile(write_dir, sprintf('%s %s.png', read_sheet, ...
        clinical_measures{meas}.label));
    fig = figure;
    tiled = tiledlayout(fig, 7, numel(tissue_type), ...
        'Padding', 'compact', 'TileSpacing', 'tight');
    % title(tiled, replace(read_sheet, '_', '\_'))
       
    for fi=1:numel(fitNames)

        multiply_6000 = false;
        if fi == 1 && ~contains(read_sheet, 'times_vol')
            multiply_6000 = true;

        end
        y_min = inf;
        y_max = -inf;
        ax_holder = cell(1, numel(tissue_type));
        for tis=1:numel(tissue_type)
            tissue_type_struct = tissue_type{tis};
            out_file_str = [tissue_type{tis}.name tissue_type{tis}.erode_size];
            read_workbook = fullfile(calc_akaike_weights_dir, out_file_str, ...
                [read_sheet '_model_results.xlsx']);

            all_data = [];
            xGroup = [];
            colorGroup = [];
            stars_arr = cell(1, numel(tissue_type_struct.model));
            this_ax_ymax_arr = nan(1, numel(tissue_type_struct.model));
            names = cell(1,numel(tissue_type_struct.model));
   
            for mi=1:numel(tissue_type_struct.model)
                names{mi} = replace(tissue_type_struct.model{mi}.name, '_', '\_');
        
                tbl = readtable(read_workbook, 'Sheet', ...
                    tissue_type_struct.model{mi}.name, ...
                    'ReadRowNames', true);

                common_ids = intersect(control_ids{meas}, tbl.Participant_ID);
                ctrl = tbl{common_ids, fitNames{fi}};
                common_ids = intersect(risk_ids{meas}, tbl.Participant_ID);
                risk = tbl{common_ids, fitNames{fi}};

                if multiply_6000
                    ctrl = ctrl.*6000;
                    risk = risk.*6000;
                    ylabels{fi} = 'f (mL/min/100mL)';
                end

                num_ctrl = length(ctrl);
                num_risk = length(risk);

                if ~all(isnan(ctrl), 'all') && ~all(isnan(risk), 'all')
                    ymax_1 = max(ctrl, [], 'all', 'omitnan');
                    ymax_2 = max(risk, [], "all", "omitnan");
                    y_max = max(ymax_1, y_max);
                    y_max = max(ymax_2, y_max);
                    y_min = min(min(ctrl, [], 'all', 'omitnan'), y_min);
                    y_min = min(min(risk, [], 'all', 'omitnan'), y_min);
                    
                    this_ax_ymax_arr(mi) = max(ymax_1, ymax_2) * 1.1;

                    p_val = ranksum(ctrl,risk,"Tail","both", "method","exact");
                    fprintf('%s %s %s p=%.4f\n', ...
                        tissue_type{tis}.label, ...
                        tissue_type{tis}.model{mi}.name, ...
                        fitNames{fi}, p_val)
                    if p_val < 0.001
                        % stars_arr{si} = sprintf('***\n%.4f', p_val);
                        stars_arr{mi} = '***';
                    elseif p_val < 0.01
                        % stars_arr{si} = sprintf('**\n%.3f', p_val);
                        stars_arr{mi} = '**';
                    elseif p_val < 0.05
                        % stars_arr{si} = sprintf('*\n%.3f', p_val);
                        stars_arr{mi} = '*';
                    else
                        stars_arr{mi} = '';
                    end  
                end
                all_data = [all_data; ctrl; risk];
                xGroup = [xGroup;
                    repmat(mi, num_ctrl, 1);
                    repmat(mi, num_risk, 1)];
                colorGroup = [colorGroup;
                        repmat(sprintf("%s (N=%d)", ...
                        clinical_measures{meas}.control_label, num_ctrl), num_ctrl, 1);
                        repmat(sprintf("%s (N=%d)", ...
                        clinical_measures{meas}.risk_label, num_risk), num_risk, 1)];
            end % End of loop over models

            if isnan(all_data)
                continue
            end

            if fi == 1
                ax = nexttile(tiled, [3,1]);
            else
                ax = nexttile(tiled, [2,1]);
            end
            ax.Box = 'on';
            hold(ax, 'on')

            b = boxchart(ax, xGroup, all_data, 'GroupByColor', colorGroup);
            fprintf('\n%s\n', tissue_type{tis}.name)

            for k = 1:numel(b)
                fprintf('%s\n', b(k).DisplayName)
                disp(b(k).BoxFaceColor)
            end

            xticks(ax, 1:numel(tissue_type_struct.model))
            xticklabels(ax, names) 
            if tis == 1
                ylabel(ax, ylabels{fi})
            elseif tis == numel(tissue_type)
                yyaxis(ax, "left")
                yticklabels(ax, {})
                yyaxis(ax, "right")
                % ax.YAxisLocation = 'right';
            else
                yticklabels(ax, {})
            end
            ax_holder{tis} = ax;
            text(ax, 1:numel(tissue_type_struct.model), ...
                this_ax_ymax_arr, stars_arr, "HorizontalAlignment","center")
            hold(ax, 'off')
            if fi == 1
                title(ax, tissue_type{tis}.label)
                leg = legend(ax, 'show', 'Location', 'northeast', 'NumColumns', 1);
                title(leg, clinical_measures{meas}.label)
            end
        end % End of loop over tissue types

        y_max = y_max * 1.2;
        for tis=1:numel(tissue_type)
            if isempty(ax_holder{tis})
                continue
            end

            if tis ~= numel(tissue_type)
                if fi == 1
                    ylim(ax_holder{tis}, [y_min y_max + (y_max - y_min)/3])
                else
                    ylim(ax_holder{tis}, [y_min y_max])
                end
            else
                 if fi == 1
                    yyaxis left
                    ylim(ax_holder{tis}, [y_min y_max + (y_max - y_min)/3])
                    ax.YColor = 'k';
                    yyaxis right
                    ylim(ax_holder{tis}, [y_min y_max + (y_max - y_min)/3])
                    ax.YColor = 'k';
                 else
                    yyaxis left
                    ylim(ax_holder{tis}, [y_min y_max])
                    ax.YColor = 'k';

                    yyaxis right
                    ylim(ax_holder{tis}, [y_min y_max])
                    ax.YColor = 'k';
                 end
            end

        end % End of loop over tissue types (format ylim etc)
    end % End of loop over f, tA, k
    exportgraphics(fig, write_png, 'Resolution', 300)
end % End of loop over clinical measures

%% Plot Boxplots (ungrouped)
write_png = fullfile(write_dir, sprintf('%s_boxplot_ungrouped.png', read_sheet));
fig = figure;
% n_col =  numel(fitNames);
% n_row = numel(tissue_type);
% tiled = tiledlayout(fig, n_row, n_col);

n_row = numel(fitNames);
n_col = numel(tissue_type);
tiled = tiledlayout(fig, n_row, n_col, 'Padding', 'compact', 'TileSpacing', 'tight' ...
    );
% title(tiled, replace(read_sheet, '_', '\_'))
       
for fi=1:numel(fitNames)

    multiply_6000 = false;
    if fi == 1 && ~contains(read_sheet, 'times_vol')
        multiply_6000 = true;

    end
    y_min = inf;
    y_max = -inf;
    ax_holder = cell(1, numel(tissue_type));
    for tis=1:numel(tissue_type)
        tissue_type_struct = tissue_type{tis};
        out_file_str = [tissue_type{tis}.name tissue_type{tis}.erode_size];
        read_workbook = fullfile(calc_akaike_weights_dir, out_file_str, ...
            [read_sheet '_model_results.xlsx']);

        all_data = [];
        xGroup = [];
        names = cell(1,numel(tissue_type_struct.model));

        for mi=1:numel(tissue_type_struct.model)
            names{mi} = replace(tissue_type_struct.model{mi}.label, '_', '\_');
    
            tbl = readtable(read_workbook, 'Sheet', ...
                tissue_type_struct.model{mi}.name, ...
                'ReadRowNames', true);
            
            tbl('15', :) = [];
            tbl('53', :) = [];
            fit_param = tbl{:, fitNames{fi}};

            if multiply_6000
                fit_param = fit_param.*6000;
                ylabels{fi} = 'f (mL/min/100mL)';
            end

            if ~all(isnan(fit_param), 'all')
                ymax_1 = max(fit_param, [], 'all', 'omitnan');
                y_max = max(ymax_1, y_max);
                y_min = min(min(fit_param, [], 'all', 'omitnan'), y_min);
                
            end
            all_data = [all_data; fit_param];
            xGroup = [xGroup;
                repmat(mi, numel(fit_param), 1)];
        end % End of loop over models

        if isnan(all_data)
            continue
        end

        ax = nexttile(tiled)
        ax.Box = 'on';
        hold(ax, 'on')

        b = boxchart(ax, xGroup, all_data);
        fprintf('\n%s\n', tissue_type{tis}.name)

        xticks(ax, 1:numel(tissue_type_struct.model))
        xticklabels(ax, names) 
        % if tis == 1
            ylabel(ax, ylabels{fi})
        % elseif tis == numel(tissue_type)
        %     yyaxis(ax, "left")
        %     yticklabels(ax, {})
        %     yyaxis(ax, "right")
        %     % ax.YAxisLocation = 'right';
        % else
        %     yticklabels(ax, {})
        % end

        if fi == 1
            title(ax, tissue_type{tis}.label)
        end
        ax_holder{tis} = ax;
        hold(ax, 'off')
    end % End of loop over tissue types

    y_max = y_max * 1.2;
    for tis=1:numel(tissue_type)
        if isempty(ax_holder{tis})
            continue
        end

        % if tis ~= numel(tissue_type)
        %     ylim(ax_holder{tis}, [y_min y_max])
        % else
        %     yyaxis left
        %     ylim(ax_holder{tis}, [y_min y_max])
        %     ax.YColor = 'k';
        % 
        %     yyaxis right
        %     ylim(ax_holder{tis}, [y_min y_max])
        %     ax.YColor = 'k';
        % end
    end % End of loop over tissue types (format ylim etc)
end % End of loop over f, tA, k
exportgraphics(fig, write_png, 'Resolution', 300)

%% Plot Boxplots (selected model)
write_outlier_workbook = fullfile(write_dir, [read_sheet ' outlier.xlsx']); 
for meas=1:numel(clinical_measures)
    write_png = fullfile(write_dir, sprintf('%s %s_boxplot_selected.png', read_sheet, ...
        clinical_measures{meas}.label));
    fig = figure;
    % tiled = tiledlayout(fig, 7, numel(tissue_type), ...
    %     'Padding', 'compact', 'TileSpacing', 'tight');

    % n_col =  numel(fitNames);
    % n_row = numel(tissue_type);
    
    n_row = numel(fitNames);
    n_col = numel(tissue_type);
    tiled = tiledlayout(fig, n_row, n_col, 'Padding', 'compact', 'TileSpacing', 'tight' ...
        );
    % title(tiled, replace(read_sheet, '_', '\_'))
       
    for fi=1:numel(fitNames)

        multiply_6000 = false;
        if fi == 1 && ~contains(read_sheet, 'times_vol')
            multiply_6000 = true;

        end
        y_min = inf;
        y_max = -inf;
        ax_holder = cell(1, numel(tissue_type));
        for tis=1:numel(tissue_type)
            tissue_type_struct = tissue_type{tis};
            out_file_str = [tissue_type{tis}.name tissue_type{tis}.erode_size];
            read_workbook = fullfile(calc_akaike_weights_dir, out_file_str, ...
                [read_sheet '_model_results.xlsx']);

            all_data = [];
            xGroup = [];
   
            tbl = readtable(read_workbook, 'Sheet', ...
                tissue_type_struct.selected_model.name, ...
                'ReadRowNames', true);

            control_common_ids = intersect(control_ids{meas}, tbl.Participant_ID);
            ctrl = tbl{control_common_ids, fitNames{fi}};
            
            risk_common_ids = intersect(risk_ids{meas}, tbl.Participant_ID);
            risk = tbl{risk_common_ids, fitNames{fi}};

            if multiply_6000
                ctrl = ctrl.*6000;
                risk = risk.*6000;
                ylabels{fi} = 'f (mL/min/100mL)';
            end
            
            num_ctrl = length(ctrl);
            num_risk = length(risk);
            
            % % Find outliers: >3 SD from the group mean
            % mean_ctrl = mean(ctrl, 'omitnan')
            % std_ctrl = std(ctrl, 'omitnan')
            % iqr_ctrl = iqr(ctrl);
            % mean_risk = mean(risk, 'omitnan')
            % std_risk = std(risk, 'omitnan')
            % outlier_ctrl_mask = abs(ctrl - mean_ctrl) > 3*std_ctrl;
            % outlier_risk_mask = abs(risk - mean_risk) > 3*std_risk;
           
            Q1_ctrl = quantile(ctrl, 0.25);
            Q3_ctrl = quantile(ctrl, 0.75);
            IQR_val_ctrl = Q3_ctrl - Q1_ctrl;
            outlier_ctrl_mask = ctrl < Q1_ctrl - 1.5*IQR_val_ctrl | ...
                           ctrl > Q3_ctrl + 1.5*IQR_val_ctrl;
            Q1_risk = quantile(risk, 0.25);
            Q3_risk = quantile(risk, 0.75);
            IQR_val_risk = Q3_risk - Q1_risk;
            outlier_risk_mask = risk < Q1_risk - 1.5*IQR_val_risk | ...
                           risk > Q3_risk + 1.5*IQR_val_risk;
            
            % Return the corresponding rows as a table
            outlier_ctrl = tbl(control_common_ids(outlier_ctrl_mask), fitNames{fi})
            outlier_risk = tbl(risk_common_ids(outlier_risk_mask), fitNames{fi})
            if ~isempty(outlier_ctrl)
                writetable(outlier_ctrl, write_outlier_workbook, ...
                    'Sheet', sprintf('%s_%s_ctrl_%s', tissue_type_struct.selected_model.name, ...
                    clinical_measures{meas}.label, fitNames{fi}), 'WriteRowNames', true)
            end
            if ~isempty(outlier_risk)
                writetable(outlier_risk, write_outlier_workbook, ...
                    'Sheet', sprintf('%s_%s_risk_%s', tissue_type_struct.selected_model.name, ...
                    clinical_measures{meas}.label, fitNames{fi}), 'WriteRowNames', true)
            end

            % filtered parameters
            filtered_ctrl = ctrl(~outlier_ctrl_mask);
            filtered_risk = risk(~outlier_risk_mask);

            if ~all(isnan(ctrl), 'all') && ~all(isnan(risk), 'all')
                ymax_1 = max(ctrl, [], 'all', 'omitnan');
                ymax_2 = max(risk, [], "all", "omitnan");
                y_max = max(ymax_1, y_max);
                y_max = max(ymax_2, y_max);
                y_min = min(min(ctrl, [], 'all', 'omitnan'), y_min);
                y_min = min(min(risk, [], 'all', 'omitnan'), y_min);
                
                this_ax_ymax_arr = max(ymax_1, ymax_2) * 1.1;

                p_val = ranksum(ctrl,risk,"Tail","both", "method","exact");
                fprintf('%s %s %s p=%.4f\n', ...
                    tissue_type{tis}.label, ...
                    tissue_type{tis}.selected_model.name, ...
                    fitNames{fi}, p_val)
                if p_val < 0.001
                    % stars_arr{si} = sprintf('***\n%.4f', p_val);
                    stars = '***';
                elseif p_val < 0.01
                    % stars_arr{si} = sprintf('**\n%.3f', p_val);
                    stars = '**';
                elseif p_val < 0.05
                    % stars_arr{si} = sprintf('*\n%.3f', p_val);
                    stars = '*';
                else
                    stars = 'ns';
                end  

                p_val_filtered = ranksum(filtered_ctrl, filtered_risk,"Tail","both", "method","exact");
                if p_val_filtered < 0.001
                    stars_filtered = '***';
                elseif p_val_filtered < 0.01
                    stars_filtered = '**';
                elseif p_val_filtered < 0.05
                    stars_filtered = '*';
                else
                    stars_filtered = 'ns';
                end  
            end
            
            all_data = [all_data; ctrl; risk];
            xGroup = [xGroup;
                ones(num_ctrl, 1);
                ones(num_risk, 1).*2];
            names = {sprintf('%s (N=%d)', ...
                    clinical_measures{meas}.control_label, num_ctrl), ...
                    sprintf('%s (N=%d)', ...
                    clinical_measures{meas}.risk_label, num_risk)};

            if isnan(all_data)
                continue
            end

            ax = nexttile(tiled);
            ax.Box = 'on';
            hold(ax, 'on')

            b = boxchart(ax, xGroup, all_data);
            fprintf('\n%s\n', tissue_type{tis}.name)

            xticks(ax, 1:2)
            xticklabels(ax, names)

            % if tis == 1
                ylabel(ax, ylabels{fi})
            % elseif tis == numel(tissue_type)
            %     yyaxis(ax, "left")
            %     yticklabels(ax, {})
            %     yyaxis(ax, "right")
            %     % ax.YAxisLocation = 'right';
            % else
            %     yticklabels(ax, {})
            % end
            ax_holder{tis} = ax;
            text(ax, 1.5, ...
                this_ax_ymax_arr, [stars '/' stars_filtered], "HorizontalAlignment","center")
            hold(ax, 'off')
            if fi == 1
                title(ax, tissue_type{tis}.label)
                % leg = legend(ax, 'show', 'Location', 'northeast', 'NumColumns', 1);
                % title(leg, clinical_measures{meas}.label)
            end
            ylim(ax, [y_min this_ax_ymax_arr*1.1])
        end % End of loop over tissue types

        y_max = y_max * 1.3;
        for tis=1:numel(tissue_type)
            if isempty(ax_holder{tis})
                continue
            end

            if tis ~= numel(tissue_type)

                ylim(ax_holder{tis}, [y_min y_max])

            else

                yyaxis left
                ylim(ax_holder{tis}, [y_min y_max])
                ax.YColor = 'k';

                yyaxis right
                ylim(ax_holder{tis}, [y_min y_max])
                ax.YColor = 'k';

            end

        end % End of loop over tissue types (format ylim etc)
    end % End of loop over f, tA, k
    exportgraphics(fig, write_png, 'Resolution', 300)
end % End of loop over clinical measures


%% Plot averaged curves
fig_deltaM = figure;
n_row = numel(clinical_measures); n_col = numel(tissue_type);
tiled = tiledlayout(fig_deltaM, n_row, n_col, "TileSpacing", "tight", "Padding", "tight");
% title(tiled, replace(read_sheet, '_', '\_'))

lightBlue = [0.4 0.7 1.0];   % Light blue
lightRed  = [1.0 0.6 0.6];   % Light red

for meas=1:numel(clinical_measures)
    control_lbl = clinical_measures{meas}.control_label;
    risk_lbl = clinical_measures{meas}.risk_label;

    write_png = fullfile(write_dir, sprintf('%s asl_signal.png', read_sheet));
      
    y_min = inf;
    y_max = -inf;
    ax_holder = cell(1, numel(tissue_type));
    for tis=1:numel(tissue_type)
        tissue_type_struct = tissue_type{tis};
        out_file_str = [tissue_type{tis}.name tissue_type{tis}.erode_size];

        this_model = tissue_type_struct.selected_model;
        % fit
        fit_workbook = fullfile(calc_akaike_weights_dir, out_file_str, ...
            [read_sheet '_delta_M.xlsx']);
        fit_deltaM = readtable(fit_workbook, ...
            'Sheet', this_model.name, ...
            'VariableNamingRule', 'preserve', 'ReadRowNames', true);

        ctrl_common_ids = intersect(control_ids{meas}, fit_deltaM.Participant_ID);
        num_ctrl_fit = numel(ctrl_common_ids);
        deltaM_ctrl_mean = mean(fit_deltaM{ctrl_common_ids, :});
        se_deltaM_ctrl = std(fit_deltaM{ctrl_common_ids, :}) ./ sqrt(num_ctrl_fit);

        risk_common_ids = intersect(risk_ids{meas}, fit_deltaM.Participant_ID);
        num_risk_fit = numel(risk_common_ids);
        deltaM_risk_mean = mean(fit_deltaM{risk_common_ids, :});
        se_deltaM_risk = std(fit_deltaM{risk_common_ids, :}) ./ sqrt(num_risk_fit);

        % real data 
        % GE scan
        data_workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', ...
            ['SIDD_' out_file_str '_summed_delta_M.xlsx']);
        data = readtable(data_workbook, 'Sheet', read_sheet, ...
                'VariableNamingRule', 'preserve', 'ReadRowNames', true);
        ids_temp = cellfun(@(x) split(x, '_'), data.Participant_ID, 'UniformOutput', false);
        data.Participant_ID = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);

        % Philips scan
        % data_workbook = fullfile(strokes_impact_dir, 'Output/extract_summed_signal/newnew', ...
        %     [out_file_str '_summed_delta_M.xlsx']);
        % data = readtable(data_workbook, 'Sheet', read_sheet, ...
        %         'VariableNamingRule', 'preserve', 'ReadRowNames', true);
        % ids_temp = cellfun(@(x) split(x, '-'), data.Participant_ID, 'UniformOutput', false);
        % data.Participant_ID = cellfun(@(x) strip(x{end}, 'left', '0'), ids_temp, 'UniformOutput', false);

        data_ctrl = mean(data{ctrl_common_ids, :});
        se_data_ctrl = std(data{ctrl_common_ids, :}) ./ sqrt(num_ctrl_fit);
        data_risk = mean(data{risk_common_ids, :});
        se_data_risk = std(data{risk_common_ids, :}) ./ sqrt(num_risk_fit);

        ax_deltaM = nexttile(tiled);
        box(ax_deltaM, 'on')

        % plot averaged signal
        % title(ax_deltaM, tissue_type_struct.label)
        if meas == numel(clinical_measures)
            xlabel(ax_deltaM, 'PLD (s)') 
        else
            xticklabels(ax_deltaM, {})
        end

        ylabel(ax_deltaM, '\DeltaM')

        hold(ax_deltaM, 'on')
        errorbar(ax_deltaM, PLD, deltaM_ctrl_mean, se_deltaM_ctrl, ...
            'Color', lightBlue, 'LineStyle', '-', 'LineWidth', 1,...
            'DisplayName', sprintf('%s (%s fit)', control_lbl, replace(this_model.label, '_', '\_')));
        errorbar(ax_deltaM, PLD, deltaM_risk_mean, se_deltaM_risk, ...
            'Color', lightRed, 'LineStyle', '-', 'LineWidth', 1, ...
            'DisplayName', sprintf('%s (%s fit)', risk_lbl, replace(this_model.label, '_', '\_')));

        errorbar(ax_deltaM, PLD, data_ctrl, se_data_ctrl, ...
            'Color', 'b', 'LineStyle', 'none', 'LineWidth', 1, 'Marker', 'x', ...
            'DisplayName', ...
            sprintf('%s (data N=%d)', control_lbl, num_ctrl_fit))
        errorbar(ax_deltaM, PLD, data_risk, se_data_risk, ...
            'Color', 'r', 'LineStyle', 'none', 'LineWidth', 1, 'Marker', 'x',  ...
            'DisplayName', ...
            sprintf('%s (data N=%d)', risk_lbl, num_risk_fit))
        
        this_axis = axis(ax_deltaM);
        y_max = max(y_max, this_axis(4));
        y_min = min(y_min, this_axis(3));
        leg = legend(ax_deltaM, 'show', 'Location', 'bestoutside');
        title(leg, clinical_measures{meas}.label)
                
        ax_holder{tis} = ax_deltaM;
        
    end % End of loop over tissue
    y_max = y_max * 1.1;
    y_min = y_min * 0.9;
    for i=1:numel(tissue_type)
        ylim(ax_holder{i}, [y_min y_max])
    end
end
exportgraphics(fig_deltaM, write_png, 'Resolution', 300)

%% Plot averaged curves (ungrouped, all models)
fig_all_models_curves = figure;
n_row = 1; n_col = numel(tissue_type);
tiled = tiledlayout(fig_all_models_curves, n_row, n_col, ...
    "TileSpacing", "tight", "Padding", "tight");
% title(tiled, replace(read_sheet, '_', '\_'))

write_png = fullfile(write_dir, sprintf('%s asl_signal_ungrouped.png', read_sheet));
  
y_min = inf;
y_max = -inf;
ax_holder = cell(1, numel(tissue_type));
for tis=1:numel(tissue_type)
    tissue_type_struct = tissue_type{tis};
    out_file_str = [tissue_type{tis}.name tissue_type{tis}.erode_size];

    %% real data 
    % GE scan
    data_workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', ...
        ['SIDD_' out_file_str '_summed_delta_M.xlsx']);
    data = readtable(data_workbook, 'Sheet', read_sheet, ...
            'VariableNamingRule', 'preserve', 'ReadRowNames', true);
    ids_temp = cellfun(@(x) split(x, '_'), data.Participant_ID, 'UniformOutput', false);
    data.Participant_ID = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);
    data('15',:) = [];
    data('53',:) = [];

    % Philips scan
    % data_workbook = fullfile(strokes_impact_dir, 'Output/extract_summed_signal/newnew', ...
    %     [out_file_str '_summed_delta_M.xlsx']);
    % data = readtable(data_workbook, 'Sheet', read_sheet, ...
    %         'VariableNamingRule', 'preserve', 'ReadRowNames', true);
    % ids_temp = cellfun(@(x) split(x, '-'), data.Participant_ID, 'UniformOutput', false);
    % data.Participant_ID = cellfun(@(x) strip(x{end}, 'left', '0'), ids_temp, 'UniformOutput', false);

    mean_data = mean(data{:, :});
    se_data = std(data{:, :}) ./ sqrt(numel(data.Participant_ID));

    ax_deltaM = nexttile(tiled);

    % plot averaged signal
    title(ax_deltaM, tissue_type_struct.label)
    xlabel(ax_deltaM, 'PLD (s)') 
    
    hold(ax_deltaM, 'on')
    box(ax_deltaM, 'on')

    % if tis ~= 1
    %     yticklabels(ax_deltaM, [])
    % else
        ylabel(ax_deltaM, '\DeltaM')
    % end

    %% fit
    fit_workbook = fullfile(calc_akaike_weights_dir, out_file_str, ...
        [read_sheet '_delta_M.xlsx']);

    for mi=1:numel(tissue_type_struct.model)
        this_model = tissue_type_struct.model{mi};
        fit_deltaM = readtable(fit_workbook, ...
            'Sheet', this_model.name, ...
            'VariableNamingRule', 'preserve', 'ReadRowNames', true);
        mean_fit = mean(fit_deltaM{:, :});
        se_fit = std(fit_deltaM{:, :}) ./ sqrt(numel(fit_deltaM.Participant_ID));

        errorbar(ax_deltaM, PLD, mean_fit, se_fit, ...
             'LineStyle', '--', 'LineWidth', 1,...
            'DisplayName', sprintf('fit (%s)',...
             replace(this_model.label, '_', '\_'))); 
    end

    errorbar(ax_deltaM, PLD, mean_data, se_data, ...
        'LineStyle', 'none', 'LineWidth', 1, 'Marker', 'o', ...
        'DisplayName', ...
        sprintf('data (N=%d)', numel(data.Participant_ID)))

    this_axis = axis(ax_deltaM);
    y_max = max(y_max, this_axis(4));
    y_min = min(y_min, this_axis(3));
    leg = legend(ax_deltaM, 'show', 'Location', 'northwest');
            
    ax_holder{tis} = ax_deltaM;
end % End of loop over tissue
y_max = y_max * 1.1;
y_min = y_min * 0.9;
for i=1:numel(tissue_type)
    ylim(ax_holder{i}, [y_min y_max])
end

exportgraphics(fig_all_models_curves, write_png, 'Resolution', 300)

