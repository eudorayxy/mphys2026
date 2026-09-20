addpath('C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\My code')
clear all;
onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

tic

tissue_prob = '0_9';

read_sheet = 'median_normalised';
read_sheet = 'mean_times_vol_normalised';

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
%% define varaibles
SIpd = 1; % this is technically not SIpd anymore - data were normalised
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
CPLV = struct('name', 'CP_LV', 'model', @fit_CPLV_model, ...
    'model_specific_arg', struct('sblood', 1, 'outflow', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'outflow_csf_bound'}});
bloodLV_CPLV = struct('name', 'sum_bloodLV_CPLV', 'model', @fit_sum_bloodCP_CPLV, ...
    'model_specific_arg', struct('sblood_cp', 1, 'outflow_cp', 0, 'sblood_lv', 0, 'outflow_lv', 0), ...
    'fit_option', '1', ...
    'param_bound', {{'f_bound', 'tA_bound', 'outflow_csf_bound'}});
%% GE scans
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
LD_arr = [0.573 0.885 2.042];
PLD = sort([PLDs_eASL_PLD1000 PLDs_eASL_PLD700]) ./ 1000;
LD = sort([LD_arr LD_arr]);

participant_details = readtable(fullfile(onedrive, ...
    'CE-ASL/ParticipantDetails.xlsx'), 'VariableNamingRule', 'preserve', ...
    ReadRowNames=true);
mean_T1b = mean(participant_details{:, "T1b"}, 'omitnan');

write_dir = fullfile(onedrive, 'CE-ASL/Output/fit_ASL_summed_signal_centralT1');

gm = struct('name', 'gm', 'label', 'GM', 'erode_size', {{['_' tissue_prob]}}, ...
    'model', {{SBCM, STCM, TCM}}, 'f_bound', gm_f_bound, 'tA_bound', tA_bound, 'kb_bound', kb_bound);
wm = struct('name', 'wm','label', 'WM', 'erode_size', {{['_' tissue_prob]}}, ...
    'model', {{SBCM, STCM, TCM}}, 'f_bound', wm_f_bound, 'tA_bound',  tA_bound, 'kb_bound', kb_bound);
lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
    'erode_size', {{...'_mask', ...
    ...'erode_size1_corrected_mask', 'erode_size2_corrected_mask'...
    'erode_size3_corrected_mask', ...'erode_size4_corrected_mask', ...
    ...'erode_size5_corrected_mask'
    }}, ...
    'model', {{STCM, STCM_csf, CPLV}}, ...
    'f_bound', lv_f_bound, 'tA_bound', tA_bound, ...
'outflow_csf_bound', outflow_csf_bound);
choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
    'erode_size', {{'_mask',...
    'erode_size1_corrected_mask'
    }}, ...
    'model', {{SBCM, STCM, TCM}}, 'f_bound', cp_f_bound, 'tA_bound', tA_bound, 'kb_bound', kb_bound);
inf_lateral_ventricle = struct('name', 'inferior lateral ventricles', 'label', 'ILV', ...
    'erode_size', {{'_mask', ...
    'erode_size1_corrected_mask', 
    }}, ...
    'model', {{STCM, STCM_csf, CPLV}}, ...
    'f_bound', ilv_f_bound, 'tA_bound', tA_bound, ...
'outflow_csf_bound', outflow_csf_bound);

%% Philips scans
% PLD = [890	1300	1700	2100	2500] ./ 1000;
% LD = 1800 ./ 1000 * ones(size(PLD));
% 
% strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
% hct_tbl = readtable(fullfile(strokes_impact_dir, 'Hematocrit.xlsx'), 'VariableNamingRule', 'preserve', ...
%     ReadRowNames=true);
% hct_tbl.Study_ID = cellfun(@(x) replace(x, '11189', '1189'), hct_tbl.Study_ID, 'UniformOutput', false);
% 
% write_dir = fullfile(strokes_impact_dir, 'Output/fit_ASL_summed_signal_centralT1');
% 
% gm = struct('name', 'GM', 'label', 'GM', 'erode_size', {{['_' tissue_prob]}}, ...
%     'model', {{SBCM, STCM, TCM}}, 'f_bound', gm_f_bound, 'tA_bound', tA_bound, 'kb_bound', kb_bound);
% wm = struct('name', 'WM','label', 'WM', 'erode_size', {{['_' tissue_prob]}}, ...
%     'model', {{SBCM, STCM, TCM}}, 'f_bound', wm_f_bound, 'tA_bound',  tA_bound, 'kb_bound', kb_bound);
% lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
%     'erode_size', {{...'_mask',...
%     ...'_erode1mm',... '_erode2mm', ...
%     '_erode3mm', ...'_erode4mm', ...
%     ...'_erode5mm'
%     }},  ...
%     'model', {{STCM, STCM_csf, CPLV}}, ...
%     'f_bound', lv_f_bound, 'tA_bound', tA_bound, ...
%     'outflow_csf_bound', outflow_csf_bound);
% choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
%     'erode_size', {{'_mask', ...
%     '_erode1mm'
%     }}, ...
%     'model', {{SBCM, STCM, TCM}}, 'f_bound', cp_f_bound, 'tA_bound', tA_bound, 'kb_bound', kb_bound);

%%

tissue_type = {...gm, ...
  ...choroid_plexus, ...
  ...lateral_ventricle,...
   ...wm
   inf_lateral_ventricle
    };

subplot_num_column = 4;
subplot_num_row = 4;

%% Loop through tissue type
for tis=1:numel(tissue_type)
    % change index for GE / Philips scans
    cp_out_file_str = [choroid_plexus.name choroid_plexus.erode_size{end}];
    cp_results = load(fullfile(write_dir, cp_out_file_str, ...
                sprintf('%s_%s.mat', cp_out_file_str, read_sheet))).results;
    % find SBCM in cp_results
    for mi=1:numel(cp_results.model)
        if strcmp(cp_results.model(mi).name, 'SBCM')
            f_cp = cp_results.model(mi).fit(:,1);
            tA_cp = cp_results.model(mi).fit(:,2);
            T1e_cp = cp_results.model(mi).T1e;
            continue
        end
    end
    tissue_type_struct = tissue_type{tis};
    
    erode_size_arr = tissue_type{tis}.erode_size;
    for ei=1:numel(erode_size_arr)
        out_file_str = [tissue_type{tis}.name erode_size_arr{ei}];
        out_dir = fullfile(write_dir, out_file_str);
        if ~isfolder(out_dir)
            mkdir(out_dir)
        end

        % GE scans
        read_workbook = fullfile(onedrive, 'CE-ASL/Output/extract_summed_signal/newnew', ...
            ['SIDD_' out_file_str '_summed_delta_M.xlsx']);

        % Philips scans
        % read_workbook = fullfile(strokes_impact_dir, 'Output/extract_summed_signal/newnew', ...
        %     [out_file_str '_summed_delta_M.xlsx']);
        
        data = readtable(read_workbook, 'Sheet', read_sheet, ...
                'VariableNamingRule', 'preserve', 'ReadRowNames', true);
        data = data(all(~isnan(table2array(data)), 2), :);
        id_list = data.Participant_ID;

        % GE scans
        T1_source_dir = fullfile(onedrive, 'CE-ASL/Output/extract_roi_T1', ...
            ['combined_data_' out_file_str '_T1.xlsx']);
        T1_tbl = readtable(T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
        select_row = find(strcmp(T1_tbl.Participant_ID,'045'))-1;
        mean_T1 = mean(T1_tbl{1:select_row, :} / 1000, 'all', 'omitnan');

        % Philips scans
        % common_ids = intersect(id_list, hct_tbl.Study_ID);
        % hct_tbl_temp = hct_tbl(common_ids,:);
        % mean_T1b = mean(hct_tbl_temp{:, "T1b"}, 'omitnan');
        % T1_source_dir = fullfile(strokes_impact_dir, 'Output/extract_roi_T1', ...
        %     [out_file_str '.xlsx']);
        % T1_tbl = readtable(T1_source_dir, 'Sheet', 'mean', 'ReadRowNames', true);
        % common_ids = intersect(id_list, T1_tbl.Participant_ID);
        % T1_tbl_temp = T1_tbl(common_ids,:);
        % T1_tbl_temp(strcmp(T1_tbl_temp.Participant_ID, '1189-027'),:) = [];
        % mean_T1 = mean(table2array(T1_tbl_temp) ./ 1000, 'all', 'omitnan');

        % sw_workbook = fullfile(onedrive, 'CE-ASL/Output/error_analysis/extract_summed_signal/new', ...
        %             ['sw_cov_Visit 2_combined_data_' out_file_str '.xlsx']);
        % data_err = readtable(sw_workbook, 'Sheet', read_sheet, 'VariableNamingRule', 'preserve', 'ReadRowNames', true);
        % data_err = data_err{'sw',:};
        data_err = [];

        results.tissue = tissue_type_struct;
        results.name = out_file_str;
        results.id_list = id_list;
        results.read_sheet = read_sheet;

        for mi=1:numel(tissue_type_struct.model)
            this_model = tissue_type_struct.model{mi};
            this_model_func = this_model.model;

            numFit = numel(this_model.param_bound);
            this_model.rmse = zeros(size(id_list));
            this_model.fit = zeros(length(id_list), numFit);

            % initialise this using the length of id_list
            this_model.T1b = zeros(size(id_list));
            this_model.T1e = zeros(size(id_list));
            results.model(mi) = this_model;

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

            count = 0;
            count_fig = 1;
            for i=1:numel(id_list)
                %
                T1e_cp_id = T1e_cp(i);
                f_cp_id = f_cp(i);
                tA_cp_id = tA_cp(i);
                count = count+1;
                
                if count == 1
                    fig = figure;
                    tiled = tiledlayout(subplot_num_row, subplot_num_column, "Parent", fig, ...
                        "TileSpacing","tight", "Padding","tight");
                    sgtitle(fig, replace([this_model.name ' ' out_file_str], '_', '\_'))
                elseif mod(i-1, subplot_num_column*subplot_num_row) == 0
                    count = 1;
                    exportgraphics(fig, fullfile(out_dir, sprintf('%s_%s(%s).png', ...
                        read_sheet, this_model.name, num2str(count_fig))), "Resolution", 300)
                    count_fig = count_fig + 1;
                    fig = figure;
                    tiled = tiledlayout(subplot_num_row, subplot_num_column, "Parent", fig, ...
                        "TileSpacing","tight", "Padding","tight");
                    sgtitle(fig, replace([this_model.name ' ' out_file_str], '_', '\_'))
                end

                % GE scans
                id_list1_split = split(char(id_list{i}), '_');
                id_no_contrast = [id_list{i} '_no_contrast'];
                id = strip(id_list1_split{1}, 'left', '0')

                % Philips scan
                % id = id_list{i}

                ax = nexttile(tiled);
                hold(ax, 'on')
                title(ax, id)
                xlabel(ax, 'PLD (s)')
                ylabel(ax, '\Delta M')
                % errorbar(ax, PLD, data{i,:}, data_err, 'LineStyle', 'none', 'HandleVisibility', 'off')
                scatter(ax, PLD, data{i,:},  'HandleVisibility', 'off')

                % assign T1b 
                hct_tbl_temp = participant_details; % Uncomment for GE scans
                if isnan(hct_tbl_temp{id, "T1b"})
                    T1b = mean_T1b;
                else
                    T1b = hct_tbl_temp{id, "T1b"};
                end

                % GE scans
                if isnan(T1_tbl{id_list{i}, :}) || str2double(id) >= 45
                    T1e = mean_T1;
                else
                    T1e = T1_tbl{id_list{i}, :} / 1000;
                end

                % Philips scans
                % if isnan(T1_tbl{id_list{i}, :}) || strcmp(id, '1189-027')
                %     T1e = mean_T1;
                % else
                %     T1e = T1_tbl{id_list{i}, :} / 1000;
                % end
    
                results.model(mi).T1b(i) = T1b;
                results.model(mi).T1e(i) = T1e;

                % multi_start_solutions = zeros(numIter, numFit+2);
                multi_start_solutions = zeros(numIter, numFit+1);
                for itr=1:numIter % loop through numIter (set) of start points
                    start_point = start_point_arr(:, itr);

                    model_specific_args = this_model.model_specific_arg;

                    % Use SCM
                    if isfield(model_specific_args, 'sblood') && ...
                        isfield(model_specific_args, 'outflow')
                        if isfield(model_specific_args, 'outflow_csf')
                            [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                                alpha, lambda, SIpd, T1b, T1e, ...
                                model_specific_args.sblood, ...
                                model_specific_args.outflow,...
                                model_specific_args.outflow_csf,...
                                data{i,:}, data_err, start_point, ...
                                lower_bound, upper_bound, ...
                                this_model.fit_option);
                        else
                            [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                                alpha, lambda, SIpd, T1b, T1e_cp_id, ...
                                model_specific_args.sblood, ...
                                model_specific_args.outflow, f_cp_id, tA_cp_id, T1e, ...
                                data{i,:}, data_err, start_point, ...
                                lower_bound, upper_bound, this_model.fit_option);
                        end
                    elseif isfield(model_specific_args, 'sblood_cp') && ...
                            isfield(model_specific_args, 'outflow_cp') && ...
                            isfield(model_specific_args, 'sblood_lv') && ...
                            isfield(model_specific_args, 'outflow_lv')
                        [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                            alpha, lambda, SIpd, T1b, T1e_cp_id, T1e, ...
                            model_specific_args.sblood_cp, ...
                            model_specific_args.outflow_cp, ...
                            model_specific_args.sblood_lv, ...
                            model_specific_args.outflow_lv, f_cp_id, tA_cp_id, ...
                            data{i,:}, data_err, start_point, lower_bound, ...
                            upper_bound, this_model.fit_option);

                    % Use TCM
                    elseif isfield(model_specific_args, 'fit_kb_only') && isfield(model_specific_args, 'fit_kb_T1b')
            
                        [estimates, rmse, chisq] = this_model_func(PLD, LD, ...
                            alpha, lambda, SIpd, T1b, T1e, f_dummy, ttr_dummy, ...
                            model_specific_args.fit_kb_only, model_specific_args.fit_kb_T1b, ...
                            data{i,:}, data_err, ...
                            start_point, lower_bound, upper_bound, this_model.fit_option);
                        
                    else
                        disp(['ERROR: Neither SCM_signal nor TCM_signal ...' ...
                        'nor CP_LV_model nor sum_bloodLV_CPLV can be called.'])
                    end            
                    % multi_start_solutions(itr, :) = [rmse, chisq, estimates'];
                    multi_start_solutions(itr, :) = [rmse, estimates'];
                    
                end % End of loop through numIter (sets) of start point

                %% PICKED THE CORRECT SOLUTION!
                % find solution with minimum chisq / RMSE
                [~, I] = min(multi_start_solutions(:, 1));
                solutions = multi_start_solutions(I, :)

                results.model(mi).rmse(i) = solutions(1);
                % results.model(mi).chisq(T1bi, T1ei, i) = solutions(2);
                % for fi=1:numFit
                %     results.model(mi).fit(T1bi, T1ei, i, fi) = solutions(2+fi);
                % end
                for fi=1:numFit
                    results.model(mi).fit(i, fi) = solutions(1+fi);
                end

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

                %% plot individual fit
                % Use SCM
                if isfield(model_specific_args, 'sblood') && isfield(model_specific_args, 'outflow')
                    if isfield(model_specific_args, 'outflow_csf')
                        signal = SCM_signal(model_specific_args.sblood, model_specific_args.outflow, ...
                            outflow_csf,...
                            PLD, LD, alpha, ...
                            lambda, SIpd, T1b, T1e, ...
                            f_solution, tA_solution);
                        if model_specific_args.outflow_csf > 0
                            legend_text = sprintf('f=%.2e, t_A=%.2f, k_{out}=%.2f', ...
                                f_solution, tA_solution, outflow_csf);
                        else
                            legend_text = sprintf('f=%.2e, t_A=%.2f', ...
                                f_solution, tA_solution);
                        end
                    else
                        signal = CP_LV_model(model_specific_args.sblood, ...
                            model_specific_args.outflow, ...
                            PLD, LD, alpha, lambda, SIpd, T1b, T1e_cp_id, ...
                            f_cp_id, tA_cp_id, T1e, f_solution);
                        legend_text = sprintf('k_{CSF}=%.2f', ...
                                f_solution);
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
                        SIpd, T1b, T1e_cp_id, f_cp_id, tA_cp_id, ...
                        f_solution, tA_solution, T1e, outflow_csf);
                    legend_text = sprintf('f=%.2e, t_A=%.2f, k_{CSF}=%.2f', ...
                        f_solution, tA_solution, outflow_csf);
                % Use TCM
                elseif isfield(model_specific_args, 'fit_kb_only') && ...
                        isfield(model_specific_args, 'fit_kb_T1b')
                    signal = TCM_signal(PLD, LD, alpha, lambda, SIpd, ...
                        T1b, T1e, f_solution, tA_solution, solutions(end));
                    legend_text = sprintf('f=%.2e, t_A=%.2f, k_b=%.2f', ...
                        f_solution, tA_solution, solutions(end));
                    
                else
                    disp(['ERROR: Neither SCM_signal nor TCM_signal ...' ...
                        'nor CP_LV_model nor sum_bloodLV_CPLV can be called.'])
                end
                
                plot(ax, PLD, signal, 'DisplayName', legend_text)
                legend(ax, 'show', 'Location', 'best')
                hold(ax, 'off')
                
                save(fullfile(out_dir, sprintf('%s_%s.mat', out_file_str, read_sheet)),'results')
            end % End of loop over ids
            exportgraphics(fig, fullfile(out_dir, sprintf('%s_%s(%s).png', ...
                read_sheet, this_model.name, num2str(count_fig))), "Resolution", 300)
            
            save(fullfile(out_dir, sprintf('%s_%s.mat', out_file_str, read_sheet)),'results')
            
        end % End of loop over models

        save(fullfile(out_dir, sprintf('%s_%s.mat', out_file_str, read_sheet)),'results')
    end % End of loop over erode_size
end % End of loop over roi

toc