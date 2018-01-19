function [ des_lut ] = getDesinusoids( dmb, wb )
%getDesinusoids Determines the desinusoid files to use based on the fov information in dmb
%   The goal here is to read in the desinusoid files, read which files were used, then get the
%   fov information from those files in order to match the fov to the desinusoid file.
%   this is necessary because filename parsing of the desinusoid file, historically, has been problematic.
%   Alex Salmon - 2016.06.17

%% Look for calibration folder
apath       = dmb(1).path; % Assuming all dmb's came from same place
doubleSlash = [filesep,filesep];
networkpath = strcmp(apath(1:2),doubleSlash);
pathparts   = strsplit(apath,filesep);
pathparts(strcmp(pathparts,'')) = [];
parentpath  = strjoin(pathparts(1:end-1),filesep);
if networkpath
    parentpath = [doubleSlash, parentpath];
end
parentpathdir = dir(parentpath);
for i=1:numel(parentpathdir)
    if strcmpi(parentpathdir(i).name,'calibration')
        cal_path = fullfile(parentpath, parentpathdir(i).name);
        break;
    end
end
if ~exist('cal_path','var')
    cal_path = uigetdir(apath,'Sorry, where are the desinusoid files?');
end

%% Get desinusoid files, separate into desinusoid files and video-associated Savior data
cal_files = dir(fullfile(cal_path,'*.mat'));
nFiles    = numel(cal_files);
des_files = false(nFiles,1);
waitbar(0,wb,'Getting desinusoid information...');
for i=1:nFiles
    cal_files(i).data = load(fullfile(cal_path,cal_files(i).name));
    waitbar(i/nFiles,wb,strrep(sprintf('Reading %s...',cal_files(i).name),'_','\_'));
end
for i=1:nFiles
    waitbar(i/nFiles,wb,'Extracting FOVs...');
    if isfield(cal_files(i).data,'horizontal_fringes_filename') % then it is a desinusoid file
        cal_files(i).isdesinusoidfile = true;
        des_files(i) = true;
        % look to the horizontal_fringes_filename for fov
        for j=1:nFiles
            if strcmp(strrep(cal_files(j).name,'.mat','.avi'),cal_files(i).data.horizontal_fringes_filename)
                cal_files(i).fov = cal_files(j).data.optical_scanners_settings.raster_scanner_amplitude_in_deg;
                break;
            end
        end
        if ~isfield(cal_files(i),'fov') || isempty(cal_files(i).fov) % then we can't use the videos as evidence of the fov, guess based on filename
            desnameparts = strsplit(cal_files(i).name,'.');
            desnameparts = strsplit(desnameparts{1},'_');
            % look for 'deg' in tokens
            if ~all(cellfun(@isempty, strfind(desnameparts,'deg')))
                fovToken = desnameparts{~(cellfun(@isempty, strfind(desnameparts,'deg')))};
                if strcmpi(fovToken,'deg') % look for preceding token
                    cal_files(i).fov = str2double(strrep(desnameparts{find(~(cellfun(@isempty, ...
                        strfind(desnameparts,'deg'))))-1},'p','.'));
                else % then deg is probably part of the token
                    cal_files(i).fov = str2double(strrep(fovToken(1:strfind(fovToken,'deg')-1),'p','.'));
                end
            
            % Now try to guess the fov based on the presence of only one token that can be converted to a number by 
            % only replacing 'p'
            elseif numel(find(~all(isnan(str2double(strrep(desnameparts,'p','.')))))) == 1
                cal_files(i).fov = ...
                    str2double(strrep(desnameparts{~isnan(str2double(strrep(desnameparts,'p','.')))},'p','.'));
                % Kind of ugly, but sure.
                
            else % No reliable way of determining fov, ask user
                fovEntered = false;
                usrCancel  = false;
                while ~fovEntered && ~usrCancel
                    usrinput = inputdlg(sprintf('What is the field-of-view for %s?', cal_files(i).name),...
                        'Failure to guess FOV',1,{'0'});
                    if isempty(usrinput)
                        usrCancel = true;
                        continue;
                    end
                    if isnan(str2double(usrinput{1}))
                        beep;
                        fprintf('\nInput should be a number\n');
                        continue;
                    end
                    
                    if ~any(str2double(usrinput{1}) == cell2mat(dmb(1).fov_lut(:,2)))
                        beep;
                        re = questdlg(sprintf('The input %s does not match any FOV''s being processed in this session. Continue with this input?',usrinput{1}),...
                            'Input/FOV mismatch','Continue','Re-enter','Quit','Continue');
                        switch re
                            case 'Continue'
                                fovEntered          = true;
                                cal_files(i).fov    = str2double(usrinput{1});
                            case 'Re-enter'
                                continue;
                            case 'Quit'
                                usrCancel = true;
                                continue;
                        end
                    end
                end
            end
        end
    else
        cal_files(i).isdesinusoidfile = false;
    end
end

%% Combine into lut
des_lut = cell(numel(find(des_files)),3);
n=0;
for i=1:nFiles
    if des_files(i)
        n=n+1;
        des_lut{n,1} = cal_files(i).fov;
        des_lut{n,2} = cal_files(i).name;
        if cal_files(i).data.horizontal_warping
            des_lut{n,3} = single(cal_files(i).data.vertical_fringes_desinusoid_matrix');
        else
            des_lut{n,3} = single(cal_files(i).data.horizontal_fringes_desinusoid_matrix);
        end
    end
end

end

