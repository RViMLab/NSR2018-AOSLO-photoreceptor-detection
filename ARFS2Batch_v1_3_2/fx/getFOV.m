function [fovData, dmb] = getFOV(dmb, err_fid, wb)
%getFOV Gets the fields of view for all videos in dmb
% Stolen with malice from Chris Langlo 2015.12.23

filepath    = dmb(1).path;
saviorpath  = filepath;
videopath   = filepath;

%% Get all .mat files
saviorData = dir(fullfile(saviorpath,'*.mat'));
if isempty(saviorData)
    saviorpath = uigetdir(filepath,'Select folder containing .mat files with video information');
    saviorData = dir(fullfile(saviorpath,'*.mat'));
end
% Place names in cell array
saviorNames = cell(numel(saviorData),1);
for i=1:numel(saviorNames)
    saviorNames{i} = saviorData(i).name;
end

%% Get all .avi files
videoData = dir(fullfile(videopath,'*.avi'));
if isempty(videoData)
    videopath = uigetdir(filepath,'Select folder containing .avi files');
    videoData = dir(fullfile(videopath,'*.avi'));
end
% Place names in cell array
videoNames = cell(numel(videoData),1);
for i=1:numel(videoNames)
    videoNames{i} = videoData(i).name;
end

%% For every video, find a .mat that matches its video number and extract FOV
waitbar(0, wb, 'Extracting FOVs...');
videoNumbers = cell(numel(videoNames),1);
fovs         = zeros(numel(videoNames),1);
removeThese  = false(numel(videoNames),1);
for i=1:numel(videoNames)
    waitbar(i/numel(videoNames), wb);
    
    % Get all video numbers only once
    nameparts  = strsplit(videoNames{i},'.');
    nameparts  = strsplit(nameparts{1},'_');
    thisVidNum = nameparts{end}; % Assumes video number is last token
    % Check if this video number is already in videoNumbers
    if ~any(strcmp(thisVidNum, videoNumbers))
        videoNumbers{i} = thisVidNum;
    else
        removeThese(i) = true;
        continue;
    end
    % Check if this video number can be found in a savior file name
    theseMatFiles = find(~cellfun(@isempty, strfind(saviorNames, ['_',thisVidNum,'.mat']))); %#ok<*EFIND>
    if isempty(theseMatFiles)
        fprintf(err_fid, 'No .mat file found for %s',videoNames{i});
        fprintf('No .mat file found for %s',videoNames{i});
        continue;
    end
    
    % Try to extract FOV from these .mat files
    for j=1:numel(theseMatFiles)
        m = load(fullfile(saviorpath, saviorNames{theseMatFiles(j)}));
        if isfield(m,'optical_scanners_settings')
            fovs(i) = m.optical_scanners_settings.raster_scanner_amplitude_in_deg;
            break;
        end
        if j==numel(theseMatFiles)
            fprintf(err_fid,'No FOV found for %s',videoNames{i});
            fprintf('No FOV found for %s',videoNames{i});
        end
    end
end
videoNumbers(removeThese)   = [];
fovs(removeThese)           = [];

%% Make lookup table
fovData = horzcat(videoNumbers, num2cell(fovs));

%% Summarize information
% Get number of unique fovs
uniqueFOVs  = unique(fovs);
fovSummary  = cell(numel(uniqueFOVs),1);
% Construct fov summary
for i=1:numel(videoNumbers)
    fovIndex = find(fovData{i,2} == uniqueFOVs);
    if isempty(fovSummary{fovIndex}) % start string
        fovSummary{fovIndex} = [fovData{i,1},'-',fovData{i,1}];
    else % build on string
        if fovData{i,2} == fovData{i-1,2}
            % replace last token with current video number
            fovSummary{fovIndex}(end-numel(fovData{i,1})+1:end) = fovData{i,1};
        else
            fovSummary{fovIndex} = [fovSummary{fovIndex}, ', ',fovData{i,1},'-',fovData{i,1}];
        end
    end
end
% Collapse isolated videos
for i=1:numel(uniqueFOVs)
    fovGroups = strsplit(fovSummary{i},', ');
    for j=1:numel(fovGroups)
        vidBounds = strsplit(fovGroups{j},'-');
        if strcmp(vidBounds{1},vidBounds{2})
            fovGroups{j} = vidBounds{1};
        end
    end
    fovSummary{i} = strjoin(fovGroups,', ');
end
% Add fov labels
for i=1:numel(uniqueFOVs)
    fovSummary{i} = ['FOV ',sprintf('%1.2f',uniqueFOVs(i)),': ',fovSummary{i}];
end

%% Display summary
msgbox(fovSummary, 'FOVs');

%% Add info to dmb
dmb(1).fov_lut = fovData;
dmb(1).allAvis = videoNames;
dmb(1).aviPath = videopath;

end








