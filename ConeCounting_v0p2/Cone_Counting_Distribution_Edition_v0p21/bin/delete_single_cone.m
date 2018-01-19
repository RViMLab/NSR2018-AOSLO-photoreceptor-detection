 function [ coordlistout ] = delete_single_cone( scale, orig_coordlist, coi)
%   Robert Cooper 10-10-2014

    distances = pdist2(coi, orig_coordlist);

    matching_val = find(distances < scale*3);
    
    if ~isempty(matching_val)
        [~, ind] = min(distances(matching_val));
        matchind = matching_val(ind);
        coordlistout=orig_coordlist([1:matchind-1 matchind+1:end],:);
    else
        coordlistout=orig_coordlist;
    end

end

