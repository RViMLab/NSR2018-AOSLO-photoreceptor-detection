function [ data ] = cleanClusters( data )
%cleanClusters applies the whole data structure changes and applies them to the cluster structure

emptyGroups = false(numel(data.clusters),1);
for i=1:numel(data.clusters)
    cg = data.clusters(i);
    missingFrames = ~ismember(cg.frames, data.frames);
    if all(missingFrames)
        emptyGroups(i) = true;
        continue;
    end
    if any(missingFrames)
        cg.assign(missingFrames) = [];
        cg.frames(missingFrames) = [];
        cg.xy(missingFrames,:)   = [];
        data = recalcClusters(data, cg);
    end
end

if any(emptyGroups)
    data.clusters(emptyGroups) = [];
end

end









