function [ dmb, terminate ] = getAvis(dmb)
%getAvis Get user selection of .avi's associated with each .dmb

terminate = false;

possibleModalities = {
    'confocal';
    'split_det';
    'avg';
    'direct';
    'reflect';
    'visible';
    'ICG';
    };    

nDmbs = numel(dmb);
i=1;
while i <= nDmbs
% for i=1:nDmbs
    % Determine modality of primary sequence
    for j=1:numel(possibleModalities)
        if isempty(strfind(dmb(i).name,possibleModalities{j}))
            continue;
        else
            primaryModality = possibleModalities{j};
            break;
        end        
    end
    
    %% Create list of .avi's to select
    % limited by modality
    aviList         = dmb(1).allAvis;
    aviList(cellfun(@isempty, (strfind(aviList,primaryModality)))) = [];
    % Get video upon which dmb is based and get its fov
    fov_lut         = dmb(1).fov_lut;
    fovs            = cell2mat(fov_lut(:,2));
    aviListNoExt    = cellfun(@(x) x(1:end-4), aviList,'uniformoutput',false);
    for j=1:numel(aviListNoExt)
        if ~isempty(strfind(dmb(i).name, aviListNoExt{j}))
            % Get videoNumber
            nameparts   = strsplit(aviListNoExt{j},'_');
            vidNum      = nameparts{end};
            dmbFOV      = fovs(strcmp(fov_lut(:,1),vidNum));
            break;
        end
    end
    % limited by fov
    removeThese = false(numel(aviList),1);
    for j=1:numel(aviListNoExt)
        nameparts   = strsplit(aviListNoExt{j},'_');
        thisVidNum  = nameparts{end};
        if fov_lut{strcmp(fov_lut(:,1),thisVidNum),2} ~= dmbFOV
            removeThese(j) = true;
        end
    end
    aviList(removeThese) = [];
    
    %% Have user select from aviList
    msg = sprintf('Select .avi''s associated with: %s',dmb(i).name);
    if i > 1
        cancelLabel = 'Back';
    else
        cancelLabel = 'Quit';
    end
    
    [selection, ok] = listdlg('promptstring',msg,'selectionmode','multiple','liststring',aviList,...
        'listsize',[17*numel(aviList{1}), 300],'cancelstring',cancelLabel);
    if ~ok && i==1
        terminate = true;
        return;
    elseif ~ok && i > 1
        i = i-1;
        continue;
    end
    
    dmb(i).avis = aviList(selection);
    
    %% Get vidnums of all selected videos
    dmb(i).vidnums = cell(numel(selection),1);
    for j=1:numel(dmb(i).avis)
        nameparts = strsplit(dmb(i).avis{j},'.');
        nameparts = strsplit(nameparts{1},'_');
        dmb(i).vidnums{j} = nameparts{end};
    end
    
    i=i+1;
end

end

