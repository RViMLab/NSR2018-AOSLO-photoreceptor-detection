function [ data ] = getMT( images, data, wb )
%getMT tracks interframe motion in a video

gf  = data.frames;
nrf = numel(gf);

%% Set pre-motion tracking rejection thresholds
bf  = ~false(nrf,1);
thr = 2;
while all(bf)
    % Intra-frame motion
    ifm_bad = data.scores.sumRsqs < mean(data.scores.sumRsqs) - (thr * std(data.scores.sumRsqs));
    % Intensity
    int_bad = data.scores.int < mean(data.scores.int) - (thr * std(data.scores.int));
    
    bf = or(ifm_bad, int_bad);
    thr = thr + 0.25;
end

%% Eliminate bad frames
data.rejected.preMT_IFM = gf(ifm_bad);
data.rejected.preMT_INT = gf(int_bad);

if any(bf)
    data = removeFrames(data,bf);
    gf = data.frames;
end

%% Initialize
nrf        = numel(gf);    % Number of Remaining Frames
nComps     = nrf-1;        % Number of Comparisons
track      = zeros(nrf,2); % Positions
nccs       = zeros(nrf,1); % Normalized cross correlation coefficients
ancc       = zeros(nrf,1); % Average NCC's
fails      = false(nrf,1); % Failures to find a distinct peak

% Elliptical mask for NCC cropping:
% 1, first pass
[X, Y] = meshgrid(1:(2*data.size(2)-1), 1:(2*data.size(1)-1));
memX2  = data.searchWinSize(2)^2;
memY2  = data.searchWinSize(1)^2;
memX2memY2 = memX2*memY2;
data.ellipticalMask1 = memY2*(X-data.size(2)).^2 + memX2*(Y-data.size(1)).^2 <= memX2memY2;
% 2, if first pass fails and convolution is necessary
shrink = 0.85; % anecdotally related to convSize, see below
memY  = shrink*data.searchWinSize(1);
memX  = shrink*data.searchWinSize(2);
memX2 = memX^2;
memY2 = memY^2;
memX2memY2 = memX2*memY2;
data.ellipticalMask2 = memY2*(X-data.size(2)).^2 + memX2*(Y-data.size(1)).^2 <= memX2memY2;
% Convolution parameters for NCC smoothing:
convType  = 'gaussian';
convSize  = 10;
convSigma = 1;
data.convFilter = fspecial(convType,convSize,convSigma);

%% 1st pass: Scan video and get a preliminary track
for i=1:nComps
    waitbar(i/nComps,wb,sprintf('Calculating movement between frames %i and %i...',gf(i),gf(i+1)));
    
    [nccs(i), dx, dy, fails(i)] = tryFF(images{gf(i+1)}, images{gf(i)}, data);
    
    track(i+1,1) = dx + track(i,1);
    track(i+1,2) = dy + track(i,2); %NOTE: in cartesian coords
    if i==1 || (~fails(i) && fails(i-1))
        ancc(i) = nccs(i);
    elseif fails(i) && ~fails(i-1)
        ancc(i) = nccs(i-1);
    else
        ancc(i) = (nccs(i)+nccs(i-1))/2;
    end
    
end

%% Pad the last element in nccs
nccs(end) = nccs(end-1);
ancc(end) = nccs(end-1);

if all(fails(1:end-1))
    data.mtskip = true;
    data.forcedMtskip = true;
    data.saccades = zeros(nrf,1);
    data.rejected.MT_fail       = gf;
    data.rejected.outliers_NCC  = [];
    data.scores.ncc = prepScore(ancc,'dir');
    data.x = track(:,1);
    data.y = track(:,2);
    return;
end

%% Check out early
if ~any(fails(1:end-1)) || data.mtskip
    bf = false(nrf,1);
    data.saccades = ones(nrf,1);
    if any(fails(1:end-1))
        [ancc, bf] = getANCC(fails, ancc, nccs);
        data.rejected.MT_fail = gf(bf);
    else
        data.rejected.MT_fail = [];
    end
    
    % Eliminate some poorly overlapping frames
    norm_ancc = ancc < mean(ancc(ancc~=0)) - (3*std(ancc(ancc~=0)));
    data.rejected.outliers_NCC = gf(norm_ancc(ancc~=0));
    data.rejected.smallClusters = [];
    
    data.scores.ncc = prepScore(ancc,'dir');
    data.x          = track(:,1);
    data.y          = track(:,2);
    
    bf = or(bf, norm_ancc);
    if any(bf)
        data = removeFrames(data,bf);
    end
    
    return;
end

%% Preallocate and initialize community lists
detainees     = false(nrf,1); % frames that correlate poorly with neighbors
lkgfList      = false(nrf,1); % Last Known Good Frame (lkgf)
firstCitzList = false(nrf,1);

%% Quickly round up known criminals and find lkgf's
for i=1:nComps
    if fails(i) && not(detainees(i))
        lkgfList(i) = true;
        % Every subsequent failure should be detained
        for j=i+1:nComps
            if fails(j)
                detainees(j) = true;
            else
                break;
            end
        end
    end
end

%% Find first citizens
if ~fails(1)
    firstCitzList(1) = true;
end
for i=1:nComps-1
    if fails(i) && ~fails(i+1)
        firstCitzList(i+1) = true;
    end
end

%% Handle possibility that first frame(s) is/are bad
if fails(1)
    % Initiate track at first good frame
    getGoods      = find(~fails);
    firstGood     = getGoods(1);
    lkgfList(1)   = false;
    detainees(1)  = true;
    % Fix track for sake of simplicity
    xshift = -track(firstGood,1);
    yshift = -track(firstGood,2);
    track(firstGood:end,1) = track(firstGood:end,1) + xshift;
    track(firstGood:end,2) = track(firstGood:end,2) + yshift;
end

%% Handle possibility that last frame is bad
if fails(end)
    detainees(end) = true;
else
    if ~fails(end-1)
        lkgfList(end) = true;
    end
end

%% Attempt to link communities in the case of a single bad frame
waitbar(0,wb,'Linking groups of frames...');
for i=1:nrf-2
    waitbar(i/(nrf-2),wb);
    if lkgfList(i) && firstCitzList(i+1)
        [nccScore, dx, dy, fail] = tryFF(images{gf(i+2)}, images{gf(i)}, data);
        if ~fail
            detainees(i+1)      = true;
            lkgfList(i)         = false;
            firstCitzList(i+1)  = false;
            fails(i)            = false;
            xshift              = track(i,1) + dx - track(i+2,1);
            yshift              = track(i,2) + dy - track(i+2,2);
            track(i+2:end,1)    = track(i+2:end,1) + xshift;
            track(i+2:end,2)    = track(i+2:end,2) + yshift;
            nccs(i)             = nccScore;
            ancc(i)             = (nccs(i) + nccs(i-1))/2;
            ancc(i+2)           = (nccs(i) + nccs(i+2))/2;
        end
    end
end

%% Establish communities
citzInd     = find(firstCitzList);
lkgfInd     = find(lkgfList);
if length(citzInd)~=length(lkgfInd)
    lastFirst = citzInd(end);
    lastLast  = lastFirst+1;
    lkgfInd(end+1) = lastLast;
end
commSize     = lkgfInd - citzInd + 1; % inclusive
commLimits   = horzcat(citzInd,lkgfInd,commSize);
nCommunities = numel(commSize);

%% Consider the neglected last frames
if ~lkgfList(end)
    I = find(lkgfList);
    lastLast = I(end);
    detainees(lastLast+1:end) = true;
end

%% Find saints (frames closest to the community centroid)
% The idea here is the frame closest to the centroid is the best target for a new saccade group.
saints = false(nrf,1);
for i=1:nCommunities
    bounds = commLimits(i,1):commLimits(i,2);
    if commLimits(i,3) < 3
        saintInd = bounds(1); % saint always same as firstCitz
    elseif commLimits(i,3) == 3
        saintInd = bounds(2); % make saint different from firstCitz and LKGF
    else
        commCentroid = mean(track(bounds,:),1);
        dists = sqrt(((track(bounds,1) - commCentroid(1)).^2) + ((track(bounds,2) - commCentroid(2)).^2));
        [~,I] = sort(dists);
        
        % Choose the first element of I that is neither bounds(1) nor bounds(end)
        n=1;
        while I(n) == bounds(1) || I(n) == bounds(end)
            n=n+1;
        end
        saintInd = bounds(I(n));
    end
    saints(saintInd) = true;
end

%% 2nd pass: Handle communities
absorbed = false(nCommunities,1);
% any unique element of saccadeGroups needs to be clustered separately
saccadeGroups = zeros(nrf,1);
for i=1:nCommunities
    if absorbed(i)
      continue;
    end
    
    bounds = commLimits(i,1):commLimits(i,2);
    saccadeGroups(bounds,1) = i*ones(numel(bounds),1);
    
    %% Set up template frames
    templateFirstCitzInd    = commLimits(i,1);
    templateFirstCitzImg    = images{gf(templateFirstCitzInd)};
    
    templateLKGFInd         = commLimits(i,2);
    templateLKGFImg         = images{gf(templateLKGFInd)};
    
    if commLimits(i,3) >= 3
        I = find(saints);
        templateSaintInd = I(i);
        templateSaintImg = images{gf(templateSaintInd)};
    end

    %% Set up source frames
    for j=1:nCommunities
        if j<=i || absorbed(j)
            continue;
        end
        
        currentProgress = (i/nCommunities) + ((((i+1)/nCommunities) - (i/nCommunities))*(j/nCommunities));
        waitbar(currentProgress,wb,sprintf('Calculating movement between groups %i and %i...',i,j));
        
        absorbeeBounds  = commLimits(j,1):commLimits(j,2);
        
        nccGrid = zeros(3,1);
        xShifts = nccGrid;
        yShifts = nccGrid;
        fails   = ~false(3,1); % guilty until proven innocent
        
        %% Compare sample first against template first
        sampleFirstCitzInd = commLimits(j,1);
        sampleFirstCitzImg = images{gf(sampleFirstCitzInd)};
        
        [nccGrid(1),dx,dy,fails(1)] = tryFF(sampleFirstCitzImg, templateFirstCitzImg, data);

        xShifts(1) = track(templateFirstCitzInd,1) + dx - track(sampleFirstCitzInd,1);
        yShifts(1) = track(templateFirstCitzInd,2) + dy - track(sampleFirstCitzInd,2);
        
        if commLimits(i,3) >= 3
            %% Compare sample first against template saint
            [nccGrid(2),dx,dy,fails(2)] = tryFF(sampleFirstCitzImg, templateSaintImg, data);

            xShifts(2) = track(templateSaintInd,1) + dx - track(sampleFirstCitzInd,1);
            yShifts(2) = track(templateSaintInd,2) + dy - track(sampleFirstCitzInd,2);
            
        end
        
        %% Compare last against last
        sampleLKGFInd   = commLimits(j,2);
        sampleLKGFImg   = images{gf(sampleLKGFInd)};
        
        [nccGrid(3),dx,dy,fails(3)] = tryFF(sampleLKGFImg, templateLKGFImg, data);

        xShifts(3) = track(templateLKGFInd,1) + dx - track(sampleLKGFInd,1);
        yShifts(3) = track(templateLKGFInd,2) + dy - track(sampleLKGFInd,2);
        
        % Update nccs for both template and sample lkgf since they are likely 0.
        if nccGrid(3) > nccs(templateLKGFInd)
            nccs(templateLKGFInd) = nccGrid(3);
            ancc(templateLKGFInd) = (nccGrid(3)+nccs(templateLKGFInd-1))/2;
        end
        if nccGrid(3) > nccs(sampleLKGFInd)
            nccs(sampleLKGFInd) = nccGrid(3);
            ancc(sampleLKGFInd) = (nccGrid(3)+nccs(sampleLKGFInd-1))/2;
        end
        
        
        if all(fails)
            saccadeGroups(absorbeeBounds) = j*ones(numel(absorbeeBounds),1);
            continue;
        end
        saccadeGroups(absorbeeBounds) = i*ones(numel(absorbeeBounds),1);
        
        % Absorb community j into i
        absorbed(j) = true;
        
        %% Calculate weighted average vector
        % in future, I bet we can get this down to one line
        dxPrime = sum(xShifts.*(nccGrid.^2))/sum(nccGrid.^2);
        dyPrime = sum(yShifts.*(nccGrid.^2))/sum(nccGrid.^2);

        %% Shift community to new position
        track(absorbeeBounds,1) = track(absorbeeBounds,1) + dxPrime;
        track(absorbeeBounds,2) = track(absorbeeBounds,2) + dyPrime;
        
    end
end

%% Check if detainees belong with saints
convicts = false(nrf,1);
if any(detainees)
    
    I_det   = find(detainees);
    I_saint = find(saints);
    
    nDet = numel(I_det);
    for i=1:nDet
        detInd = I_det(i);
        detImg = images{gf(detInd)};
        
        waitbar(i/nDet,wb,sprintf('Finding a home for frame %i...',gf(detInd)));
        
        badFit = false;
        for j=1:nCommunities
            poInd   = I_saint(j); % parole officer
            poImg   = images{gf(poInd)};
            [detNcc,dx,dy,fail] = tryFF(detImg, poImg, data);
            
            if ~fail
                track(detInd,1) = track(poInd,1) + dx;
                track(detInd,2) = track(poInd,2) + dy;
                saccadeGroups(detInd) = saccadeGroups(poInd);
%                 fprintf('Frame %i moved to frame %i\n', gf(detInd), gf(poInd));
                fails(detInd) = false;
                badFit = false;
                if detNcc > nccs(detInd)
                    nccs(detInd) = detNcc;
                    ancc(detInd) = (detNcc+nccs(poInd))/2;
                end
                break;
            else
                badFit = true;
            end
        end
        if badFit
            convicts(detInd) = true;
        end
    end
end

%% Determine whether to force MT skip, i.e., if eliminating convicts would result in all clusters < mfpc
mfpc = data.minFramesPerCluster;
bf_small = false(nrf,1);
uniqueGroups = unique(saccadeGroups(saccadeGroups~=0));
sizes = zeros(numel(uniqueGroups),1);
for i=1:numel(uniqueGroups)
    sizes(i) = numel(find(saccadeGroups==uniqueGroups(i)));
end
smallComms = sizes < mfpc;
if ~all(smallComms) % eliminate all the small communities
    for i=1:numel(uniqueGroups)
        if smallComms(i)
            bf_small(saccadeGroups==uniqueGroups(i)) = true; % add these to bad frames
        end
    end
else % warn that mfpc is not met
    fprintf(['Warning: Could not find a continuous cluster of frames\n',...
        'greater than the minimum frame per cluster threshold.\n']);
    
    data.mtskip = true;
    data.forced_mtskip = true;
    data.rejected.MT_fail       = gf;
    data.rejected.outliers_NCC  = [];
    data.rejected.smallClusters = [];
    data.scores.ncc = prepScore(ancc,'dir');
    return;
end

%% Update data and eliminate convicts, and small clusters
data.x          = track(:,1);
data.y          = track(:,2);
data.saccades   = saccadeGroups;
data.scores.ncc = prepScore(ancc,'dir');

%% Eliminate any communities that fall below mfpc (min frame per cluster) threshold
data.rejected.smallClusters = gf(bf_small);
data.rejected.MT_fail       = gf(convicts);

data = removeFrames(data, or(bf_small,convicts));

%% Eliminate NCC outliers
norm_ancc = (data.scores.ncc - mean(data.scores.ncc))./std(data.scores.ncc);
bf = norm_ancc < -3;
data.rejected.outliers_NCC = gf(bf);
if any(bf)
    data = removeFrames(data,bf);
end

%% Reset to 0 for each group, prepare output
uniqueGroups = unique(data.saccades);
for i=1:numel(uniqueGroups)
    bounds = data.saccades == uniqueGroups(i);
    first  = find(bounds);
    data.x(bounds) = data.x(bounds) - data.x(first(1));
    data.y(bounds) = data.y(bounds) - data.y(first(1));
end

end









