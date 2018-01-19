function [ arfs_data, images ] = arfsFx( images, parameters, wb )
%arfsFx is a callable version of ARFS used for analysis of its function
% This version is tailored to ARFS2Batch.m

try
    %% Get user input parameters
    if exist('arfs_data','var') % for debugging
        clear arfs_data;
    end
    arfs_data.name                = parameters.fname;
    arfs_data.mtskip              = parameters.mtskip;
    arfs_data.minFramesPerCluster = str2double(parameters.framesPerCluster);

    %% Add functions to path
    addpath(fullfile(pwd,'fx','ARFS'));

    %% STEP 1: Process video
    arfs_data.nFrames = numel(images);
    arfs_data.frames  = (1:arfs_data.nFrames)';
    arfs_data.size    = size(images{1});
    
    %% STEP 2: INTENSITY-BASED SCORING
    arfs_data = getInt(images, arfs_data, wb);
    
    %% STEP 3: INTRA-FRAME MOTION-BASED SCORING
    arfs_data = getIFM(images, arfs_data, wb);

    %% STEP 4: TRACK MOTION
    % Set up search window for NCC: 2/3 ht wd
    arfs_data.searchWinSize = round(2/3.*arfs_data.size);
    arfs_data = getMT(images, arfs_data, wb); % will only do 1st pass if mtskip
    
    %% STEP 5: CLUSTER ANALYSIS OF FIXATIONS
    if ~arfs_data.mtskip
        arfs_data = getClusters(arfs_data, wb);
        arfs_data = getP2C(arfs_data, wb);
    else
        arfs_data.rejected.outliers_P2C = [];
    end
    
    %% STEP 6: SORTING/REPORTING
    arfs_data = finalRejection(arfs_data);
    arfs_data.finalScores = arfs_data.scores.sumRsqs;
    
    waitbar(1,wb,strrep(sprintf('Done analyzing %s',arfs_data.name),'_','\_'));
                        
%% Error Handling
catch MException
    fprintf('\nI''m sorry I failed you: %s\n', parameters.fname);
    fprintf(MException.message);
    fprintf('\n');
    arfs_data = MException;
end
end





