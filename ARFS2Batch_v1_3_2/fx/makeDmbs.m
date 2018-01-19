function rfList = makeDmbs( dmb, data )
%makeDmbs Makes .dmb's based on the user input and arfs data

p       = dmb.pack;
p.nReq  = str2double(p.nReq);

%% Best frames from EACH cluster
if p.clusterwise && ~data.mtskip
    ng = numel(data.clusters); % number of groups
    tnc = 0; % total number of clusters
    for i=1:ng
        tnc = tnc + numel(data.clusters(i).cNames);
    end
    rfList = zeros(tnc*p.nReq,1);
    rfListIndx = 1;
    for i=1:ng
        cg = data.clusters(i); % current group
        for j=1:numel(cg.cNames)
            % Find frames in this cluster i and their scores
            ccFrames = cg.frames(cg.assign == cg.cNames(j));
            ccScores = data.finalScores(ismember(data.frames, ccFrames));
            % Rank frames
            [~,I] = sort(ccScores,'descend');
            sFramesCluster = ccFrames(I);
            if numel(sFramesCluster) < p.nReq
                nFramesToAdd = numel(sFramesCluster);
            else
                nFramesToAdd = p.nReq;
            end
            rfList(rfListIndx:rfListIndx+nFramesToAdd-1) = sFramesCluster(1:nFramesToAdd);
            rfListIndx = rfListIndx+nFramesToAdd;
        end
    end
    rfList(rfList==0) = [];

%% Best frames OVERALL
elseif ~p.clusterwise || data.mtskip
    [~,I]   = sort(data.finalScores,'descend');
    sFrames = data.frames(I);
    if numel(sFrames) < p.nReq
        p.nReq = numel(sFrames);
    end
    rfList  = sFrames(1:p.nReq);
end

pyScriptffName = ['"',fullfile(pwd,'fx','applyBatch.py'),'"'];
for k=1:numel(rfList)
    try
        eval(sprintf('! %s -n %s -r %i -d %s', ...
            pyScriptffName, ['"',data.name,'"'], rfList(k), ['"',fullfile(dmb.path, dmb.name),'"']));
    catch
        python(pyScriptffName, ...
            ['-n ',['"',data.name,'"']], ...
            ['-r ',num2str(rfList(k))], ...
            ['-d ',['"',fullfile(dmb.path, dmb.name),'"']]);
    end
end


end

