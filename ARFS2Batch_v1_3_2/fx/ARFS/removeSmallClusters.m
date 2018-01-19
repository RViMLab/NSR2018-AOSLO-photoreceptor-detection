function [ data ] = removeSmallClusters( data )
%removeSmallClusters finds clusters below the minimum frame per cluster threshold and removes all those frames

mfpc = data.minFramesPerCluster;
bf = false(numel(data.frames),1);
nGroups = numel(data.clusters);
% Find small clusters
for i=1:nGroups
    cg = data.clusters(i);
    for j=1:numel(cg.cNames)
        if cg.sizes(j) < mfpc
            bf(ismember(data.frames, cg.frames(cg.assign==cg.cNames(j)))) = true;
        end
    end
end

% Update rejected information
data.rejected.smallClusters = [data.rejected.smallClusters; data.frames(bf)];

% Remove frames
data = removeFrames(data, bf);
data = cleanClusters(data);

% bf_whole  = false(numel(redata.frames),1);
% bf_cFrame = false(numel(cluster.frames),1);
% bc        = false(nc,1); % bad cluster
% 
% for i=1:nc
%     cc = cluster.assign==cluster.cNames(i);
%     cluster.sizes(i) = numel(find(cc));
%     
%     if cluster.sizes(i) < mfpc % Reject frames from small clusters
%         bf_whole(ismember(redata.frames, cluster.frames(cc))) = true;
%         bf_cFrame(cc) = true;
%         bc(i) = true;
%         continue;
%     end
%     
%     cluster.centroids(i,:) = mean(cluster.xy(cc,:),1);
% end
% 
% % Whole structure changes:
% redata.rejected.smallClusters       = [redata.rejected.smallClusters; redata.frames(bf_whole)];
% redata.frames(bf_whole)             = [];
% redata.scores.int(bf_whole)         = [];
% redata.scores.sumRsqs(bf_whole)     = [];
% redata.scores.ncc(bf_whole)         = [];
% redata.x(bf_whole)                  = [];
% redata.y(bf_whole)                  = [];
% redata.saccades(bf_whole)           = [];
% % check if p2c exists yet
% if any(strcmp(fieldnames(redata.scores),'p2c'))
%     redata.scores.p2c(bf_whole) = [];
% end
% 
% % Cluster changes
% cluster.cNames(bc)        = [];
% cluster.sizes(bc)         = [];
% cluster.centroids(bc,:)   = [];
% cluster.assign(bf_cFrame) = [];
% cluster.frames(bf_cFrame) = [];
% cluster.xy(bf_cFrame,:)   = [];

end









