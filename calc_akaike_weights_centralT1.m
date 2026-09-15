addpath('C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\My code')
close all;
clear all;
onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';
tic

function aicc = get_aicc(num_param, num_points, rmse)
    k = num_param;
    n = num_points;
    mll = -n/2 .* log(rmse.^2);
    aicc = 2*k - 2.*mll + 2*k*(k+1)/(n-k-1);
end

function weight = akaike_weight(delta_aic)
    weight = exp(-delta_aic ./ 2);
end

%% define varaibles
SIpd = 1; % this is technically not SIpd anymore - data were normalised
alpha = 0.85;
lambda = 0.9;

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

%% tissue type
tissue_prob = '0_9';
% read_sheet = 'median_times_vol_normalised';
read_sheet = 'median_normalised';
% read_sheet = 'mean_times_vol_normalised';

%% GE scans
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
LD_arr = [0.573 0.885 2.042];
PLD = sort([PLDs_eASL_PLD1000 PLDs_eASL_PLD700]) ./ 1000; % seconds
LD = sort([LD_arr LD_arr]);

gm = struct('name', 'gm', 'label', 'GM', 'erode_size', {{['_' tissue_prob]}}, ...
    'model', {{SBCM, STCM, TCM}});
wm = struct('name', 'wm','label', 'WM', 'erode_size', {{['_' tissue_prob]}}, ...
    'model', {{SBCM, STCM, TCM}});
lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
    'erode_size', {{
    'erode_size3_corrected_mask'
    }}, ...
    'model', {{STCM, STCM_csf, CPLV}});
choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
    'erode_size', {{'_mask',...
    'erode_size1_corrected_mask'
    }}, ...
    'model', {{SBCM, STCM, TCM}});

write_rootdir = fullfile(onedrive, ...
    'CE-ASL/Output/calc_akaike_weights_centralT1');
read_dir = fullfile(onedrive, 'CE-ASL/Output/fit_ASL_summed_signal_centralT1');

%% Philips scans
% PLD = [890 1300 1700 2100 2500] ./ 1000; % seconds
% LD = 1.8 * ones(size(PLD));
% 
% gm = struct('name', 'GM', 'label', 'GM', 'erode_size', {{['_' tissue_prob]}}, ...
%     'model', {{SBCM, STCM, TCM}});
% wm = struct('name', 'WM','label', 'WM', 'erode_size', {{['_' tissue_prob]}}, ...
%     'model', {{SBCM, STCM, TCM}});
% lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
%     'erode_size', {{
%     '_erode3mm', 
%     }},  ...
%     'model', {{STCM, STCM_csf}});
% choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
%     'erode_size', {{...'_mask', ...
%     '_erode1mm'
%     }}, ...
%     'model', {{SBCM, STCM, TCM}});
% 
% strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
% write_rootdir = fullfile(strokes_impact_dir, 'Output/calc_akaike_weights_centralT1');
% read_dir = fullfile(strokes_impact_dir, 'Output/fit_ASL_summed_signal_centralT1');

%%
tissue_type = {gm, ...
    lateral_ventricle,...
   choroid_plexus, ...
   wm
    };

num_points = numel(PLD);
fitNames = {'f', 'tA',...
    'k'
    };
workbook_header_centralT1 = [{'Participant_ID', 'unnormalised_weight', 'normalised_weight'} fitNames {'rmse', 'aicc'}];

% Loop through tissue type
for tis=1:numel(tissue_type)
        
    tissue_type_struct = tissue_type{tis};
    tissue_name = tissue_type_struct.name

    % change index for GE / Philips scans
    cp_out_file_str = [choroid_plexus.name choroid_plexus.erode_size{end}];
    cp_results = load(fullfile(read_dir, cp_out_file_str, ...
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

    %% Loop through masks
    erode_size_arr = tissue_type{tis}.erode_size;
    for ei=1:numel(erode_size_arr)
        out_file_str = [tissue_type{tis}.name erode_size_arr{ei}];
        results = load(fullfile(read_dir, out_file_str, ...
            sprintf('%s_%s.mat', out_file_str, read_sheet))).results;

        write_dir = fullfile(write_rootdir, out_file_str);
        if ~isfolder(write_dir)
            mkdir(write_dir)
        end

        read_sheet = results.read_sheet;
        id_list = results.id_list;

        % GE scans
        id_list_temp = cellfun(@(x) split(x, '_'), id_list, 'UniformOutput', false);
        id_list_temp = cellfun(@(x) strip(x{1}, 'left', '0'), id_list_temp, 'UniformOutput', false);
        % Philips scan
        % id_list_temp = cellfun(@(x) split(x, '-'), id_list, 'UniformOutput', false);
        % id_list_temp = cellfun(@(x) strip(x{end}, 'left', '0'), id_list_temp, 'UniformOutput', false);
         
        model_rank_header = ["Participant_ID" string(1:numel(tissue_type_struct.model))];
        model_struct = struct([]);
        fit_centralT1 = nan(numel(id_list), 3, numel(tissue_type_struct.model));
        rmse_centralT1 = nan(numel(id_list), numel(tissue_type_struct.model));
        aicc_centralT1 = nan(numel(id_list), numel(tissue_type_struct.model));
        for mi=1:numel(tissue_type_struct.model)

            T1b = results.model(mi).T1b;
            T1e = results.model(mi).T1e;

            % read fit values
            this_model = tissue_type_struct.model{mi};
            numFit = numel(this_model.param_bound)

            model_struct(mi).name = this_model.name;
            model_struct(mi).aicc = get_aicc(numFit, num_points, results.model(mi).rmse);
            model_struct(mi).fit_val = results.model(mi).fit;

            rmse_centralT1(:, mi) = arrayfun(@(i) ...
                results.model(mi).rmse(i), 1:numel(id_list))';
            aicc_centralT1(:, mi) = arrayfun(@(i) ...
                model_struct(mi).aicc(i), 1:numel(id_list))';
            for fi=1:size(results.model(mi).fit, 2)
                fit_centralT1(:, fi, mi) = arrayfun(@(i) results.model(mi).fit(i, fi), 1:numel(id_list));
            end
        end
        
        global_aicc_min = inf(numel(id_list), 1);
        for mi = 1:numel(model_struct)
            % update global min per subject
            global_aicc_min = min(global_aicc_min, aicc_centralT1(:, mi));
        end

        write_workbook = fullfile(write_dir, [read_sheet '_model_results.xlsx']);
        model_rank_workbook = fullfile(write_dir, [read_sheet '_modelranking.xlsx']);
        delta_M_workbook = fullfile(write_dir, [read_sheet '_delta_M.xlsx']);

        % initialise
        models_weights_unnormalised = NaN(numel(id_list), numel(model_struct));
        models_names = repmat({model_struct.name}, numel(id_list), 1); % rank later
        
        delta_M_fit = zeros(numel(id_list), num_points, numel(model_struct));
        for mi = 1:numel(model_struct)
            this_model = tissue_type_struct.model{mi};
            output_sheet = this_model.name;
            delta_aicc = model_struct(mi).aicc - global_aicc_min;

            % calculate weight 
            w = akaike_weight(delta_aicc);
            models_weights_unnormalised(:, mi) = akaike_weight(aicc_centralT1(:, mi) - global_aicc_min);

            model_specific_args = this_model.model_specific_arg;
            f = model_struct(mi).fit_val(:, 1);
            if size(model_struct(mi).fit_val, 2) >1
                ttr = model_struct(mi).fit_val(:, 2);
            else
                ttr = zeros(size(f));
            end
            if size(model_struct(mi).fit_val, 2) >2
                kb = model_struct(mi).fit_val(:, 3);
            else
                kb = zeros(size(f));
            end
            % Use SCM
            if isfield(model_specific_args, 'sblood') && isfield(model_specific_args, 'outflow')
                if isfield(model_specific_args, 'outflow_csf')
                    delta_M_fit(:, :, mi) = SCM_signal(model_specific_args.sblood, ...
                        model_specific_args.outflow, kb, PLD, ...
                        LD, alpha, lambda, SIpd, T1b, T1e, f, ttr);
                else
                    delta_M_fit(:, :, mi) = CP_LV_model(model_specific_args.sblood, ...
                        model_specific_args.outflow, PLD, LD, alpha, lambda, ...
                        SIpd, T1b, T1e_cp, ...
                        f_cp, tA_cp, T1e, f);
                end
                
            % Use TCM
            elseif isfield(model_specific_args, 'fit_kb_only') && isfield(model_specific_args, 'fit_kb_T1b')

                delta_M_fit(:, :, mi) = TCM_signal(PLD, LD, alpha, ...
                           lambda, SIpd, T1b, T1e, f, ttr, kb);  
            else
                disp('ERROR: Neither SCM_signal nor TCM_signal can be called.')
            end

            delta_M_tbl = array2table([str2double(id_list_temp) delta_M_fit(:, :, mi)],...
                "VariableNames", ["Participant_ID" string(PLD)]) % HARD CODE PLD
            writetable(delta_M_tbl, delta_M_workbook, 'Sheet', output_sheet)

            % write weight, f, ttr, kb to excel sheets each of
            % which represents one strategy / model :)
            
        end
        % write to a workbook with model rankings id-best model- second
        % best - third best ...
        % normalise model weights
        all_models_weights = sum(models_weights_unnormalised, 2, 'omitnan');
        models_weights_normalised = models_weights_unnormalised ./ all_models_weights;
        [sorted_models_weights_normalised, rank] = sort(models_weights_normalised, 2, 'descend');

        ranked_model_names = cell(size(models_names));
        ranked_fit_val = struct([]);
        for fi=1:3
            ranked_fit_val(fi).val =  NaN(numel(id_list), numel(model_struct));
        end

        % store model name and fits according to descending order of model weight
        for i=1:numel(id_list)
            ranked_model_names(i, :) = models_names(i, rank(i, :));
            for fi=1:3
                ranked_fit_val(fi).val(i, :) = fit_centralT1(i, fi, rank(i, :));
            end
        end
        % write model name from that with bigger to smaller weight for each person
        ranked_tbl = cell2table([id_list_temp ranked_model_names], 'VariableNames', model_rank_header);
        writetable(ranked_tbl, model_rank_workbook, 'Sheet', 'name')
        % write corresponding model weight
        ranked_tbl = array2table([str2double(id_list_temp) sorted_models_weights_normalised], ...
            'VariableNames', model_rank_header);
        writetable(ranked_tbl, model_rank_workbook, 'Sheet', 'weights')
        % write corresponding fit parameters
        for fi=1:3
            ranked_tbl = array2table([str2double(id_list_temp) ranked_fit_val(fi).val], 'VariableNames', model_rank_header);
            writetable(ranked_tbl, model_rank_workbook, 'Sheet', fitNames{fi})
        end

        % write model weigths (unnormalised, normalised, fit parameters,
        % rmse, aicc) to different sheets for different models
        for mi=1:numel(tissue_type_struct.model)
            tbl = array2table( ...
                [str2double(id_list_temp) models_weights_unnormalised(:, mi) models_weights_normalised(:, mi)...
                fit_centralT1(:,:,mi) rmse_centralT1(:, mi) aicc_centralT1(:, mi)], ...
                'VariableNames', workbook_header_centralT1);
            writetable(tbl, write_workbook, ...
                'Sheet', tissue_type_struct.model{mi}.name)
        end
    end % End of erode_size      
end % End of loop over tissue types

toc