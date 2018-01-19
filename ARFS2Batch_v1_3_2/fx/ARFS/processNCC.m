function [ ncc ] = processNCC( ncc, strip, yoffset, cropParams )
%processNCC Convolves and crops around the area with a supposed peak
%   Detailed explanation goes here

%% Crop ellipse of maximum eye movement
cp = cropParams;
memY = cp.memY;
memX = cp.memX;

[nccHt, nccWd] = size(ncc);
[X, Y] = meshgrid(1:nccWd, 1:nccHt);

[ss, h] = size(strip);
k = ss+yoffset;

memX2 = memX^2;
memY2 = memY^2;
memX2memY2 = memX2*memY2;
inellipse = memY2*(X-h).^2 + memX2*(Y-k).^2 <= memX2memY2;

ncc = ncc.*inellipse;

%% Protect against edge effects
cropWinY = ceil(0.5*ss);
cropWinX = ceil(0.05*nccWd);
ncc(1:cropWinY,:) = 0;
ncc(end-cropWinY-1:end,:) = 0;
ncc(:,1:cropWinX) = 0;
ncc(:,end-cropWinX-1:end) = 0;

%% Check out early if obvious peak
remNcc = ncc(ncc > 0);
% figure, surf(ncc), shading flat; title(num2str(yoffset));
% figure, plot(remNcc); title(num2str(yoffset));
if max(remNcc) > mean(remNcc) + (5*std(remNcc));
    [ypeak, xpeak] = find(ncc==max(ncc(:)));
%     fprintf('ob peak found at %i\n', yoffset);
else
%     fprintf('no ob peak found at %i\n', yoffset);
    %% Smooth
    convType  = 'gaussian';
    convSize  = 10;
    convSigma = 1;
    conv_ncc = conv2(ncc,fspecial(convType,convSize,convSigma),'same');

    %% Re-crop
    shrink = 0.85;
    memY = shrink*memY;
    memX = shrink*memX;
    memX2 = memX^2;
    memY2 = memY^2;
    memX2memY2 = memX2*memY2;
    inellipse = memY2*(X-h).^2 + memX2*(Y-k).^2 <= memX2memY2;
    conv_ncc = conv_ncc.*inellipse;

    cropWinY = ceil(.6*ss);
    cropWinX = ceil(.06*nccWd);
    conv_ncc(1:cropWinY,:) = 0;
    conv_ncc(end-cropWinY-1:end,:) = 0;
    conv_ncc(:,1:cropWinX) = 0;
    conv_ncc(:,end-cropWinX-1:end) = 0;

    %% Check slopes by cols and rows
    vGridCol = zeros(size(conv_ncc));
    for i=1:nccWd
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
    vGridRow = zeros(size(conv_ncc));
    for i=1:nccHt
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
    [ypeak, xpeak] = find(vGrid==max(vGrid(:)));
    
end

%% Create a box around the peak
paneSize = 20;
vMask = zeros(size(ncc));

miny = ypeak-paneSize;
if miny < 1
    miny=1;
end
maxy = ypeak+paneSize;
if maxy > nccHt
    maxy=nccHt;
end
minx = xpeak-paneSize;
if minx < 1
    minx = 1;
end
maxx = xpeak+paneSize;
if maxx > nccWd;
    maxx = nccWd;
end

vMask(miny:maxy,minx:maxx) = 1;
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
