addpath('C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\My code')
% close all;
clear all;
onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

set(groot, 'DefaultAxesFontSize', 13)
set(groot, 'DefaultTextFontSize', 13)
set(groot, 'DefaultLegendFontSize', 13)
set(groot, 'DefaultColorbarFontSize', 13)
set(groot, 'DefaultAxesFontName', 'Arial')
set(groot, 'DefaultTextFontName', 'Arial')
set(groot, 'DefaultLineLineWidth', 1.5)
set(groot, 'DefaultScatterSizeData', 80)

tic

%% Define fixed param
tissue_prob = '0_9';
read_sheet = 'median_times_vol_normalised';
read_sheet = 'median_normalised';
read_sheet = 'mean_times_vol_normalised';

lv_f_bound = [0 150];
cp_f_bound = [0 50];

% lv_f_bound = [0 100];
% cp_f_bound = [0 30];

% lv_f_bound = [0 120/6000];
% cp_f_bound = [0 120/6000];

tA_bound = [0 4];
kb_bound = [0 10];
outflow_csf_bound = [0 30];

SIpd = 1;
alpha = 0.85;
lambda = 0.9;
numIter = 500;
f_dummy = 0;
ttr_dummy = 0;

%% models
SBCM = struct('name', 'SBCM', 'model', @fit_SCM, ...
    'model_specific_arg', struct('sblood', 1, 'outflow', 0, 'outflow_csf', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound'}});
STCM = struct('name', 'STCM', 'model', @fit_SCM, ...
    'model_specific_arg', struct('sblood', 0, 'outflow', 0, 'outflow_csf', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound'}});
STCM_csf = struct('name', 'STCM_LV', 'model', @fit_SCM, ...
    'model_specific_arg', struct('sblood', 0, 'outflow', 0, 'outflow_csf', 1), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound', 'outflow_csf_bound'}});
TCM = struct('name', 'TCM', 'model', @fit_TCM, ...
    'model_specific_arg', struct('fit_kb_only', 0, 'fit_kb_T1b', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound', 'kb_bound'}});

%% GE scans
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
LD_arr = [0.573 0.885 2.042];
PLD = sort([PLDs_eASL_PLD1000 PLDs_eASL_PLD700]) ./ 1000; % seconds
LD = sort([LD_arr LD_arr]);

cp_erode_size = 'erode_size1_corrected_mask';
lv_erode_size = 'erode_size3_corrected_mask';

write_dir = fullfile(onedrive, 'CE-ASL/Output/STCM_csf_model_identifiability');

%% Philips scans
% PLD = [890 1300 1700 2100 2500] ./ 1000; % seconds
% LD = 1.8 * ones(size(PLD));
% 
% strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
% hct_tbl = readtable(fullfile(strokes_impact_dir, 'Hematocrit.xlsx'), 'VariableNamingRule', 'preserve', ...
%     ReadRowNames=true);
% hct_tbl.Study_ID = cellfun(@(x) replace(x, '11189', '1189'), hct_tbl.Study_ID, 'UniformOutput', false);
% 
% write_dir = fullfile(strokes_impact_dir, 'Output/STCM_csf_model_identifiability');
% 
% cp_erode_size = '_mask';
% lv_erode_size = '_erode3mm';

%% read CP & LV data
lv_file_str = ['lateral ventricles' lv_erode_size];
cp_file_str = ['choroid plexus' cp_erode_size];
    
% GE scans
lv_read_workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', ...
    ['SIDD_' lv_file_str '_summed_delta_M.xlsx']);
cp_read_workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', ...
    ['SIDD_' cp_file_str '_summed_delta_M.xlsx']);
% Philips scans
% lv_read_workbook = fullfile(strokes_impact_dir, 'Output/extract_summed_signal/newnew', ...
%     [lv_file_str '_summed_delta_M.xlsx']);
% cp_read_workbook = fullfile(strokes_impact_dir, 'Output/extract_summed_signal/newnew', ...
%     [cp_file_str '_summed_delta_M.xlsx']);

lv_data = readtable(lv_read_workbook, 'Sheet', read_sheet, ...
        'VariableNamingRule', 'preserve', 'ReadRowNames', true);
cp_data = readtable(cp_read_workbook, 'Sheet', read_sheet, ...
        'VariableNamingRule', 'preserve', 'ReadRowNames', true);
lv_data = lv_data(all(~isnan(table2array(lv_data)), 2), :);
data_err = [];
id_list = lv_data.Participant_ID;
id_list = id_list(1:5);

% Get T1 tables and mean T1 values
% GE scans
participant_details = readtable(fullfile(onedrive, ...
    'CE-ASL/ParticipantDetails.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);
mean_T1b = mean(participant_details{:, "T1b"}, 'omitnan');
lv_T1_source_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', ...
    ['combined_data_' lv_file_str '_T1.xlsx']);
lv_T1_tbl = readtable(lv_T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
common_ids = intersect(id_list, lv_T1_tbl.Participant_ID);
lv_T1_tbl = lv_T1_tbl(common_ids,:);
select_row = find(strcmp(lv_T1_tbl.Participant_ID,'045'))-1;
lv_mean_T1 = mean(lv_T1_tbl{1:select_row, :} / 1000, 'all', 'omitnan');
cp_T1_source_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', ...
    ['combined_data_' cp_file_str '_T1.xlsx']);
cp_T1_tbl = readtable(cp_T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
cp_T1_tbl = cp_T1_tbl(common_ids,:);
select_row = find(strcmp(cp_T1_tbl.Participant_ID,'045'))-1;
cp_mean_T1 = mean(cp_T1_tbl{1:select_row, :} / 1000, 'all', 'omitnan');

%% Philips scans
% common_ids = intersect(id_list, hct_tbl.Study_ID);
% hct_tbl_temp = hct_tbl(common_ids,:);
% mean_T1b = mean(hct_tbl_temp{:, "T1b"}, 'omitnan');
% lv_T1_source_dir = fullfile(strokes_impact_dir, 'Output/extract_roi_T1', ...
%     [lv_file_str '.xlsx']);
% lv_T1_tbl = readtable(lv_T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
% common_ids = intersect(id_list, lv_T1_tbl.Participant_ID);
% lv_T1_tbl_temp = lv_T1_tbl(common_ids,:);
% lv_T1_tbl_temp(strcmp(lv_T1_tbl_temp.Participant_ID, '1189-027'),:) = [];
% lv_mean_T1 = mean(table2array(lv_T1_tbl_temp) ./ 1000, 'all', 'omitnan');
% cp_T1_source_dir = fullfile(strokes_impact_dir, 'Output/extract_roi_T1', ...
%     [cp_file_str '.xlsx']);
% cp_T1_tbl = readtable(cp_T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
% cp_T1_tbl_temp = cp_T1_tbl(common_ids,:);
% cp_T1_tbl_temp(strcmp(cp_T1_tbl_temp.Participant_ID, '1189-027'),:) = [];
% cp_mean_T1 = mean(table2array(cp_T1_tbl_temp) ./ 1000, 'all', 'omitnan');

%% Initialise arrays to store solution for each id
% CP data fitting solutions
cp_stcm_arr = zeros(numel(id_list), 3); % [f_cp ttr_cp rmse];
cp_sbcm_arr = zeros(numel(id_list), 3); % [f_cp ttr_cp rmse];
cp_tcm_arr = zeros(numel(id_list), 4); % [f_cp ttr_cp kb_cp rmse];
% delta M
deltaM_cp_stcm = zeros(numel(id_list), length(PLD));
deltaM_cp_sbcm = zeros(numel(id_list), length(PLD));
deltaM_cp_tcm = zeros(numel(id_list), length(PLD));

% LV data fitting solutions
lv_stcm_arr = zeros(numel(id_list), 3); % [f_lv ttr_lv rmse]; STCM
cp_lv_stcm_arr = zeros(numel(id_list), 2); % [k_csf rmse]; CP input from STCM
cp_lv_sbcm_arr = zeros(numel(id_list), 2); % [k_csf rmse]; CP input from SBCM
lv_stcm_outflow_arr = zeros(numel(id_list), 4); % [f_lv ttr_lv k_out rmse]; STCM with csf outflow
% delta M
deltaM_lv_stcm = zeros(numel(id_list), length(PLD));
deltaM_lv_stcm_outflow = zeros(numel(id_list), length(PLD));
deltaM_lv_cplvstcm = zeros(numel(id_list), length(PLD));
deltaM_lv_cplvsbcm = zeros(numel(id_list), length(PLD));

if ~isfolder(write_dir)
    mkdir(write_dir)
end


% Loop through each participant
for i=1:numel(id_list)
    cp_data_id = cp_data{i, :};
    lv_data_id = lv_data{i, :};

    % GE scans
    id_list1_split = split(char(id_list{i}), '_');
    id_no_contrast = [id_list{i} '_no_contrast'];
    id = strip(id_list1_split{1}, 'left', '0')

    % Philips scan
    % id = id_list{i}

    % assign T1
    hct_tbl_temp = participant_details; % Uncomment for GE scans
    if isnan(hct_tbl_temp{id, "T1b"})
        T1b = mean_T1b;
    else
        T1b = hct_tbl_temp{id, "T1b"};
    end

    % GE scans
    if isnan(lv_T1_tbl{id_list{i}, :}) || str2double(id) >= 45
        lv_T1e = lv_mean_T1;
    else
        lv_T1e = lv_T1_tbl{id_list{i}, :} / 1000;
    end
    if isnan(cp_T1_tbl{id_list{i}, :}) || str2double(id) >= 45
        cp_T1e = cp_mean_T1;
    else
        cp_T1e = cp_T1_tbl{id_list{i}, :} / 1000;
    end

    % Philips scans
    % if isnan(cp_T1_tbl{id_list{i}, :}) || strcmp(id, '1189-027')
    %     cp_T1e = cp_mean_T1;
    % else
    %     cp_T1e = cp_T1_tbl{id_list{i}, :} / 1000;
    % end
    % if isnan(lv_T1_tbl{id_list{i}, :}) || strcmp(id, '1189-027')
    %     lv_T1e = lv_mean_T1;
    % else
    %     lv_T1e = lv_T1_tbl{id_list{i}, :} / 1000;
    % end

    %% create figures
    % fig = figure('Visible', 'off','Position', [100 100 2400 800]);
    fig_cp = figure;
    tiled_cp = tiledlayout(fig_cp, 2, 3, "TileSpacing", "compact", "Padding", "tight");
    title(tiled_cp, ['CP (ID: ' id ')'])
    ax_curve_cp = nexttile(tiled_cp);
    ax_stcm_cp = nexttile(tiled_cp);
    ax_sbcm_cp = nexttile(tiled_cp);
    ax_tcm_f_tA_cp = nexttile(tiled_cp);
    ax_tcm_f_kb_cp = nexttile(tiled_cp);
    ax_tcm_tA_kb_cp = nexttile(tiled_cp);

    fig_lv = figure;
    tiled_lv = tiledlayout(fig_lv, 2, 3, "TileSpacing", "compact", "Padding", "tight");
    title(tiled_lv, ['LV (ID: ' id ')'])
    ax_curve_lv = nexttile(tiled_lv);
    ax_stcm_lv = nexttile(tiled_lv);
    ax_cplv_lv = nexttile(tiled_lv);
    ax_stcm_outflow_f_tA_lv = nexttile(tiled_lv);
    ax_stcm_outflow_f_k_lv = nexttile(tiled_lv);
    ax_stcm_outflow_tA_k_lv = nexttile(tiled_lv);
  
    hold(ax_curve_lv, 'on')
    xlabel(ax_curve_lv, 'PLD (s)')
    ylabel(ax_curve_lv, '\DeltaM')
    scatter(ax_curve_lv, PLD, lv_data_id, 'Marker', 'o', 'DisplayName', 'LV data')
    hold(ax_curve_cp, 'on')
    xlabel(ax_curve_cp, 'PLD (s)')
    ylabel(ax_curve_cp, '\DeltaM')
    scatter(ax_curve_cp, PLD, cp_data_id, 'Marker', 'diamond', 'DisplayName', 'CP data')
    
    cp_lower_bound = [cp_f_bound(1); tA_bound(1); kb_bound(1)];
    cp_upper_bound = [cp_f_bound(2); tA_bound(2); kb_bound(2)];
    cp_start_point = cp_lower_bound + ...
         (cp_upper_bound - cp_lower_bound).*rand(length(cp_lower_bound), numIter);

    lv_lower_bound = [lv_f_bound(1); tA_bound(1); outflow_csf_bound(1)];
    lv_upper_bound = [lv_f_bound(2); tA_bound(2); outflow_csf_bound(2)];
    lv_start_point = lv_lower_bound + ...
         (lv_upper_bound - lv_lower_bound).*rand(length(lv_lower_bound), numIter);

    %% CP - STCM solutions
    hold(ax_stcm_cp, 'on')
    ylabel(ax_stcm_cp, 'F (rel. units)')
    xlabel(ax_stcm_cp, 't_A (s)')
    title(ax_stcm_cp, 'STCM')
    
    solutions = NaN(3, numIter); % store f,ttr,kb,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = cp_start_point(1:2, itr);
        
        [estimates, rmse, ~] = STCM.model(PLD, LD, ...
                alpha, lambda, SIpd, T1b, cp_T1e, ...
                STCM.model_specific_arg.sblood, ...
                STCM.model_specific_arg.outflow,...
                STCM.model_specific_arg.outflow_csf,...
                cp_data_id, data_err, this_start_point, ...
                cp_lower_bound(1:2), cp_upper_bound(1:2), ...
                STCM.fit_option);
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    estimates = solutions(1:end-1, min_idx);
    f_stcm_cp = estimates(1);
    tA_stcm_cp = estimates(2);

    solutions
    scatter(ax_stcm_cp, solutions(2,:), solutions(1,:), [], solutions(3,:), 'filled')
    plot(ax_stcm_cp, tA_stcm_cp, f_stcm_cp, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_stcm_cp);
    c.Label.String = 'RMSE';
    hold(ax_stcm_cp, 'off')

    rmse = solutions(end, min_idx);
    cp_stcm_arr(i, :) = [f_stcm_cp tA_stcm_cp rmse];
    signal = SCM_signal(STCM.model_specific_arg.sblood, STCM.model_specific_arg.outflow, ...
                        STCM.model_specific_arg.outflow_csf,...
                        PLD, LD, alpha, ...
                        lambda, SIpd, T1b, cp_T1e, ...
                        f_stcm_cp, tA_stcm_cp);
    deltaM_cp_stcm(i, :) = signal(:)';
    plot(ax_curve_cp, PLD, signal, 'DisplayName', 'STCM')

    %% CP - SBCM solutions
    hold(ax_sbcm_cp, 'on')
    ylabel(ax_sbcm_cp, 'F (rel. units)')
    xlabel(ax_sbcm_cp, 't_A (s)')
    title(ax_sbcm_cp, 'SBCM solutions')

    solutions = NaN(3, numIter); % store f,ttr,kb,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = cp_start_point(1:2, itr);
        
        [estimates, rmse, ~] = SBCM.model(PLD, LD, ...
                alpha, lambda, SIpd, T1b, cp_T1e, ...
                SBCM.model_specific_arg.sblood, ...
                SBCM.model_specific_arg.outflow,...
                SBCM.model_specific_arg.outflow_csf,...
                cp_data_id, data_err, this_start_point, ...
                cp_lower_bound(1:2), cp_upper_bound(1:2), ...
                SBCM.fit_option);
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    estimates = solutions(1:end-1, min_idx);
    f_sbcm_cp = estimates(1);
    tA_sbcm_cp = estimates(2);

    solutions
    scatter(ax_sbcm_cp, solutions(2,:), solutions(1,:), [], solutions(3,:), 'filled')
    plot(ax_sbcm_cp, tA_sbcm_cp, f_sbcm_cp, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_sbcm_cp);
    c.Label.String = 'RMSE';
    hold(ax_sbcm_cp, 'off')

    rmse = solutions(end, min_idx);
    cp_sbcm_arr(i, :) = [f_sbcm_cp tA_sbcm_cp rmse];
    signal = SCM_signal(SBCM.model_specific_arg.sblood, SBCM.model_specific_arg.outflow, ...
                        SBCM.model_specific_arg.outflow_csf,...
                        PLD, LD, alpha, ...
                        lambda, SIpd, T1b, cp_T1e, ...
                        f_sbcm_cp, tA_sbcm_cp);
    deltaM_cp_sbcm(i, :) = signal(:)';
    plot(ax_curve_cp, PLD, signal, 'DisplayName', 'SBCM')

    %% LV - CP_LV_model solutions
    hold(ax_cplv_lv, 'on')
    ylabel(ax_cplv_lv, 'RMSE')
    xlabel(ax_cplv_lv, 'F (rel. units)')
    % xlabel(ax_cplv_lv, 'k_{csf} (s^{-1})')
    title(ax_cplv_lv, 'blood-CP-LV')

    %% LV - CP_LV_model using CP STCM input
    solutions = NaN(2, numIter); % store k_csf,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = lv_start_point(3, itr);
        
        [estimates, rmse, ~] = fit_CPLV_model(PLD, LD, ...
            alpha, lambda, SIpd, T1b, cp_T1e, STCM.model_specific_arg.sblood, ...
                STCM.model_specific_arg.outflow, f_stcm_cp, tA_stcm_cp, lv_T1e, ...
                lv_data_id, data_err, this_start_point, lv_lower_bound(3), ...
                lv_upper_bound(3), 1);
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    k_stcm_cp_in = solutions(1:end-1, min_idx);
    
    solutions
    scatter(ax_cplv_lv, solutions(1,:), solutions(2,:), [], 'r', 'filled', ...
        'DisplayName', 'STCM CP input')
    
    rmse = solutions(end, min_idx);
    cp_lv_stcm_arr(i, :) = [k_stcm_cp_in rmse];
    signal = CP_LV_model(STCM.model_specific_arg.sblood, ...
        STCM.model_specific_arg.outflow, PLD, LD, alpha, lambda, ...
        SIpd, T1b, cp_T1e, f_stcm_cp, tA_stcm_cp, lv_T1e, k_stcm_cp_in);
    deltaM_lv_cplvstcm(i, :) = signal(:)';
    plot(ax_curve_lv, PLD, signal, 'DisplayName', 'blood-CP(STCM)-LV')

    %% LV - CP_LV_model using CP SBCM input
    solutions = NaN(2, numIter); % store k_csf,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = lv_start_point(3, itr);
        
        [estimates, rmse, ~] = fit_CPLV_model(PLD, LD, ...
            alpha, lambda, SIpd, T1b, cp_T1e, SBCM.model_specific_arg.sblood, ...
                SBCM.model_specific_arg.outflow, f_sbcm_cp, tA_sbcm_cp, lv_T1e, ...
                lv_data_id, data_err, this_start_point, lv_lower_bound(3), ...
                lv_upper_bound(3), 1);
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    k_sbcm_cp_in = solutions(1:end-1, min_idx);
    
    solutions
    scatter(ax_cplv_lv, solutions(1,:), solutions(2,:), [], 'b', 'filled', ...
        'DisplayName', 'SBCM CP input')
    legend(ax_cplv_lv, 'show', 'Location', 'best')
    hold(ax_cplv_lv, 'off')
    rmse = solutions(end, min_idx);
    cp_lv_sbcm_arr(i, :) = [k_sbcm_cp_in rmse];
    signal = CP_LV_model(SBCM.model_specific_arg.sblood, ...
        SBCM.model_specific_arg.outflow, PLD, LD, alpha, lambda, ...
        SIpd, T1b, cp_T1e, f_sbcm_cp, tA_sbcm_cp, lv_T1e, k_sbcm_cp_in);
    deltaM_lv_cplvsbcm(i, :) = signal(:)';
    % plot(ax_curve_lv, PLD, signal, 'DisplayName', 'CP-LV (SBCM input)')
    plot(ax_curve_lv, PLD, signal, 'DisplayName', 'blood-CP(SBCM)-LV')

    %% CP - TCM solutions
    hold(ax_tcm_f_tA_cp, 'on')
    hold(ax_tcm_f_kb_cp, 'on')
    hold(ax_tcm_tA_kb_cp, 'on')
    % title(ax_tcm_f_tA_cp, 'TCM solutions')
    % title(ax_tcm_f_kb_cp, 'TCM solutions')
    % title(ax_tcm_tA_kb_cp, 'TCM solutions')
    title(ax_tcm_f_tA_cp, 'TCM')
    title(ax_tcm_f_kb_cp, 'TCM')
    title(ax_tcm_tA_kb_cp, 'TCM')
    ylabel(ax_tcm_f_tA_cp, 'F (rel. units)')
    xlabel(ax_tcm_f_tA_cp, 't_A (s)')
    ylabel(ax_tcm_f_kb_cp, 'F (rel. units)')
    xlabel(ax_tcm_f_kb_cp, 'k_b (s^{-1})')
    ylabel(ax_tcm_tA_kb_cp, 't_A (s)')
    xlabel(ax_tcm_tA_kb_cp, 'k_b (s^{-1})')

    solutions = NaN(4, numIter); % store f,ttr,kb,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = cp_start_point(:, itr);
        
        [estimates, rmse, ~] = TCM.model(PLD, LD, ...
                            alpha, lambda, SIpd, T1b, cp_T1e, f_dummy, ttr_dummy, ...
                            TCM.model_specific_arg.fit_kb_only, ...
                            TCM.model_specific_arg.fit_kb_T1b, ...
                            cp_data_id, data_err, ...
                            this_start_point, cp_lower_bound, cp_upper_bound, ...
                            TCM.fit_option);
                        
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    estimates = solutions(1:end-1, min_idx);
    f_tcm_cp = estimates(1);
    tA_tcm_cp = estimates(2);
    kb_tcm_cp = estimates(3);

    solutions
    % f-tA
    scatter(ax_tcm_f_tA_cp, solutions(2,:), solutions(1,:), [], solutions(end,:), 'filled')
    plot(ax_tcm_f_tA_cp, tA_tcm_cp, f_tcm_cp, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_tcm_f_tA_cp);
    c.Label.String = 'RMSE';
    hold(ax_tcm_f_tA_cp, 'off')
    % f-kb
    scatter(ax_tcm_f_kb_cp, solutions(3,:), solutions(1,:), [], solutions(end,:), 'filled')
    plot(ax_tcm_f_kb_cp, kb_tcm_cp, f_tcm_cp, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_tcm_f_kb_cp);
    c.Label.String = 'RMSE';
    hold(ax_tcm_f_kb_cp, 'off')
    % tA-kb
    scatter(ax_tcm_tA_kb_cp, solutions(3,:), solutions(2,:), [], solutions(end,:), 'filled')
    plot(ax_tcm_tA_kb_cp, kb_tcm_cp, tA_tcm_cp, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_tcm_tA_kb_cp);
    c.Label.String = 'RMSE';
    hold(ax_tcm_tA_kb_cp, 'off')

    rmse = solutions(end, min_idx);
    cp_tcm_arr(i, :) = [f_tcm_cp tA_tcm_cp kb_tcm_cp rmse];
    signal = TCM_signal(PLD, LD, alpha, lambda, SIpd, ...
                T1b, cp_T1e, f_tcm_cp, tA_tcm_cp, kb_tcm_cp);
                    
    deltaM_cp_tcm(i, :) = signal(:)';
    plot(ax_curve_cp, PLD, signal, 'DisplayName', 'TCM')

    %% LV - STCM solutions
    hold(ax_stcm_lv, 'on')
    ylabel(ax_stcm_lv, 'F (rel. units)')
    xlabel(ax_stcm_lv, 't_A (s)')
    title(ax_stcm_lv, 'STCM')

    solutions = NaN(3, numIter); % store f,ttr,kb,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = lv_start_point(1:2, itr);
        
        [estimates, rmse, ~] = STCM.model(PLD, LD, ...
                alpha, lambda, SIpd, T1b, lv_T1e, ...
                STCM.model_specific_arg.sblood, ...
                STCM.model_specific_arg.outflow,...
                STCM.model_specific_arg.outflow_csf,...
                lv_data_id, data_err, this_start_point, ...
                lv_lower_bound(1:2), lv_upper_bound(1:2), ...
                STCM.fit_option);
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    estimates = solutions(1:end-1, min_idx);
    f_stcm_lv = estimates(1);
    tA_stcm_lv = estimates(2);

    solutions
    scatter(ax_stcm_lv, solutions(2,:), solutions(1,:), [], solutions(3,:), 'filled')
    plot(ax_stcm_lv, tA_stcm_lv, f_stcm_lv, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_stcm_lv);
    c.Label.String = 'RMSE';
    hold(ax_stcm_lv, 'off')

    rmse = solutions(end, min_idx);
    lv_stcm_arr(i, :) = [f_stcm_lv tA_stcm_lv rmse];
    signal = SCM_signal(STCM.model_specific_arg.sblood, STCM.model_specific_arg.outflow, ...
                        STCM.model_specific_arg.outflow_csf,...
                        PLD, LD, alpha, ...
                        lambda, SIpd, T1b, lv_T1e, ...
                        f_stcm_lv, tA_stcm_lv);
    deltaM_lv_stcm(i, :) = signal(:)';
    plot(ax_curve_lv, PLD, signal, 'DisplayName', 'STCM')

    
    %% LV - STCM with outflow solutions
    hold(ax_stcm_outflow_f_tA_lv, 'on')
    hold(ax_stcm_outflow_f_k_lv, 'on')
    hold(ax_stcm_outflow_tA_k_lv, 'on')
    % title(ax_stcm_outflow_f_tA_lv, 'STCM+outflow solutions')
    % title(ax_stcm_outflow_f_k_lv, 'STCM+outflow solutions')
    % title(ax_stcm_outflow_tA_k_lv, 'STCM+outflow solutions')
    title(ax_stcm_outflow_f_tA_lv, 'STCM+outflow')
    title(ax_stcm_outflow_f_k_lv, 'STCM+outflow')
    title(ax_stcm_outflow_tA_k_lv, 'STCM+outflow')
    ylabel(ax_stcm_outflow_f_tA_lv, 'F (rel. units)')
    xlabel(ax_stcm_outflow_f_tA_lv, 't_A (s)')
    ylabel(ax_stcm_outflow_f_k_lv, 'F (rel. units)')
    xlabel(ax_stcm_outflow_f_k_lv, 'k_{out} (s^{-1})')
    ylabel(ax_stcm_outflow_tA_k_lv, 't_A (s)')
    xlabel(ax_stcm_outflow_tA_k_lv, 'k_{out} (s^{-1})')

    solutions = NaN(4, numIter); % store f,ttr,kb,resnorm in numIter columns
    for itr=1:numIter
        this_start_point = lv_start_point(:, itr);
        
        [estimates, rmse, ~] = STCM_csf.model(PLD, LD, ...
                alpha, lambda, SIpd, T1b, lv_T1e, ...
                STCM_csf.model_specific_arg.sblood, ...
                STCM_csf.model_specific_arg.outflow,...
                STCM_csf.model_specific_arg.outflow_csf,...
                lv_data_id, data_err, this_start_point, ...
                lv_lower_bound, lv_upper_bound, ...
                STCM_csf.fit_option);
                        
         solutions(:,itr) = [estimates; rmse];
    end

    [~, min_idx] = min(solutions(end,:), [], 'omitnan');
    estimates = solutions(1:end-1, min_idx);
    f_stcm_outflow_lv = estimates(1);
    tA_stcm_outflow_lv = estimates(2);
    k_stcm_outflow_lv = estimates(3);

    solutions
    % f-tA
    scatter(ax_stcm_outflow_f_tA_lv, solutions(2,:), solutions(1,:), [], solutions(end,:), 'filled')
    plot(ax_stcm_outflow_f_tA_lv, tA_stcm_outflow_lv, f_stcm_outflow_lv, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_stcm_outflow_f_tA_lv);
    c.Label.String = 'RMSE';
    hold(ax_stcm_outflow_f_tA_lv, 'off')
    % f-k
    scatter(ax_stcm_outflow_f_k_lv, solutions(3,:), solutions(1,:), [], solutions(end,:), 'filled')
    plot(ax_stcm_outflow_f_k_lv, k_stcm_outflow_lv, f_stcm_outflow_lv, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_stcm_outflow_f_k_lv);
    c.Label.String = 'RMSE';
    hold(ax_stcm_outflow_f_k_lv, 'off')
    % tA-k
    scatter(ax_stcm_outflow_tA_k_lv, solutions(3,:), solutions(2,:), [], solutions(end,:), 'filled')
    plot(ax_stcm_outflow_tA_k_lv, k_stcm_outflow_lv, tA_stcm_outflow_lv, ...
        'Color', 'r', 'Marker', 'square', 'LineStyle', 'none', 'MarkerSize', 10)
    c = colorbar(ax_stcm_outflow_tA_k_lv);
    c.Label.String = 'RMSE';
    hold(ax_stcm_outflow_tA_k_lv, 'off')

    rmse = solutions(end, min_idx);
    lv_stcm_outflow_arr(i, :) = [f_stcm_outflow_lv tA_stcm_outflow_lv k_stcm_outflow_lv rmse];
    signal = SCM_signal(STCM_csf.model_specific_arg.sblood, STCM_csf.model_specific_arg.outflow, ...
                        k_stcm_outflow_lv,...
                        PLD, LD, alpha, ...
                        lambda, SIpd, T1b, lv_T1e, ...
                        f_stcm_outflow_lv, tA_stcm_outflow_lv);
                    
    deltaM_lv_stcm_outflow(i, :) = signal(:)';
    plot(ax_curve_lv, PLD, signal, 'DisplayName', 'STCM+outflow')

    %% format plot
    axis_lim = axis(ax_curve_lv);
    ylim(ax_curve_lv, [axis_lim(3) axis_lim(4)*2.5])
    axis_lim = axis(ax_curve_cp);
    ylim(ax_curve_cp, [axis_lim(3) axis_lim(4)*2])
    legend(ax_curve_lv, 'show', 'Location', 'northwest')
    legend(ax_curve_cp, 'show', 'Location', 'northwest')
    hold(ax_curve_lv, 'off')
    hold(ax_curve_cp, 'off')
    
    exportgraphics(fig_cp, fullfile(write_dir, [id '_cp_' read_sheet '.png']), 'Resolution', 200)
    exportgraphics(fig_lv, fullfile(write_dir, [id '_lv_' read_sheet '.png']), 'Resolution', 200)
end % End of loop over participants

%% Export fit parameters to workbook
% % CP data fitting solutions
% cp_write_workbook = fullfile(write_dir, [read_sheet '_cp_fits.xlsx']);
% tbl = array2table([string(id_list) cp_stcm_arr], ...
%     "VariableNames", {'Participant_ID', 'F (rel. units)', 'tA', 'rmse'});
% writetable(tbl, cp_write_workbook, 'Sheet', 'STCM')
% tbl = array2table([string(id_list) cp_sbcm_arr], ...
%     "VariableNames", {'Participant_ID', 'F (rel. units)', 'tA', 'rmse'});
% writetable(tbl, cp_write_workbook, 'Sheet', 'SBCM')
% tbl = array2table([string(id_list) cp_tcm_arr], ...
%     "VariableNames", {'Participant_ID', 'F (rel. units)', 'tA', 'k_b','rmse'});
% writetable(tbl, cp_write_workbook, 'Sheet', 'TCM')
% % delta M
% tbl = array2table([string(id_list) deltaM_cp_stcm], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, cp_write_workbook, 'Sheet', 'STCM_deltaM')
% tbl = array2table([string(id_list) deltaM_cp_sbcm], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, cp_write_workbook, 'Sheet', 'SBCM_deltaM')
% tbl = array2table([string(id_list) deltaM_cp_tcm], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, cp_write_workbook, 'Sheet', 'TCM_deltaM')
% 
% % LV data fitting solutions
% lv_write_workbook = fullfile(write_dir, [read_sheet '_lv_fits.xlsx']);
% tbl = array2table([string(id_list) lv_stcm_arr], ...
%     "VariableNames", {'Participant_ID', 'F (rel. units)', 'tA', 'rmse'});
% writetable(tbl, lv_write_workbook, 'Sheet', 'STCM')
% tbl = array2table([string(id_list) cp_lv_stcm_arr], ...
%     "VariableNames", {'Participant_ID', 'k_csf', 'rmse'});
% writetable(tbl, lv_write_workbook, 'Sheet', 'CPLV_model_STCM_CPinput')
% tbl = array2table([string(id_list) cp_lv_sbcm_arr], ...
%     "VariableNames", {'Participant_ID', 'k_csf', 'rmse'});
% writetable(tbl, lv_write_workbook, 'Sheet', 'CPLV_model_SBCM_CPinput')
% tbl = array2table([string(id_list) lv_stcm_outflow_arr], ...
%     "VariableNames", {'Participant_ID', 'F (rel. units)', 'tA', 'k_out', 'rmse'});
% writetable(tbl, lv_write_workbook, 'Sheet', 'STCM_outflow')
% % delta M
% tbl = array2table([string(id_list) deltaM_lv_stcm], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, lv_write_workbook, 'Sheet', 'STCM_deltaM')
% tbl = array2table([string(id_list) deltaM_lv_stcm_outflow], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, lv_write_workbook, 'Sheet', 'STCM_outflow_deltaM')
% tbl = array2table([string(id_list) deltaM_lv_cplvstcm], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, lv_write_workbook, 'Sheet', 'CPLV_model_STCM_CPinput_deltaM')
% tbl = array2table([string(id_list) deltaM_lv_cplvsbcm], ...
%     "VariableNames", ["Participant_ID" string(PLD)]);
% writetable(tbl, lv_write_workbook, 'Sheet', 'CPLV_model_SBCM_CPinput_deltaM')

toc


