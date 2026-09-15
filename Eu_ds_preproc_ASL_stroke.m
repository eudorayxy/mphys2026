onedrive = 'C:\Users\c01712ey\OneDrive - The University of Manchester\1 MPhys Project\';
network_drive = '\\nasr.man.ac.uk\mhsrss$\snapped\replicated\sidd-mcr\mphys_2026\';

cdrive = 'C:\MPhys10902195\';
addpath([onedrive 'CE-ASL\CE-ASL'])
addpath([onedrive 'spm12'])
addpath([onedrive 'fm_toolbox'])

%% define PLDs
PLDs = [890 1300 1700 2100 2500]; %ms
LD = 1800; %ms

spm_dir = onedrive;

logfile_name = fullfile(network_drive, "Stroke_Impact_6mControls", "preproc_log.txt");
logfile = fopen(logfile_name, 'a');

id_list = readtable(fullfile(network_drive, "Stroke_Impact_6mControls", "data_log.csv")).id;

select_row = find(strcmp(id_list, '1189-035'));
id_list = id_list(select_row:end);

% vsize = [3 3 5]; % mm

for person=1:length(id_list)
    M0_present = false;
    tic
    
    %% define participant id
    id = char(id_list{person});
    fprintf(logfile, '\n\nID: %s', id);
    
    % rootdir = [onedrive 'CE-ASL\' data id '\'];
    rootdir = fullfile(network_drive, 'Stroke_Impact_6mControls', id);
    
    rawdir = fullfile(rootdir, 'raw');
    cd(rawdir)

%% 
    t1_dir = fullfile(rootdir, 'structural');
    if not(isfolder(t1_dir))
        mkdir(fullfile(rootdir, 'structural'));
    end
    t1_fn = fullfile(rootdir, 'structural', '3D_T1w.nii');
    t1_dir = dir(fullfile(rawdir, '3DT1*.nii'));
    if ~isempty(t1_dir)
        t1_nii = t1_dir.name;
        copyfile(t1_nii, t1_fn);
    else
        fprintf(logfile, '\n"3DT1*.nii" not present - skip to next subject');
        continue
    end

%% Seperate PLD files
    asl_dir = fullfile(rootdir, 'ASL');
    if not(isfolder(asl_dir)) 
        mkdir(asl_dir)
    end

    M0_dir = dir(fullfile(rawdir, '*M0*.nii')); % find M0 file
    if ~isempty(M0_dir)
        M0_present = true;
        M0_nii = M0_dir.name;
        copyfile(fullfile(rawdir, M0_nii), fullfile(asl_dir, M0_nii))
        M0_nii_path = fullfile(asl_dir, M0_nii);
    end

    PLD_nii_path_holder = cell(length(PLDs), 1);
    count = 0;
    for p = 1:length(PLDs)
        cd(rawdir)
            
        fprintf(logfile, '\nPLD: %d\n', PLDs(p));
        
        PLD_dir = dir(['*PLD' num2str(PLDs(p)) '*.nii']); % find ASL file
        if ~isempty(PLD_dir)
            PLD_nom = PLD_dir(1).name
            fprintf(logfile, PLD_nom);
            copyfile(fullfile(rawdir, PLD_nom), fullfile(asl_dir, PLD_nom))
            PLD_nii_path_holder{p} = fullfile(asl_dir, PLD_nom);
        else
            fprintf(logfile, 'error PLD_dir PLD: %d is empty\n', PLDs(p));
            disp(['No file matching *PLD' num2str(PLDs(p)) '* found.']);
            count = count + 1;
            continue
        end
    end

    if count == length(PLD_nii_path_holder)
        PLD_nii_path_holder = {};
    end

    if M0_present
        Eu_register_x(t1_fn, M0_nii_path, PLD_nii_path_holder);
    else
        fprintf(logfile, 'M0 not present - registration failed');
    end
    Eu_segment(spm_dir, t1_fn)     
    
    elapsed_time = toc;
    fprintf(logfile, '\nElapsed time: %.2f s\n', elapsed_time);

end
fprintf(logfile, '\n');
fclose(logfile);
