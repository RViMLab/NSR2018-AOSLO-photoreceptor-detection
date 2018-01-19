function [ ol ] = clusterOverlap( ol, cluster )
%clusterOverlap allows clusters to steal frames from other clusters
%   This proceeds in order of decreasing frame number
%   A frame is stolen if it is predicted to overlap with a maximum px displacement of 200 or less
%   This step is important as it prevents over clustering, which would lead
%   to inconsistencies in frame choice due to the randomness of kmeans.

hh = ol.size(1);
ww = ol.size(2);

maxdisp = 100; % based on the default 200 px max displacement
maxdisp = maxdisp/sqrt(2); % components

thr = (1-(maxdisp/hh))*(1-(maxdisp/ww)); % proporion overlapping area
a = (-ww*thr)+ww; % horz radius of elipse
b = (-hh*thr)+hh; % vert radius of elipse
% t=0:pi/50:2*pi;
% xyt = cluster.xy;
nrf = numel(cluster.frames);

% Number of Clusters (nc)
nc = numel(cluster.cNames);

% Biggest to smallest clusters
[~,order] = sort(cluster.sizes, 'descend');

% Steal frames
for i=1:nc
    % Current Cluster (cc)
    cc = cluster.assign==cluster.cNames(order(i));
    if numel(find(cc)) == 0
        continue;
    end
    
    cluster.centroids(order(i),:) = mean(cluster.xy(cc,:),1);
    
    if i==nc
        break;
    end
    for j=1:nrf
        % cannot steal from a stealer or a frame that's alread been stolen
        if i >= find(cluster.cNames(order) == cluster.assign(j))
            continue;
        end
        % dist between centroid(order(i)) and frame(j)
        x1y1 = cluster.xy(j,:) - cluster.centroids(order(i),:);
        
        ang = atand(x1y1(2)/x1y1(1));
        d1  = sqrt((x1y1(1)^2)+(x1y1(2)^2));
        % dist between centroid(i) and tolerance boundary (elliptical)
        x2 = a*cosd(ang);
        y2 = b*sind(ang);
        d2 = sqrt((x2^2)+(y2^2));
        if d1 <= d2
            cluster.assign(j) = cluster.cNames(order(i));
        end
    end
%     figure;
%     scatter(xyt(:,1),xyt(:,2),100,cluster.assign,'linewidth',2)
%     scatter(xyt(cluster.assign==7,1),xyt(cluster.assign==7,2),100,'g','linewidth',2)
%     hold on;
%     scatter(cluster.centroids(order(i),1),cluster.centroids(order(i),2),100,'k','marker','x','linewidth',2);
%     scatter(xyt(cluster.assign~=7,1),xyt(cluster.assign~=7,2),100,'r','marker','x','linewidth',2);
%     t = linspace(0,2*pi,100);
%     patch((a*cos(t))+cluster.centroids(order(i),1),(b*sin(t))+cluster.centroids(order(i),2),...
%         [1,1,1],'facecolor','none','linewidth',2)
%     plot([cluster.centroids(order(i),1), a+cluster.centroids(order(i),1)],...
%         [cluster.centroids(order(i),2),cluster.centroids(order(i),2)],...
%         'color','r','linestyle','--');
%     hold off;
%     axis tight; axis equal; axis off;
end

ol = recalcClusters(ol, cluster);


end



