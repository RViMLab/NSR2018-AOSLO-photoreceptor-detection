function [ data ] = findClusters( data )
%findClusters Tracks motion of frames, returns clusters of stable fixation
%   Uses kmeans and slihouette value optimization to pick the best number
%   of clusters.
%   data must have fields:
%            .x: [nrfx1 double]
%            .y: [nrfx1 double]
%       .frames: [nrfx1 double]
%         .nccs: [nrfx1 double]
%        .crops: [ht wd]
%         .ancc: [nrfx1 double]
%        .score: [nrfx1 double]
%
%   Returns a structure with fields
%          .frames: [nrfx1 double]
%         .cluster: [nrfx1 double]
%               .x: [nrfx1 double]
%               .y: [nrfx1 double]
%       .centroids: [nClustersx2 double]
%          .cNames: [nClustersx1 double]

mfpc = data.minFramesPerCluster;
xyt = [data.x, data.y];
nrf = numel(data.frames);
maxK = round(nrf/mfpc);
if maxK == 0 % very few frames remaining
    maxK = 1;
end
% evalCH = evalclusters(xyt,'kmeans','CalinskiHarabasz','KList',1:maxK);
% evalDB = evalclusters(xyt,'kmeans','DaviesBouldin','KList',1:maxK);
% evalGap = evalclusters(xyt,'kmeans','gap','KList',1:maxK);
evalSilh = evalclusters(xyt,'kmeans','silhouette','KList',1:maxK);

% ENSURE 20 FRAME MINIMUM FOR BIGGEST CLUSTER
optK = evalSilh.OptimalK;
tblSilh = 0;
while max(tblSilh) <= mfpc
    clusterSilh = kmeans(xyt,optK,'replicates',5);
    optK = optK -(max(tblSilh) <= mfpc);
    tblSilh = tabulate(clusterSilh);
    tblSilh = tblSilh(:,2);
end
% Prepare data for testing
data.clusters.assign = clusterSilh;
data.clusters.sizes  = tblSilh;

% Steal frames
data = clusterOverlap(data);

% Reject any frames from small clusters
smallClusters = data.clusters.names(data.clusters.sizes < mfpc);
if isempty(smallClusters)
    return;
end
bf = false(nrf,1);
for i=1:nrf
    if ismember(data.clusters.assign(i), smallClusters)
        bf(i) = true;
    end
end

data.rejected.smallClusters = data.frames(bf);
data.frames(bf)             = [];
data.scores.prelim(bf)      = [];
data.scores.int(bf)         = [];
data.scores.sumRsqs(bf)     = [];
data.scores.ncc(bf)         = [];
data.x(bf)                  = [];
data.y(bf)                  = [];
data.clusters.assign(bf)    = [];
data = recalcClusters(data);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CODE FOR PLOTTING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% t = 0:pi/10:2*pi;
% figure
% subplot(2,2,1);
% plot(evalCH.CriterionValues);
% title('A: Calinski Harabasz')
% subplot(2,2,2);
% plot(evalDB.CriterionValues);
% title('B: Davies Bouldin')
% subplot(2,2,3)
% plot(evalGap.CriterionValues);
% title('C: Gap')
% subplot(2,2,4)
% plot(evalSilh.CriterionValues);
% title('D: Silhouette')

% %kmeans
% clusterCH = kmeans(xyt,evalCH.OptimalK,'replicates',5);
% clusterDB = kmeans(xyt,evalDB.OptimalK,'replicates',5);
% clusterGap = kmeans(xyt,evalGap.OptimalK,'replicates',5);
    
% Cluster Information:
% tblCH = tabulate(clusterCH);
% tblCH = tblCH(:,2);
% tblDB = tabulate(clusterDB);
% tblDB = tblDB(:,2);
% tblGap = tabulate(clusterGap);
% tblGap = tblGap(:,2);
% tblSilh = tabulate(clusterSilh);
% tblSilh = tblSilh(:,2);
% Col2 is number of members/cluster#i

% z = ones(nFrames,1);
% pCH = horzcat(xyt,z,clusterCH);
% pDB = horzcat(xyt,z,clusterDB);
% pGap = horzcat(xyt,z,clusterGap);
% pSilh = horzcat(xyt,z,clusterSilh);

% For SIZING
% set pX(:,3) to be the number of members in a cluster
%the i,4th index of pCH is the cluster number for that fixation position
%tbl is sorted by cluster number
%tblCH(pCH(i,4)) returns the number of members in that cluster
% for i=1:numel(pCH(:,3))
%     pCH(i,3) = tblCH(pCH(i,4));
% end
% for i=1:numel(pDB(:,3))
%     pDB(i,3) = tblDB(pDB(i,4));
% end
% for i=1:numel(pGap(:,3))
%     pGap(i,3) = tblGap(pGap(i,4));
% end
% for i=1:nFrames
%     pSilh(i,3) = tblSilh(pSilh(i,4));
% end

%for noticable differences in area
% pCH(:,3) = pCH(:,3)*25;
% pDB(:,3) = pDB(:,3)*25;
% pGap(:,3) = pGap(:,3)*25;
% pSilh(:,3) = pSilh(:,3)*25;
% size is proportional to the number of members in a cluster
% color by cluster
% figure
% subplot(2,2,1);
% scatter(pCH(:,1),pCH(:,2),pCH(:,3),pCH(:,4));
% title('A: Calinski Harabasz')
% subplot(2,2,2);
% scatter(pDB(:,1),pDB(:,2),pDB(:,3),pDB(:,4));
% title('B: Davies Bouldin')
% subplot(2,2,3)
% scatter(pGap(:,1),pGap(:,2),pGap(:,3),pGap(:,4));
% title('C: Gap')
% subplot(2,2,4)
% scatter(pSilh(:,1),pSilh(:,2),pSilh(:,3),pSilh(:,4));
% title('D: Silhouette')

% %for noticable differences in area
% pCH(:,5) = 50./peaks;
% pDB(:,5) = 50./peaks;
% pGap(:,5) = 50./peaks;
% pSilh(:,5) = 50./peaks;
% % size is proportional to peak ncc value for that point
% figure
% subplot(2,2,1);
% scatter(pCH(:,1),pCH(:,2),pCH(:,5),pCH(:,4));
% title('A: Calinski Harabasz')
% subplot(2,2,2);
% scatter(pDB(:,1),pDB(:,2),pDB(:,5),pDB(:,4));
% title('B: Davies Bouldin')
% subplot(2,2,3)
% scatter(pGap(:,1),pGap(:,2),pGap(:,5),pGap(:,4));
% title('C: Gap')
% subplot(2,2,4)
% scatter(pSilh(:,1),pSilh(:,2),pSilh(:,5),pSilh(:,4));
% title('D: Silhouette')

% Silhouette seems to be the simplest and best

% Rank frames 
% h = hist(clusterSilh,optK);
% [~,rankedClusters] = sort(h,'descend');
% rankedFrames = zeros(nFrames,2);
% numMembers=1;
% for i = 1:optK
%     for firstMember = 1:nFrames
%         if clusterSilh(firstMember)==rankedClusters(i)
%             rankedFrames(numMembers,1) = firstMember;
%             rankedFrames(numMembers,2) = rankedClusters(i);
%             numMembers = numMembers+1;
%         end
%     end
% end

% % Determine temporal disjunctions
% for i = 1:nFrames
%     rankedFrames(i,3) = peaks(rankedFrames(i,1));
%     rankedFrames(i,1) = goodFrames(rankedFrames(i,1));
%     if i > 1 && rankedFrames(i,2)==rankedFrames(i-1,2)
%         rankedFrames(i,4) = rankedFrames(i,1) - rankedFrames(i-1,1);
%     else
%         rankedFrames(i,4) = 0;
%     end
% end

% % Change old peak NCC values to new NCC's of the temporal disjointed frames
% for i = 1:nFrames-1
%     if rankedFrames(i+1,4) > 1
%         oldNcc = rankedFrames(i,3);
%         pre = images{rankedFrames(i)};
%         post = images{rankedFrames(i+1)};
%         ncc = normxcorr2(pre,post);
%         peak = max(ncc(:));
%         rankedFrames(i,5) = oldNcc - peak;
%         rankedFrames(i,3) = peak;
%     end
% end

% rf(:,1) = actual frame
% rf(:,2) = cluster number
% rf(:,3) = max(ncc) for rf(i) to rf(i+1)
% rf(:,4) = dt for i to i-1, 0 if i-1 belongs to another cluster
% rf(:,5) = dNcc after temporal disjoint reassignment

% % re-sort rankedFrames based on rankedClusters
% rf = zeros(numel(rankedFrames(:,1)),1);
% k=1;
% for i = 1:numel(rankedClusters)
%     for j = 1:nrf
%         if rankedFrames(j,2) == rankedClusters(i)
%             rf(k) = rankedFrames(j,1);
%             k = k+1;
%         end
%     end
% end
    
% rankedFrames = rf;
% final.rf = rankedFrames;
% final.info = pSilh;
% final.track = track;