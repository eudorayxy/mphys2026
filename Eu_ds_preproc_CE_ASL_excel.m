onedrive = 'C:\Users\eudor\OneDrive - The University of Manchester\1 MPhys Project\';
cdrive = 'C:\MPhys10902195\';
addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

%% define PLDs
PLDs_eASL_PLD1000 = [1000, 1573, 2458]; %ms
PLDs_eASL_PLD700 = [700, 1273, 2158]; %ms

dataset = 'Visit 2';
spm_dir = onedrive;

data_table = readtable([onedrive 'CE-ASL\' dataset '\visit2_data.xlsx']);

logfile_name = [onedrive 'CE-ASL\' dataset '\preproc_log.txt'];
logfile = fopen(logfile_name, 'a');

select_row = find(strcmp(data_table.ID, '039'));
data_table = data_table(select_row:end, :);

for person=1:length(data_table.ID) % test the first two
    register_success = true;
    tic
    
    %% define participant id
    id = char(data_table.ID{person});
    fprintf(logfile, '\n\nID: %s', id);
    vsize = [1.719 1.719 4]; % check this is correct

    % rootdir = [onedrive 'CE-ASL\' data id '\'];
    rootdir = fullfile(onedrive, 'CE-ASL/', dataset, id);
    
    rawdir = fullfile(rootdir, 'raw');
    cd(rawdir)

%% 
    t1_dir = fullfile(rootdir, 'structural');
    if not(isfolder(t1_dir))
        mkdir(fullfile(rootdir, 'structural'));
    end
    t1_fn = fullfile(rootdir, 'structural', '3D_T1w.nii');
    t1_nii = dir(fullfile(rawdir, ['*' char(data_table(person, :).T1w_img) '*.nii'])).name
    copyfile(t1_nii, t1_fn);

%% Seperate PLD files
    asl_dir = fullfile(rootdir, 'ASL');
    if not(isfolder(asl_dir)) 
        mkdir(asl_dir)
    end
    ce_asl_dir = fullfile(rootdir, 'CE-ASL');
    if not(isfolder(ce_asl_dir))
        mkdir(ce_asl_dir)
    end
    
    % Use id to identify which file to look for 
    % Use out as output ASL/CASL
    PLD_files(1).id = data_table{person, 'eASL_PLD700'}; 
    PLD_files(1).out = 'eASL_PLD700';
    PLD_files(1).outdir = asl_dir;
    PLD_files(1).idx = 1;
    PLD_files(1).PLDs = PLDs_eASL_PLD700;
    
    PLD_files(2).id = data_table{person, 'eASL_PLD1000'};
    PLD_files(2).out = 'eASL_PLD1000';
    PLD_files(2).outdir = asl_dir;
    PLD_files(2).idx = 1;
    PLD_files(2).PLDs = PLDs_eASL_PLD1000;

    PLD_files(3).id = data_table{person, 'CeASL_PLD1000'};
    PLD_files(3).out = 'CeASL_PLD1000';
    PLD_files(3).outdir = ce_asl_dir;
    PLD_files(3).idx = 1;
    PLD_files(3).PLDs = PLDs_eASL_PLD1000;

    
    for file = 1:length(PLD_files)
        if iscell(PLD_files(file).id)
            PLD_id = PLD_files(file).id{1};
        else
            PLD_id = PLD_files(file).id;
        end
        Output_id = PLD_files(file).out;
        file_idx = PLD_files(file).idx;
        out_dir = PLD_files(file).outdir;
        
        if ~isnan(PLD_id)
            cd(rawdir)
            
            fprintf(logfile, '\nfile index: %d\n', file_idx);
            
            PLD_dir = dir(['*' PLD_id '*.nii']); % find file
            if ~isempty(PLD_dir)
                PLD_nom = PLD_dir(file_idx).name
                fprintf(logfile, PLD_nom);
                PLD_im = double(load_nii(PLD_nom).img);
                fprintf(logfile, '\nNumber of volumes: %d\n', size(PLD_im, 4));
            
            else
                % fprintf(logfile, 'error no match for PLD_file id: %s\n', PLD_id);
                % error(['No folder matching *' PLD_id '* found.']);
                fprintf(logfile, 'error PLD_dir PLD_id: %s is empty\n', PLD_id);
                error(['No folder matching *' PLD_id '* found.']);
            end

            if size(PLD_im, 4) == 5
            
                PLDs = PLD_files(file).PLDs;
                PLD_nii_path_holder = cell(length(PLDs), 1);
                for PLD_idx=1:length(PLDs)
                    PLD = PLDs(PLD_idx);
                    PLD_volume = PLD_im(:,:,:,PLD_idx);
                    PLD_volume_nii = make_nii(PLD_volume, vsize);
                    PLD_volume_nii_path = fullfile(out_dir, [Output_id '_' num2str(PLD) '.nii']);
                    PLD_nii_path_holder{PLD_idx} = PLD_volume_nii_path;
                    save_nii(PLD_volume_nii, PLD_volume_nii_path);
                    centre_header_file(PLD_volume_nii_path);
                end
                
                M0 = PLD_im(:,:,:,5);
                M0_nii = make_nii(M0,vsize);
                M0_nii_path = fullfile(out_dir, [Output_id '_M0.nii']);
                save_nii(M0_nii, M0_nii_path);
                centre_header_file(M0_nii_path);
                
                if nnz(M0) ~= 0
                    out = Eu_register_x(t1_fn, M0_nii_path, PLD_nii_path_holder);
                else
                    register_success = false;
                    fprintf(logfile, '\n Registration failed. M0_nii %s is all zeros \n', M0_nii_path);
                end
            end
        end
    end

    %% Segment T1w image
    % if register_success
    %     Eu_segment(t1_fn);
    % else
    %     fprintf(logfile, '\nSegmentation failed\n');
    % end
    
    Eu_segment(spm_dir, t1_fn)     
    
    elapsed_time = toc;
    fprintf(logfile, '\nelapsed time: %.2f s\n', elapsed_time);

end
fprintf(logfile, '\n');
fclose(logfile);
