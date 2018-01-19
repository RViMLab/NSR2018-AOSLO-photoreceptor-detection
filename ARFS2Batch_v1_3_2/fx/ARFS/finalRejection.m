function [ data ] = finalRejection( data )
%finalRejection uses a conservative threshold to reject frames

% Find lower ncc frames
data.rejected.strict_NCC = [];
ncc_threshold = 0.2; % lower 20% rejected
data.ncc_threshold = ncc_threshold;
% Renormalize ncc scores
data.scores.ncc = prepScore(data.scores.ncc,'dir');

bf = data.scores.ncc < ncc_threshold;

% Update rejection information
data.rejected.strict_NCC = data.frames(bf);

if any(bf) % there will be. Exactly the number of surviving frames * ncc_threshold
    data = removeFrames(data, bf);
    if ~data.mtskip
        data = cleanClusters(data);
        data = removeSmallClusters(data);
    end
end

end

