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
read_sheet = 'median_times_vol_normalised';
read_sheet_arr= {'median_normalised', 'median_normalised', 'median_normalised',...
    'mean_times_vol_normalised',  'mean_times_vol_normalised'};
% read_sheet = 'mean_times_vol_normalised';

% models
SBCM = struct('name', 'SBCM', 'label', 'SBCM');
STCM = struct('name', 'STCM', 'label', 'STCM');
STCM_csf = struct('name', 'STCM_LV', 'label', 'STCM\newline+outflow');
TCM = struct('name', 'TCM', 'label', 'TCM');
CPLV = struct('name', 'CP_LV', 'label', 'blood-\newlineCP-LV');

%% GE scans
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

%% Philips scans
% gm = struct('name', 'GM', 'label', 'GM', 'erode_size', ['_' tissue_prob], ...
%     'model', {{SBCM, STCM, TCM}});
% wm = struct('name', 'WM','label', 'WM', 'erode_size', ['_' tissue_prob], ...
%     'model', {{SBCM, STCM, TCM}});
% lateral_ventricle = struct('name', 'lateral ventricles', 'label', 'LV', ...
%     'erode_size', '_erode3mm', ...
%     'model', {{STCM, STCM_csf}});
% choroid_plexus = struct('name', 'choroid plexus', 'label', 'CP', ...
%     'erode_size', '_erode1mm', ...
%     'model', {{SBCM, STCM, TCM}});
% 
% strokes_impact_dir = fullfile(network_drive, 'Stroke_Impact_6mControls');
% calc_akaike_weights_dir = fullfile(strokes_impact_dir, 'Output/calc_akaike_weights_centralT1');

%%
tissue_type = {gm, wm,...
    choroid_plexus,...
    lateral_ventricle, ...
    inf_lateral_ventricle
    };

fig = figure;
tiled = tiledlayout(fig, 1, numel(tissue_type), 'TileSpacing', 'none', 'Padding','compact');
% title(tiled, ['Model Weight - ' replace(read_sheet, '_', '\_')])
for tis=1:numel(tissue_type)
    tissue_type_struct = tissue_type{tis};
    all_data = [];
    xGroup = [];

    read_sheet = read_sheet_arr{tis};
    out_file_str = [tissue_type{tis}.name tissue_type{tis}.erode_size];
    read_workbook = fullfile(calc_akaike_weights_dir, out_file_str, [read_sheet '_model_results.xlsx']);

    names = cell(1,numel(tissue_type_struct.model));
    for mi=1:numel(tissue_type_struct.model)
        names{mi} = replace(tissue_type_struct.model{mi}.label, '_', '\_');
        tbl = readtable(read_workbook, 'Sheet', tissue_type_struct.model{mi}.name, 'ReadRowNames', true);
        tbl('15',:) = [];
        tbl('53',:) = [];
        tbl = tbl.normalised_weight;
        all_data = [all_data; tbl];
        xGroup = [xGroup;
            repmat(mi, length(tbl), 1)];
    end
    ax = nexttile(tiled);
    title(ax, tissue_type_struct.label)
    ax.Box = 'on';      
    hold(ax, 'on')
    b = boxchart(ax, xGroup, all_data);
    ylim(ax, [0 1])
    xticks(ax, 1:numel(names))
    xticklabels(ax, names) 

    if tis ~= 1
        yticklabels(ax, [])
    else
        ylabel(ax, 'Model Weight')
    end

end

exportgraphics(fig, fullfile(onedrive, ...
    'CE-ASL/Output/plot_boxplot_averaged_curves/model_weight.png'), Resolution=300)