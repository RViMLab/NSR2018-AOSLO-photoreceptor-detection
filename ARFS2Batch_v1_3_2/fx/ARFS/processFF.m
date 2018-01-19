function [ ncc, failed ] = processFF( ncc, data )
%processNCC Convolves and crops around the dx,dy=0,0 translation

failed = false;
%% Mask ncc
ncc = ncc.*data.ellipticalMask1;
% ncc = ncc(k-memY:k+memY,h-memX:h+memX); % rectangular cropping, see getMT

%% Check out early if only one obvious peak
% 0 out neighbors around max
tmpncc = ncc; % temporary ncc
tmpncc(tmpncc>0) = tmpncc(tmpncc>0) - min(tmpncc(tmpncc>0));
maxtmpncc = max(tmpncc(:));
[ypeak,xpeak] = find(tmpncc==maxtmpncc);
mph = (1-(1/exp(1)))*maxtmpncc; % min peak height ~63.21% max
ps = 10; % pane size
tmpncc(ypeak-ps:ypeak+ps,xpeak-ps:xpeak+ps) = 0;
tmpncc(ypeak,xpeak) = maxtmpncc;
tmpncc(tmpncc<mph) = 0;
tmpncc = tmpncc > 0;


if numel(find(tmpncc)) == 1 % success!
    return;
else % perhaps the peak is obscured by a lesion
    %% Smooth and recrop
    conv_ncc = conv2(ncc,data.convFilter,'same').*data.ellipticalMask2;

    %% Check slopes by cols and rows
    % Col
    vGridCol = zeros(size(conv_ncc));
    for i=1:(2*data.size(2)-1)
        if not(any(conv_ncc(:,i)))
            continue;
        end
        col = conv_ncc(:,i);
        I = find(col>0);
        col(col==0) = [];
        dcol = diff(col);
        if isempty(dcol)
            continue;
        end
        vGridCol(I(2:end),i) = dcol;
    end
    % Row
    vGridRow = zeros(size(conv_ncc));
    for i=1:(2*data.size(1)-1)
        if not(any(conv_ncc(i,:)))
            continue;
        end
        col = conv_ncc(i,:);
        I = find(col>0);
        col(col==0) = [];
        dcol = diff(col);
        if isempty(dcol)
            continue;
        end
        vGridRow(i,I(2:end)) = dcol;
    end
    % Get product of amplitudes
    vGrid = abs(vGridCol).*abs(vGridRow);
    vGridMaxRow = max(vGrid,[],2);
    vGridMaxRow = vGridMaxRow(vGridMaxRow > 0);
    vGridMaxCol = max(vGrid,[],1);
    vGridMaxCol = vGridMaxCol(vGridMaxCol > 0);
    mphr = median(vGridMaxRow) + exp(1)*std(vGridMaxRow);
    mphc = median(vGridMaxCol) + exp(1)*std(vGridMaxCol);
    mpd = round(length(vGridMaxRow)/3);
    
    pksr = findpeaks(vGridMaxRow,'MINPEAKHEIGHT',mphr,'MINPEAKDISTANCE',mpd);
    pksc = findpeaks(vGridMaxCol,'MINPEAKHEIGHT',mphc,'MINPEAKDISTANCE',mpd);
    if numel(pksr) ~= 1 || numel(pksc) ~= 1
        failed = true;
        return;
    end
    [ypeak, xpeak] = find(vGrid==max(vGrid(:)));
    
end

%% Create a box around the peak
ps = 10;
vMask = zeros(size(ncc));
vMask(ypeak-ps:ypeak+ps, xpeak-ps:xpeak+ps) = 1;
ncc = ncc.*vMask;

end

% CODE GRAVEYARD

% Smooth
% nIter = numel(10:2:20)*numel(1:5);
% conv(nIter).ncc = [];
% nIter = 0;

% for i=10:2:20
%     for j=1:5
%         nIter = nIter +1;
        %%%%%%%%%%%
        % DISPLAY %
        %%%%%%%%%%%
%         figure;
%         conv_param = strcat(convType,', size: ',num2str(convSize),', sigma: ',...
%             num2str(convSigma));
%         conv(nIter).param = conv_param;
%         surf(conv_ncc), shading flat; title(conv_param,'FontSize',18);
%     end
% end

% outVidName = strcat('ConvExperiment.avi');
% writerObj = VideoWriter(outVidName);
% open(writerObj);
% surf(conv(m).vGrid);
% axis tight;
% set(gca,'nextplot','replacechildren');
% set(gcf,'Renderer','zbuffer');
% for m=1:numel(conv)
%     surf(conv(m).vGrid); shading flat; title(conv(m).param,'FontSize',18);
%     frame = getframe;
%     writeVideo(writerObj,frame);
% end
% close(writerObj);

% for m=1:numel(conv)
%     conv(m).vGrid = vGridCombined;
% end


%%%%%%%%%%%
% DISPLAY %
%%%%%%%%%%%
% paneParam = strcat('cropped: ',num2str(paneSize),'px around peak');
% figure; imagesc(ncc); title(paneParam,'FontSize',18);
% figure, surf(conv_ncc), shading flat;
% figure, surf(ncc), shading flat;

% ncc = ncc(cropParams.y:end-cropParams.y,cropParams.x:end-cropParams.x);
