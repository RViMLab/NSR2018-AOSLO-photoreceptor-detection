function [ redata ] = recalcClusters( redata, cluster )
%recalcClusters recalculates cluster data after frames have been reassigned or deleted.

% mfpc                = redata.minFramesPerCluster;
cluster.cNames      = unique(cluster.assign);
nc                  = numel(cluster.cNames);
cluster.sizes       = zeros(nc,1);
cluster.centroids   = zeros(nc,2);

% bf_whole  = false(numel(redata.frames),1);
% bf_cFrame = false(numel(cluster.frames),1);
% bc        = false(nc,1); % bad cluster

for i=1:nc
    cc = cluster.assign==cluster.cNames(i);
    cluster.sizes(i) = numel(find(cc));
    
%     if cluster.sizes(i) < mfpc % Reject frames from small clusters
%         bf_whole(ismember(redata.frames, cluster.frames(cc))) = true;
%         bf_cFrame(cc) = true;
%         bc(i) = true;
%         continue;
%     end
    
    cluster.centroids(i,:) = mean(cluster.xy(cc,:),1);
end

% Whole structure changes:
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

%% Update data structure with new cluster information
for i=1:numel(redata.clusters)
    if cluster.groupName == redata.clusters(i).groupName
        redata.clusters(i) = cluster;
        break;
    end
end

end

