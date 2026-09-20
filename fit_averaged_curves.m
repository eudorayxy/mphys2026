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

%% define varaibles
lv_f_bound = [0 150];
cp_f_bound = [0 50];
ilv_f_bound = cp_f_bound;

gm_f_bound = [0 120/6000];
wm_f_bound = [0 120/6000];
% lv_f_bound = [0 120/6000];
% cp_f_bound = [0 120/6000];

tA_bound = [0 5];
kb_bound = [0 10];
outflow_csf_bound = [0 30];

SIpd = 1; % this is technically not SIpd anymore - data were normalised
alpha = 0.85;
lambda = 0.9;
numIter = 500;
f_dummy = 0;
ttr_dummy = 0;
data_err = [];

tissue_prob = '0_9';
read_sheet = 'median_times_vol_normalised';
read_sheet = 'median_normalised';
read_sheet = 'mean_times_vol_normalised';
fitNames = {'f', 'tA', 'k'
    };
ylabels = {'F (mL/s)', 't_A (s)' , 'k_{out} (s^{-1})'
    };

%% models
SBCM = struct('name', 'SBCM', 'label', 'SBCM', 'model', @fit_SCM, ...
    'model_specific_arg', struct('sblood', 1, 'outflow', 0, 'outflow_csf', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound'}});
STCM = struct('name', 'STCM', 'label', 'STCM', 'model', @fit_SCM, ...
    'model_specific_arg', struct('sblood', 0, 'outflow', 0, 'outflow_csf', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound'}});
STCM_csf = struct('name', 'STCM_LV', 'label', 'STCM+outflow', 'model', @fit_SCM, ...
    'model_specific_arg', struct('sblood', 0, 'outflow', 0, 'outflow_csf', 1), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound', 'outflow_csf_bound'}});
TCM = struct('name', 'TCM', 'label', 'TCM', 'model', @fit_TCM, ...
    'model_specific_arg', struct('fit_kb_only', 0, 'fit_kb_T1b', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound', 'kb_bound'}});
CPLV = struct('name', 'CP_LV', 'label', 'blood-CP-LV', ...
    'model', @fit_CPLV_model, ...
    'model_specific_arg', struct('sblood', 1, 'outflow', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'outflow_csf_bound'}});

%% GE scans
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
LD_arr = [0.573 0.885 2.042];
PLD = sort([PLDs_eASL_PLD1000 PLDs_eASL_PLD700]) ./ 1000; % seconds
LD = sort([LD_arr LD_arr]);

participant_details = readtable(fullfile(onedrive, ...
    'CE-ASL/ParticipantDetails.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);

gm = struct('name', 'gm', 'label', 'GM', 'erode_size', ['_' tissue_prob], ...
    'model', {{SBCM, STCM, TCM}}, 'f_bound', gm_f_bound, 'tA_bound', tA_bound, 'kb_bound', kb_bound);
wm = struct('name', 'wm','label', 'WM', 'erode_size', ['_' tissue_prob], ...
    'model', {{SBCM, STCM, TCM}}, 'f_bound', wm_f_bound, 'tA_bound',  tA_bound, 'kb_bound', kb_bound);
lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
    'erode_size', 'erode_size3_corrected_mask', ...
    'model', {{STCM, STCM_csf, CPLV}}, ...
    'f_bound', lv_f_bound, 'tA_bound', tA_bound, ...
'outflow_csf_bound', outflow_csf_bound);
choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
    'erode_size', 'erode_size1_corrected_mask', ...
    'model', {{SBCM, STCM, TCM}}, 'f_bound', cp_f_bound, 'tA_bound', tA_bound, 'kb_bound', kb_bound);
inf_lateral_ventricle = struct('name', 'inferior lateral ventricles', 'label', 'ILV', ...
    'erode_size', 'erode_size1_corrected_mask', ...
    'model', {{STCM, STCM_csf, CPLV}}, ...
    'f_bound', ilv_f_bound, 'tA_bound', tA_bound, ...
'outflow_csf_bound', outflow_csf_bound);

calc_akaike_weights_dir = fullfile(onedrive, ...
    'CE-ASL/Output/calc_akaike_weights_centralT1');
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

% MCI = struct('name', 'MCI', 'at_risk', 'Y', 'label', 'MCI', ...
%     'control_label', 'NC', 'risk_label', 'MCI');
% MoCA = struct('name', 'MoCA', 'at_risk', 25, 'label', 'MoCA', ...
%     'control_label', 'MoCA>25', 'risk_label', 'MoCA\leq25');
% Amyloid = struct('name', 'Amyloid', 'at_risk', 'Y', 'label', 'Amyloid', ...
%     'control_label', 'Amyloid -', 'risk_label', 'Amyloid +');
% QRisk = struct('name', 'QRISK category', 'at_risk', 'Y', 'label', 'QRisk', ...
%     'control_label', 'QRisk low', 'risk_label', 'QRisk high');
clinical_measures = {MCI,...
    ...MoCA, 
    Amyloid, QRisk
    };
write_dir = fullfile(onedrive, 'CE-ASL/Output/fit_averaged_curves');

if ~isfolder(write_dir)
    mkdir(write_dir)
end

gm.selected_model = SBCM;
wm.selected_model = SBCM;
choroid_plexus.selected_model = SBCM;
lateral_ventricle.selected_model = STCM_csf;
inf_lateral_ventricle.selected_model = STCM;

tissue_type = {...gm, wm, ...
    ...choroid_plexus, ...
   lateral_ventricle, inf_lateral_ventricle
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

    % change index for GE / Philips scans
    cp_out_file_str = [choroid_plexus.name choroid_plexus.erode_size];
    cp_results = load(fullfile(onedrive, 'CE-ASL/Output/fit_ASL_summed_signal_centralT1', ...
        cp_out_file_str, sprintf('%s_%s.mat', cp_out_file_str, read_sheet))).results;
    % find SBCM in cp_results
    for mi=1:numel(cp_results.model)
        if strcmp(cp_results.model(mi).name, 'SBCM')
            f_cp = mean(cp_results.model(mi).fit(:,1));
            tA_cp = mean(cp_results.model(mi).fit(:,2));
            T1e_cp = mean(cp_results.model(mi).T1e);
            continue
        end
    end

    % real data 
    % GE scan
    data_workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', ...
        ['SIDD_' out_file_str '_summed_delta_M.xlsx']);
    data = readtable(data_workbook, 'Sheet', read_sheet, ...
            'VariableNamingRule', 'preserve', 'ReadRowNames', true);
    ids_temp = cellfun(@(x) split(x, '_'), data.Participant_ID, 'UniformOutput', false);
    data.Participant_ID = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);
    data('15',:) = [];
    data('53',:) = [];

    mean_T1b = mean(participant_details{data.Participant_ID, "T1b"}, 'omitnan');

    % id 15 has no T1 maps
    T1_source_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', ...
        ['combined_data_' out_file_str '_T1.xlsx']);
    T1_tbl = readtable(T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
    select_row = find(strcmp(T1_tbl.Participant_ID,'045'))-1;
    mean_T1 = mean(T1_tbl{1:select_row, :} / 1000, 'all', 'omitnan');

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

    % fit
    for mi=1:numel(tissue_type_struct.model)
        this_model = tissue_type_struct.model{mi};
        this_model_func = this_model.model;
    
        numFit = numel(this_model.param_bound);
    
        lower_bound = zeros(numel(this_model.param_bound),1);
        upper_bound = zeros(numel(this_model.param_bound),1);
        for bi=1:numel(this_model.param_bound)
            param_bound_str = this_model.param_bound{bi};
            this_param_bound = tissue_type_struct.(param_bound_str);
            lower_bound(bi) = this_param_bound(1);
            upper_bound(bi) = this_param_bound(2);
        end
    
        start_point_arr = lower_bound(:) + ...
            (upper_bound(:) - lower_bound(:)).*rand(length(lower_bound), numIter);

        multi_start_solutions = zeros(numIter, numFit+1);
        for itr=1:numIter % loop through numIter (set) of start points
            start_point = start_point_arr(:, itr);

            model_specific_args = this_model.model_specific_arg;

            % Use SCM
            if isfield(model_specific_args, 'sblood') && ...
                isfield(model_specific_args, 'outflow')
                if isfield(model_specific_args, 'outflow_csf')
                    [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                        alpha, lambda, SIpd, mean_T1b, mean_T1, ...
                        model_specific_args.sblood, ...
                        model_specific_args.outflow,...
                        model_specific_args.outflow_csf,...
                        mean_data, data_err, start_point, ...
                        lower_bound, upper_bound, ...
                        this_model.fit_option);
                else
                    [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                        alpha, lambda, SIpd, mean_T1b, T1e_cp, ...
                        model_specific_args.sblood, ...
                        model_specific_args.outflow, f_cp, tA_cp, mean_T1, ...
                        mean_data, data_err, start_point, ...
                        lower_bound, upper_bound, this_model.fit_option);
                end
            elseif isfield(model_specific_args, 'sblood_cp') && ...
                    isfield(model_specific_args, 'outflow_cp') && ...
                    isfield(model_specific_args, 'sblood_lv') && ...
                    isfield(model_specific_args, 'outflow_lv')
                [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                    alpha, lambda, SIpd, mean_T1b, T1e_cp, mean_T1, ...
                    model_specific_args.sblood_cp, ...
                    model_specific_args.outflow_cp, ...
                    model_specific_args.sblood_lv, ...
                    model_specific_args.outflow_lv, f_cp, tA_cp, ...
                    mean_data, data_err, start_point, lower_bound, ...
                    upper_bound, this_model.fit_option);

            % Use TCM
            elseif isfield(model_specific_args, 'fit_kb_only') && ...
                isfield(model_specific_args, 'fit_kb_T1b')
    
                [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                    alpha, lambda, SIpd, mean_T1b, mean_T1, f_dummy, ttr_dummy, ...
                    model_specific_args.fit_kb_only, model_specific_args.fit_kb_T1b, ...
                    mean_data, data_err, ...
                    start_point, lower_bound, upper_bound, this_model.fit_option); 
            else
                disp(['ERROR: Neither SCM_signal nor TCM_signal ...' ...
                        'nor CP_LV_model nor sum_bloodLV_CPLV can be called.'])
            end
    
            % multi_start_solutions(itr, :) = [rmse, chisq, estimates'];
            multi_start_solutions(itr, :) = [rmse, estimates'];
            
        end % End of loop through numIter (sets) of start point

        % PICKED THE CORRECT SOLUTION!
        % find solution with minimum chisq / RMSE
        [~, I] = min(multi_start_solutions(:, 1));
        solutions = multi_start_solutions(I, :)

        f_solution = solutions(2);
        if length(solutions) > 2
            tA_solution = solutions(3);
        else
            tA_solution = 0;
        end
        if isfield(model_specific_args, 'outflow_csf') 
            if model_specific_args.outflow_csf > 0
                outflow_csf = solutions(4);
            else
                outflow_csf = model_specific_args.outflow_csf;
            end
        elseif isfield(model_specific_args, 'sblood_cp') && ...
                isfield(model_specific_args, 'outflow_cp') && ...
                isfield(model_specific_args, 'sblood_lv') && ...
                isfield(model_specific_args, 'outflow_lv')
            outflow_csf = solutions(4);
        else 
            outflow_csf = NaN;
        end

        % plot individual fit
        % Use SCM
        if isfield(model_specific_args, 'sblood') && isfield(model_specific_args, 'outflow')
            if isfield(model_specific_args, 'outflow_csf')
                signal = SCM_signal(model_specific_args.sblood, ...
                    model_specific_args.outflow, ...
                    outflow_csf,...
                    PLD, LD, alpha, ...
                    lambda, SIpd, mean_T1b, mean_T1, ...
                    f_solution, tA_solution);
                
            else
                signal = CP_LV_model(model_specific_args.sblood, ...
                    model_specific_args.outflow, ...
                    PLD, LD, alpha, lambda, SIpd, mean_T1b, T1e_cp, ...
                    f_cp, tA_cp, mean_T1, f_solution);
                
            end
        elseif isfield(model_specific_args, 'sblood_cp') && ...
                isfield(model_specific_args, 'outflow_cp') && ...
                isfield(model_specific_args, 'sblood_lv') && ...
                isfield(model_specific_args, 'outflow_lv')
            signal = sum_bloodLV_CPLV(model_specific_args.sblood_cp, ...
                model_specific_args.outflow_cp, ...
                model_specific_args.sblood_lv, ...
                model_specific_args.outflow_lv, ...
                PLD, LD, alpha, lambda, ...
                SIpd, mean_T1b, T1e_cp, f_cp, tA_cp, ...
                f_solution, tA_solution, mean_T1, outflow_csf);
        % Use TCM
        elseif isfield(model_specific_args, 'fit_kb_only') && ...
                isfield(model_specific_args, 'fit_kb_T1b')
            signal = TCM_signal(PLD, LD, alpha, lambda, SIpd, ...
                mean_T1b, mean_T1, f_solution, tA_solution, solutions(end));
        else
            disp(['ERROR: Neither SCM_signal nor TCM_signal ...' ...
                'nor CP_LV_model nor sum_bloodLV_CPLV can be called.'])
        end

        plot(ax_deltaM, PLD, signal, 'DisplayName', sprintf('fit (%s)',...
             replace(this_model.label, '_', '\_')))
       
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
    % ylim(ax_holder{i}, [y_min y_max])
end

exportgraphics(fig_all_models_curves, write_png, 'Resolution', 300)

%% Plot averaged curves (selected group)
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
        this_model_func = this_model.model;
       
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

        [ctrl_common_ids, ~, ctrl_idx] = intersect(control_ids{meas}, data.Participant_ID);
        num_ctrl_fit = numel(ctrl_common_ids);
        
        [risk_common_ids, ~, risk_idx] = intersect(risk_ids{meas}, data.Participant_ID);
        num_risk_fit = numel(risk_common_ids);

        data_ctrl = mean(data{ctrl_common_ids, :});
        se_data_ctrl = std(data{ctrl_common_ids, :}) ./ sqrt(num_ctrl_fit);
        data_risk = mean(data{risk_common_ids, :});
        se_data_risk = std(data{risk_common_ids, :}) ./ sqrt(num_risk_fit);

        mean_T1b_ctrl = mean(participant_details{ctrl_common_ids, "T1b"}, 'omitnan');
        mean_T1b_risk = mean(participant_details{risk_common_ids, "T1b"}, 'omitnan');

        % id 15 has no T1 maps
        T1_source_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', ...
            ['combined_data_' out_file_str '_T1.xlsx']);
        T1_tbl = readtable(T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
        select_row = find(strcmp(T1_tbl.Participant_ID,'045'))-1;
        ids_temp = cellfun(@(x) split(x, '_'), T1_tbl.Participant_ID, 'UniformOutput', false);
        T1_tbl.Participant_ID = cellfun(@(x) strip(x{1}, 'left', '0'), ids_temp, 'UniformOutput', false);
    
        ctrl_common_ids_T1 = intersect(T1_tbl.Participant_ID(1:select_row), ctrl_common_ids);
        mean_T1_ctrl = mean(T1_tbl{ctrl_common_ids_T1, :} / 1000, 'all', 'omitnan');
        risk_common_ids_T1 = intersect(T1_tbl.Participant_ID(1:select_row), risk_common_ids);
        mean_T1_risk = mean(T1_tbl{risk_common_ids_T1, :} / 1000, 'all', 'omitnan');
       
        % change index for GE / Philips scans
        cp_out_file_str = [choroid_plexus.name choroid_plexus.erode_size];
        cp_results = load(fullfile(onedrive, 'CE-ASL/Output/fit_ASL_summed_signal_centralT1', ...
            cp_out_file_str, sprintf('%s_%s.mat', cp_out_file_str, read_sheet))).results;
        % find SBCM in cp_results
        for mi=1:numel(cp_results.model)
            if strcmp(cp_results.model(mi).name, 'SBCM')
                f_cp_ctrl = mean(cp_results.model(mi).fit(ctrl_idx,1));
                tA_cp_ctrl = mean(cp_results.model(mi).fit(ctrl_idx,2));
                T1e_cp_ctrl = mean(cp_results.model(mi).T1e(ctrl_idx));

                f_cp_risk = mean(cp_results.model(mi).fit(risk_idx,1));
                tA_cp_risk = mean(cp_results.model(mi).fit(risk_idx,2));
                T1e_cp_risk = mean(cp_results.model(mi).T1e(risk_idx));
                continue
            end
        end

        % fit
        numFit = numel(this_model.param_bound);
        lower_bound = zeros(numel(this_model.param_bound),1);
        upper_bound = zeros(numel(this_model.param_bound),1);
        for bi=1:numel(this_model.param_bound)
            param_bound_str = this_model.param_bound{bi};
            this_param_bound = tissue_type_struct.(param_bound_str);
            lower_bound(bi) = this_param_bound(1);
            upper_bound(bi) = this_param_bound(2);
        end
    
        start_point_arr = lower_bound(:) + ...
            (upper_bound(:) - lower_bound(:)).*rand(length(lower_bound), numIter);

        multi_start_solutions_ctrl = zeros(numIter, numFit+1);
        multi_start_solutions_risk = zeros(numIter, numFit+1);
        for itr=1:numIter % loop through numIter (set) of start points
            start_point = start_point_arr(:, itr);
            model_specific_args = this_model.model_specific_arg;

            % Use SCM
            if isfield(model_specific_args, 'sblood') && ...
                isfield(model_specific_args, 'outflow')
                if isfield(model_specific_args, 'outflow_csf')
                    [estimates_ctrl, rmse_ctrl, ~] = this_model_func(PLD, LD, ...
                        alpha, lambda, SIpd, mean_T1b_ctrl, mean_T1_ctrl, ...
                        model_specific_args.sblood, ...
                        model_specific_args.outflow,...
                        model_specific_args.outflow_csf,...
                        data_ctrl, data_err, start_point, ...
                        lower_bound, upper_bound, ...
                        this_model.fit_option);
                    [estimates_risk, rmse_risk, ~] = this_model_func(PLD, LD, ...
                        alpha, lambda, SIpd, mean_T1b_risk, mean_T1_risk, ...
                        model_specific_args.sblood, ...
                        model_specific_args.outflow,...
                        model_specific_args.outflow_csf,...
                        data_risk, data_err, start_point, ...
                        lower_bound, upper_bound, ...
                        this_model.fit_option);
                else
                    [estimates_ctrl, rmse_ctrl, ~] = this_model_func(PLD, LD, ...
                        alpha, lambda, SIpd, mean_T1b_ctrl, T1e_cp_ctrl, ...
                        model_specific_args.sblood, ...
                        model_specific_args.outflow, f_cp_ctrl, tA_cp_ctrl, mean_T1_ctrl, ...
                        data_ctrl, data_err, start_point, ...
                        lower_bound, upper_bound, this_model.fit_option);
                    [estimates_risk, rmse_risk, ~] = this_model_func(PLD, LD, ...
                        alpha, lambda, SIpd, mean_T1b_risk, T1e_cp_risk, ...
                        model_specific_args.sblood, ...
                        model_specific_args.outflow, f_cp_risk, tA_cp_risk, mean_T1_risk, ...
                        data_risk, data_err, start_point, ...
                        lower_bound, upper_bound, this_model.fit_option);
                end
            elseif isfield(model_specific_args, 'sblood_cp') && ...
                    isfield(model_specific_args, 'outflow_cp') && ...
                    isfield(model_specific_args, 'sblood_lv') && ...
                    isfield(model_specific_args, 'outflow_lv')
                [estimates_ctrl, rmse_ctrl, ~] = this_model_func(PLD, LD, ...
                    alpha, lambda, SIpd, mean_T1b_ctrl, T1e_cp_ctrl, mean_T1_ctrl, ...
                    model_specific_args.sblood_cp, ...
                    model_specific_args.outflow_cp, ...
                    model_specific_args.sblood_lv, ...
                    model_specific_args.outflow_lv, f_cp_ctrl, tA_cp_ctrl, ...
                    data_ctrl, data_err, start_point, lower_bound, ...
                    upper_bound, this_model.fit_option);
                [estimates_risk, rmse_risk, ~] = this_model_func(PLD, LD, ...
                    alpha, lambda, SIpd, mean_T1b_risk, T1e_cp_risk, mean_T1_risk, ...
                    model_specific_args.sblood_cp, ...
                    model_specific_args.outflow_cp, ...
                    model_specific_args.sblood_lv, ...
                    model_specific_args.outflow_lv, f_cp_risk, tA_cp_risk, ...
                    data_risk, data_err, start_point, lower_bound, ...
                    upper_bound, this_model.fit_option);

            % Use TCM
            elseif isfield(model_specific_args, 'fit_kb_only') && ...
                isfield(model_specific_args, 'fit_kb_T1b')
    
                [estimates_ctrl, rmse_ctrl, ~] = this_model_func(PLD, LD, ...
                    alpha, lambda, SIpd, mean_T1b_ctrl, mean_T1_ctrl, f_dummy, ttr_dummy, ...
                    model_specific_args.fit_kb_only, model_specific_args.fit_kb_T1b, ...
                    data_ctrl, data_err, ...
                    start_point, lower_bound, upper_bound, this_model.fit_option);
                [estimates_risk, rmse_risk, ~] = this_model_func(PLD, LD, ...
                    alpha, lambda, SIpd, mean_T1b_risk, mean_T1_risk, f_dummy, ttr_dummy, ...
                    model_specific_args.fit_kb_only, model_specific_args.fit_kb_T1b, ...
                    data_risk, data_err, ...
                    start_point, lower_bound, upper_bound, this_model.fit_option);
            else
                disp(['ERROR: Neither SCM_signal nor TCM_signal ...' ...
                        'nor CP_LV_model nor sum_bloodLV_CPLV can be called.'])
            end
    
            multi_start_solutions_ctrl(itr, :) = [rmse_ctrl, estimates_ctrl'];
            multi_start_solutions_risk(itr, :) = [rmse_risk, estimates_risk'];
            
        end % End of loop through numIter (sets) of start point

        loop_solutions = {multi_start_solutions_ctrl, multi_start_solutions_risk};
        c = {lightBlue, lightRed};
        lbl = {control_lbl, risk_lbl};
        mean_T1b = {mean_T1b_ctrl, mean_T1b_risk};
        mean_T1 = {mean_T1_ctrl, mean_T1_risk};
        T1e_cp = {T1e_cp_ctrl, T1e_cp_risk};
        f_cp = {f_cp_ctrl, f_cp_risk};
        tA_cp = {tA_cp_ctrl, tA_cp_risk};

        ax_deltaM = nexttile(tiled);
        box(ax_deltaM, 'on')

        % plot averaged signal
        title(ax_deltaM, tissue_type_struct.label)
        if meas == numel(clinical_measures)
            xlabel(ax_deltaM, 'PLD (s)') 
        else
            xticklabels(ax_deltaM, {})
        end

        ylabel(ax_deltaM, '\DeltaM')

        hold(ax_deltaM, 'on')
        
        for li=1:2
            % PICKED THE CORRECT SOLUTION!
            solutions_li = loop_solutions{li};
            % find solution with minimum chisq / RMSE
            [~, I] = min(solutions_li(:, 1));
            solutions = solutions_li(I, :)
    
            f_solution = solutions(2);
            if length(solutions) > 2
                tA_solution = solutions(3);
            else
                tA_solution = 0;
            end
            if isfield(model_specific_args, 'outflow_csf') 
                if model_specific_args.outflow_csf > 0
                    outflow_csf = solutions(4);
                else
                    outflow_csf = model_specific_args.outflow_csf;
                end
            elseif isfield(model_specific_args, 'sblood_cp') && ...
                    isfield(model_specific_args, 'outflow_cp') && ...
                    isfield(model_specific_args, 'sblood_lv') && ...
                    isfield(model_specific_args, 'outflow_lv')
                outflow_csf = solutions(4);
            else 
                outflow_csf = NaN;
            end
    
            % plot individual fit
            % Use SCM
            if isfield(model_specific_args, 'sblood') && isfield(model_specific_args, 'outflow')
                if isfield(model_specific_args, 'outflow_csf')
                    signal = SCM_signal(model_specific_args.sblood, ...
                        model_specific_args.outflow, ...
                        outflow_csf,...
                        PLD, LD, alpha, ...
                        lambda, SIpd, mean_T1b{li}, mean_T1{li}, ...
                        f_solution, tA_solution);
                    
                else
                    signal = CP_LV_model(model_specific_args.sblood, ...
                        model_specific_args.outflow, ...
                        PLD, LD, alpha, lambda, SIpd, mean_T1b{li}, T1e_cp{li}, ...
                        f_cp{li}, tA_cp{li}, mean_T1{li}, f_solution);
                    
                end
            elseif isfield(model_specific_args, 'sblood_cp') && ...
                    isfield(model_specific_args, 'outflow_cp') && ...
                    isfield(model_specific_args, 'sblood_lv') && ...
                    isfield(model_specific_args, 'outflow_lv')
                signal = sum_bloodLV_CPLV(model_specific_args.sblood_cp, ...
                    model_specific_args.outflow_cp, ...
                    model_specific_args.sblood_lv, ...
                    model_specific_args.outflow_lv, ...
                    PLD, LD, alpha, lambda, ...
                    SIpd, mean_T1b{li}, T1e_cp{li}, f_cp{li}, tA_cp{li}, ...
                    f_solution, tA_solution, mean_T1{li}, outflow_csf);
            % Use TCM
            elseif isfield(model_specific_args, 'fit_kb_only') && ...
                    isfield(model_specific_args, 'fit_kb_T1b')
                signal = TCM_signal(PLD, LD, alpha, lambda, SIpd, ...
                    mean_T1b{li}, mean_T1{li}, f_solution, tA_solution, solutions(end));
            else
                disp(['ERROR: Neither SCM_signal nor TCM_signal ...' ...
                    'nor CP_LV_model nor sum_bloodLV_CPLV can be called.'])
            end
    
            plot(ax_deltaM, PLD, signal, ...
            'Color', c{li}, 'LineStyle', '-', 'LineWidth', 1,...
            'DisplayName', sprintf('%s (%s fit)', lbl{li}, replace(this_model.label, '_', '\_')));
       
        end
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
        hold(ax_deltaM, 'off')
        ax_holder{tis} = ax_deltaM;
    end % End of loop over tissue
    y_max = y_max * 1.1;
    y_min = y_min * 0.9;
    for i=1:numel(tissue_type)
        % ylim(ax_holder{i}, [y_min y_max])
    end
    
end % End of loop over clinical measure
    
exportgraphics(fig_deltaM, write_png, 'Resolution', 300)
