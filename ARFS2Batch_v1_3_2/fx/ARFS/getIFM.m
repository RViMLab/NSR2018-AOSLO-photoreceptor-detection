function [ data ] = getIFM( images, data, wb )
%getIFM Summary of this function goes here
%
%   FFT math originally written by Alf Dubra
%   Adapted for this project by Alex Salmon
%   Detailed explanation goes here

% Get the fourier spectrum from an array of doubles.

waitbar(0,wb,'Detecting motion artifacts and distortion...');

%% Set constants
ss       = 40; % From optimization experiment
sampling = 512; % From optimization experiment
nRows    = data.size(1);
nIter    = floor((nRows/(ss))) + (mod(nRows,ss) ~= 0);
gf       = data.frames;
nrf      = numel(gf);
rsqs     = zeros(nrf,nIter);

%% Make Filter
cropWidth          = floor(sampling/4);
lowPassMask        = cropWidth:3*cropWidth;
filteredSideLength = numel(lowPassMask);

%% Analyze strips
for i=1:nrf
    waitbar(i/nrf,wb);
    
    for j=1:nIter
        %% Obtain strip
        if j==nIter && mod(nRows,ss)~=0 % Last strip, make sure to do bottom if not already done
            ub = nRows-ss+1;
            lb = nRows;
        else
            ub = 1+(ss*(j-1));
            lb = ub+ss-1;
        end
        strip = images{gf(i)}(ub:lb,:);
        %% Obtain FFT
        % Determine whether the performance of larger strip sizes depends on sampling of the FFT
        stripFFT = ifftshift(fft2(fftshift(strip),sampling,sampling));
        stripSpectra = abs(stripFFT).^2;
        ssf = stripSpectra(lowPassMask,lowPassMask); % ssf: stripSpectraFiltered
        ssf(ssf < mean(ssf(ssf>0))) = 0; % step out anything less than median   

        %% Find correlation of FFT maxima
        % Inspired by Longitudinal Reflectance Profile (lrp)
        % Get max and row index of max in each col
        y = zeros(filteredSideLength^2,1);
        x = y;
        n = 1;
        for k=1:filteredSideLength
            if max(ssf(:,k)) <= 0
                continue;
            end
            indicesOfMax = find(ssf(:,k) == max(ssf(:,k)));
            y(n:n+numel(indicesOfMax)-1) = indicesOfMax;
            x(n:n+numel(indicesOfMax)-1) = k.*ones(numel(indicesOfMax),1);
            n = n+numel(indicesOfMax);
        end
        y = y(1:n-1);
        x = x(1:n-1);

        if isempty(x) % then there is a strip devoid of signal
            rsqs(i,j) = 1;
            continue;
        end
        % Linear regression
        x = [ones(size(x)),x]; %#ok<*AGROW>
        B = x\y; % B(1) = y-intercept, B(2) = slope
        yCalc = x*B;
        % slope = abs(B(2));
        Rsq = 1 - sum((y - yCalc).^2)/sum((y - mean(y)).^2);
        if Rsq == Inf || Rsq == -Inf
            Rsq = 1;
        end
        rsqs(i,j) = Rsq;
    end
end

sumRsqs = sum(rsqs,2);

%% Find outliers
normSumRsqs = (sumRsqs - mean(sumRsqs))./std(sumRsqs);
bf = normSumRsqs > exp(1);

%% Update reject and score information
data.rejected.outliers_IFM  = gf(bf);
data.scores.sumRsqs = prepScore(sumRsqs,'inv');
data = removeFrames(data, bf);

end

% Code Graveyard

%% Rotate remaining images by R degrees and check again
% Works with 0 <= R <= 90
% R = 45;
% gf = data.frames;
% nrf = numel(gf);
% if display
%     figure;
%     set(gcf, 'Position', get(0,'Screensize'));
%     nrf = numel(testFrames);
% end
% if writeVid
%     fName = ...
%         'C:\Users\DevLab_811\Documents\Code\MATLAB\Prototyping\IFM\ifmR.avi'; %#ok<*UNRCH>
%     v = VideoWriter(fName);
%     open(v);
% end

% Get new parameters
% imr = imrotate(images{1}(1:ss,:),R,'bilinear');
% [nRowsR,nColsR] = size(imr);
% m1 = (nCols*sind(R))/(nCols*cosd(R));
% m2 = (nCols*sind(90-R))/(nCols*cosd(90-R));
% hBounds = zeros(nRowsR,2);
% % Width-facing triangle
% oppLen1 = floor(1+nCols*sind(R));
% adjLen1 = floor(1+nCols*cosd(R));
% % Height-facing triangle
% oppLen2 = floor(1+ss*sind(R));
% adjLen2 = floor(1+ss*cosd(R));
% % left bound
% hBounds(1:oppLen1,1)     = 1 + adjLen1 - m1*(1:oppLen1);
% hBounds(oppLen1+1:end,1) = 1 + m2*(1:numel(hBounds(oppLen1+1:end,1)));
% % right bound
% hBounds(1:adjLen2,2)     = adjLen1 + m2*(0:adjLen2-1);
% hBounds(adjLen2+1:end,2) = nColsR  - m1*(1:numel(hBounds(adjLen2+1:end,2)));

% nIterR  = floor(((nRowsR-ss)/(2*ss))) + (mod(nRowsR,2*ss) ~= 0);
% slopesR = zeros(nrf,nIterR);
% rsqsR   = slopesR;
% boxTooSmall = false(nIterR,1);

% ss0 = 2*round(ss*2*sind(R));
% 
% nIterRR = floor((nRows/(2*ss0))) + (mod(nRows,2*ss0) ~= 0);
% nIterRC = floor(nCols/(2*ss0));
% slopes3D = zeros(nrf,nIterRR,nIterRC);
% for i=1:nrf
%     img = images{gf(i)};
%     
%     if display
%         img = images{testFrames(i)};
%         sh1 = subplot(121);
%         imshow(img);
%         title(['Frame: ',num2str(testFrames(i))],...
%             'FontName','Arial','FontSize',16);
%         hr = cell(nIter,1);
%     end
%     
%     for j=1:nIterRR
%         %% Obtain strip
%         ub = 1 + (2*ss0*(j-1));
%         lb = ub + ss0 -1;
%         if lb > nRows
%             lb = nRows;
%             ub = nRows-ss0+1;
%         end
%         
%         if display
%             if j > 1
%                 delete(hr{j});
%             end
%             
%             hr{j} = imrect(sh1,[1, ub, nCols, ss0]);
%             setColor(hr{j},'r');
%                         
%             hrr = cell(nIterRC,1);
%         end
%         
%         for k=1:nIterRC
% %             top    = 1 + (2*ss*k) - ss;
% %             bot    = top+ss-1;
% %             lefts  = [hBounds(top,1), hBounds(bot,1)];
% %             left   = max(lefts);
%             left = 1 + (2*ss0*k) - ss0;
% %             rights = [hBounds(top,2),hBounds(bot,2)];
% %             right  = min(rights);
%             right = left+ss0-1;
%             
%             if display
%                 if k > 1
%                     delete(hrr{k-1});
%                 end
%                 hrr{k} = imrect(sh1,[left, ub, ss0, ss0]);
%                 setColor(hrr{k},'b');
%                 drawnow;
%             end
%             
% %             box    = zeros(numel(top:bot),numel(left:right));
% %             if numel(box) < ss^2
% %                 boxTooSmall(j) = true;
% %                 continue;
% %             end
% %             [htBox, wdBox] = size(box);
% 
%             ministrip = img(ub:lb,left:right);
%             imr = imrotate(ministrip,R,'bilinear','loose');
%             leftBound = round(ss0*cosd(R)/2);
%             rightBound = round(ss0*cosd(R) + (ss0*sind(R)/2));
%             topBound = leftBound;
%             botBound = rightBound;
%             imrCropped = imr(topBound:botBound,leftBound:rightBound);
%             %% Obtain FFT
%             stripFFT = ...
%                 ifftshift(fft2(fftshift(imrCropped),sideLength,sideLength));
%             stripSpectra = abs(stripFFT).^2;
%             ssf = stripSpectra(lowPassMask,lowPassMask); % ssf: stripSpectraFiltered
%             ssf(ssf < median(ssf(ssf>0))) = 0; % step out anything less than median
% 
%             if display
%                 subplot(322);
%                 imshow(imrCropped);
%                 title(['m ',num2str(ub),' to ',num2str(lb),', n ',...
%                     num2str(left),' to ',num2str(right)],...
%                     'FontName','Arial','FontSize',16);
%                 
%                 subplot(324);
%                 imshow(log10(ssf),[]);
%                 drawnow;
%             end
% 
%             %% Find slope of FFT maxima
%             % Inspired by Longitudinal Reflectance Profile (lrp)
%             % Get max and row index of max in each col
%             [maxSSF, maxInd] = max(ssf,[],1);
%             maxLTEzero = maxSSF <= 0;
%             maxSSF(maxLTEzero) = [];
%             maxInd(maxLTEzero) = [];
%             xAx = 1:filteredSideLength;
%             xAx(maxLTEzero)    = [];
% 
%             if isempty(xAx) || isempty(maxInd)
%                 continue;
%             end
%             % Linear regression
%             y = maxInd';
%             x = [ones(numel(xAx),1),xAx'];
%             B = x\y; % B(1) = y-intercept, B(2) = slope
%             yCalc = x*B;
%             slope = abs(B(2));
%             Rsq = 1 - sum((y - yCalc).^2)/sum((y - mean(y)).^2);
% 
%             slopes3D(i,j,k) = Rsq;
% %             rsqsR(i,j)   = Rsq;
% 
%             if display
%                 subplot(326);
%                 scatter(xAx,maxInd,[],'k');
%                 title(['Slope: ',num2str(B(2),'%1.3f'),', R^2: ',...
%                     num2str(Rsq,'%1.3f')],...
%                     'FontName','Arial','FontSize',16);
%                 axis square;
%                 hold on;
%                 plot(xAx, (xAx*B(2))+B(1),'color','r');
%                 hold off;
%                 drawnow;
%             end
%             if writeVid
%                 frame = getframe(gcf);
%                 writeVideo(v,frame);
%             end
%         end
%     end
% end
% if writeVid
%     close(v);
% end
% 
% maxSlopes2D = sum(slopes3D,3);
% maxSlopes   = sum(maxSlopes2D,2);

%         lrpx = zeros(sideLength,1);
%         lrpy = lrpx;
%         for n=1:filteredSideLength
%             if max(ssf(:,n)) <= 0
%                 continue;
%             end
%             [~,y] = max(ssf(:,n));
%             if numel(y) > 1
%                 y = mean(y);
%             end
%             lrpx(n) = n;
%             lrpy(n) = y;
%         end
%         lrpx(lrpx==0) = []; % lrpx = flip(lrpx); %this was for display purposes
%         lrpy(lrpy==0) = [];
        
        % Get slope
%         if isempty(lrpx) || isempty(lrpy)
%             continue;
%         end
%         results = polyfit(lrpx, lrpy, 1);

%         subplot(212);
%         figure;
%         scatter(lrpx,lrpy);
%         ylim([200 800])
%         title(['strip: ',num2str(j)]);
%         YfitLine  = polyval(results, lrpx);
%         hold on; plot(lrpx,YfitLine,'color','r'); hold off;

% figure; suptitle('worst sum of slopes');
% [~,sortSumSlopes] = sort(sumSlopes);
% for i=1:9
%     subplot(3,3,i);
%     imshow(images{gf(sortSumSlopes(i))});
%     title(num2str(gf(sortSumSlopes(i))));
% end
% figure; suptitle('best sum of slopes');
% for i=0:8
%     subplot(3,3,i+1);
%     imshow(images{gf(sortSumSlopes(end-i))});
%     title(num2str(gf(sortSumSlopes(end-i))));
% end
% 
% figure;
% suptitle('worst max slopes');
% [~,sortMaxSlopes] = sort(maxSlopes);
% for i=1:9
%     subplot(3,3,i);
%     imshow(images{gf(sortMaxSlopes(i))});
%     title(num2str(gf(sortMaxSlopes(i))));
% end
% figure;
% suptitle('best max slopes');
% [~,sortMaxSlopes] = sort(maxSlopes);
% for i=0:8
%     subplot(3,3,i+1);
%     imshow(images{gf(sortMaxSlopes(end-i))});
%     title(num2str(gf(sortMaxSlopes(end-i))));
% end


% Code Graveyard
% Lots of motion elimination
% sumOfSlopes       = sum(slopes,2);
% meanSumOfSlopes   = mean(sumOfSlopes);
% sdSumOfSlopes     = std(sumOfSlopes);
% wholeVidThreshold = meanSumOfSlopes + sdSumOfSlopes;
% slopes(sumOfSlopes > wholeVidThreshold,:) = [];
%
% % Little but distinct motion elimination
% sdCoeff = 3;
% singleFrameThreshold = median(slopes(:)) + (sdCoeff * std(slopes(:)));
% gf = gf(not(any(slopes > singleFrameThreshold, 2)));

% angles = atand(slopes);

%     MPD = floor(median(angles(i,:)) + std(angles(i,:)));
%     [~,I] = findpeaks(hist(angles(i,:)),'MinPeakDistance',MPD,...
%         'MinPeakHeight',1);
%     nModes(i) = numel(I);

% nModes = zeros(nrf,1);

% angles(sumOfSlopes > wholeVidThreshold,:) = [];


