function [ dmb, terminate ] = getArfsParams( dmb )
%getArfsParams Gets user input for ARFS parameters

terminate = false;

%% Set defaults
arfsDefs =  struct('mtskip',           false, ...
                   'clusterwise',      true, ...
                   'nReq',             '1', ...
                   'framesPerCluster', '10');
done     = false;
i=1;
while ~done
    
    % Change input handling in GUI to take in a parameter object rather than its fields separately (todo)
    arfsParams = getArfsParams_GUI(dmb(i).name, ...
        'mtskip',           arfsDefs.mtskip, ...
        'clusterwise',      arfsDefs.clusterwise, ...
        'nReq',             arfsDefs.nReq, ...
        'framesPerCluster', arfsDefs.framesPerCluster);
    if ~isstruct(arfsParams)
        terminate = true;
        return;
    end
    if isfield(arfsParams,'backButtonPressed')
        if i > 1
            i = i-1;
        end
        
        arfsDefs = dmb(i).pack;
        continue;
    end
    
    arfsDefs    = arfsParams;
    dmb(i).pack = arfsParams;
    
    i = i+1;
    if i > numel(dmb)
        done = true;
    end
end

end

