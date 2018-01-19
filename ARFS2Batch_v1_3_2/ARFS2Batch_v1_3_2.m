%% Applies the parameters in a .dmb to a user defined selection of videos
restoredefaultpath; clear all; close all; clc; %#ok<*CLSCR>
%% Get fx's
addpath(fullfile(pwd,'fx'));

%% Display Instructions (todo)

%% Get .dmbs
[dmb, term] = getDmbs(pwd);
if term 
    clear all;
    return;
end
%% Create diary (Tom's addition)
batch_path = strrep(dmb(1).path,'/','//');
diary_file = sprintf('%slog.txt', batch_path);
diary(diary_file);

%% Initialize master waitbar
wb = waitbar(0,'Analyzing AOSLO image sequences');
set(wb,'Resize','on');

%% Save dmb as a .mat and the stdout/stderr as a txt file for troubleshooting/debugging.
timestamp       = strjoin(strread(num2str(fix(clock)),'%s')','_'); %#ok<*DSTRRD>
dmbdata_fname   = [timestamp,'_dmbdata.mat'];
outerr_fname    = [timestamp,'_stdout.txt'];
outerr_fid      = fopen(fullfile(dmb(1).path,outerr_fname),'wt');
if outerr_fid == -1
    fprintf('Unable to create %s for error documentation.\n',outerr_fname);
end

%% Log path in outerr
for i=1:numel(dmb)
    fprintf(outerr_fid, '%s\n', dmb(i).path);
end

%% Get FOVs
[fov_lut, dmb] = getFOV(dmb, outerr_fid, wb);

%% Get .avi's
[dmb, term] = getAvis(dmb);
if term
    clear all;
    return;
end

%% Get ARFS parameters
[dmb, term] = getArfsParams(dmb);
if term
    clear all;
    return;
end

%% Get confirmation before running ARFS (todo)

%% Get the total number of videos to be processed
nVidsTotal = 0;
for i=1:numel(dmb)
    nVidsTotal = nVidsTotal + numel(dmb(i).avis);
end

%% Determine desinusoid file properties
desinusoid_lut = getDesinusoids(dmb, wb);

%% Run ARFS and make .dmb's
n=0;
try
    for i=1:numel(dmb)
        for j=1:numel(dmb(i).avis)
            % shortcuts
            vidpath                 = dmb(1).aviPath;
            
            vidname                 = dmb(i).avis{j};
            vidnum                  = dmb(i).vidnums{j};
            arfsParameters          = dmb(i).pack;
            arfsParameters.fname    = vidname;
            
            % Update waitbar and outerr
            n=n+1;
            set(wb, 'name', sprintf('%s (%i/%i)',vidname,n,nVidsTotal));
            waitbar(n/nVidsTotal, wb, strrep(sprintf('Working on %s...',vidname),'_','\_'));
            
            %% Read and Desinusoid video
            % check if vidnum in fov_lut
            if ~any(strcmp(fov_lut(:,1),vidnum))
                fprintf('\nNo .mat file associated with %s\n\n',vidname);
                fprintf(outerr_fid,'\nNo .mat file associated with %s\n\n',vidname);
                continue;
            end
            fov         = fov_lut{strcmp(fov_lut(:,1),vidnum),2};
            des_matrix  = desinusoid_lut{cellfun(@(x) x == fov, desinusoid_lut(:,1)), 3};
            
            % Read video
            images = readAndDesinusoid(vidpath, vidname, des_matrix, wb);
            if isa(images,'MException')
                recordErr(images,outerr_fid);
                continue; % Who knows, maybe the next video will go better.
            end

            %% Run ARFS
            tic
            dmb(i).arfs(j).data = arfsFx(images, arfsParameters, wb);
            if isa(dmb(i).arfs(j).data,'MException')
                recordErr(dmb(i).arfs(j).data,outerr_fid);
                continue;
            end
            
            % Make .dmb's
            dmb(i).arfs(j).rfList = makeDmbs(dmb(i), dmb(i).arfs(j).data);
            
            % Save progress
            save(fullfile(dmb(1).path,dmbdata_fname),'dmb');
        end
    end
    close(wb);
    fclose(outerr_fid);
catch MException
    recordErr(MException,outerr_fid);
    
    close(wb);
    fclose(outerr_fid);
end
runtime=toc
fprintf(['\nDone! If any unexpected errors occurred,\nfeel free to email these files to asalmon@mcw.edu:',...
    '\n\nerror log: %s\nyour parameters and data: %s\npath: %s\n'],outerr_fname,dmbdata_fname,dmb(1).path);
diary off







