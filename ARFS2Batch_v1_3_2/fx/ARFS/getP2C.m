function [ data ] = getP2C( data, wb )
%getP2C Calculates a frame's proximity to its cluster centroid

% Preallocate
nGroups  = numel(data.clusters);
nrf      = numel(data.frames);
d2c      = zeros(nrf,1);

% Calculate distance between frame and cluster centroid
waitbar(0,wb,'Calculating distance to cluster centroids...');
for i=1:nGroups
    waitbar(i/nGroups,wb);
    
    cg = data.clusters(i); % cluster group
    for j=1:numel(cg.frames)
        d2c(data.frames == cg.frames(j)) = ...
            sqrt(sum((cg.centroids(cg.cNames == cg.assign(j),:) - cg.xy(j,:)).^2));
    end
end

% Find outliers
bf = false(nrf,1);
for i=1:nGroups
    cg = data.clusters(i);
    for j=1:numel(cg.cNames)
        cc = find(ismember(data.frames, cg.frames(cg.assign == cg.cNames(j))));
        norm_d2c = (d2c(cc) - mean(d2c(cc)))./std(d2c(cc));
        bf(cc(norm_d2c > 3)) = true;
    end
end

% Update rejects and scores
data.rejected.outliers_P2C = data.frames(bf);
data.scores.p2c = prepScore(d2c,'inv');

if any(bf)
    data = removeFrames(data, bf);
    data = cleanClusters(data);
    data = removeSmallClusters(data);
end

end









