function [ data ] = getInt( images, data, wb )
%intRejection returns frames that fall within a range of intensity distributions

waitbar(0,wb,'Calculating mean pixel intensity...');

%% Get intensity distribution
nrf  = numel(data.frames);
mInt = zeros(nrf,1);
for i=1:nrf
    mInt(i) = mean(images{data.frames(i)}(:));
    
    waitbar(i/nrf,wb);
end

%% Find outliers
mIntNorm = (mInt - mean(mInt))./std(mInt);
bf = mIntNorm < -exp(1); % change back if using on split or avg

%% Update reject and score information, reject frames
data.rejected.outliers_INT = data.frames(bf);
data.scores.int = prepScore(mInt,'dir');
data = removeFrames(data,bf);

end

% CODE GRAVEYARD 


% medInt  = (medInt-mean(medInt))./std(medInt);
% meanInt = (meanInt-mean(meanInt))./std(meanInt);
% skewInt = (skewInt-mean(skewInt))./std(skewInt);
% kurtInt = (kurtInt-mean(kurtInt))./std(kurtInt);

% skewInt = abs(skewInt-median(skewInt));

% [~,sortMedInt] = sort(medInt,'descend');
% [~,sortSkewInt] = sort(skewInt,'descend');
% figure;
% suptitle('highest median');
% for i=1:16
%     subplot(4,4,i); imshow(images{sortMedInt(i)});
% end
% figure;
% suptitle('lowest median');
% for i=0:15
%     subplot(4,4,i+1); imshow(images{sortMedInt(end-i)});
% end
% figure;
% suptitle('good skew');
% for i=1:16
%     subplot(4,4,i); imshow(images{sortSkewInt(i)});
% end
% figure;
% suptitle('bad skew');
% for i=0:15
%     subplot(4,4,i+1); imshow(images{sortSkewInt(end-i)});
% end

% figure;
% subplot(411);
% plot(medInt);
% ylabel('median','FontSize',16,'FontName','Arial');
% subplot(412);
% plot(meanInt);
% ylabel('mean','FontSize',16,'FontName','Arial');
% subplot(413);
% plot(skewInt);
% ylabel('skew','FontSize',16,'FontName','Arial');
% subplot(414);
% plot(kurtInt);
% xlabel('frame','FontSize',16,'FontName','Arial');
% ylabel('kurtosis','FontSize',16,'FontName','Arial');
% 
% figure;
% plot(medInt,'color','k');
% hold on;
% plot(meanInt,'color','g');
% plot(skewInt,'color','c');
% plot(kurtInt,'color','r');
% xlabel('frame','FontSize',16,'FontName','Arial');
% hold off;
% 
% figure;
% subplot(221);
% scatter(medInt, meanInt);
% hold on;
% fitLine  = polyfit(medInt, meanInt, 1);
% YfitLine  = polyval(fitLine, medInt);
% plot(medInt,YfitLine,'Color','r');
% xlim([min(medInt), max(medInt)]);
% ylim([min(meanInt), max(meanInt)]);
% xlabel('median','FontSize',16,'FontName','Arial');
% ylabel('mean','FontSize',16,'FontName','Arial');
% hold off;
% subplot(222);
% scatter(skewInt, kurtInt);
% hold on;
% fitLine  = polyfit(skewInt, kurtInt, 1);
% YfitLine  = polyval(fitLine, skewInt);
% plot(skewInt,YfitLine,'Color','r');
% xlim([min(skewInt), max(skewInt)]);
% ylim([min(kurtInt), max(kurtInt)]);
% xlabel('skewness','FontSize',16,'FontName','Arial');
% ylabel('kurtosis','FontSize',16,'FontName','Arial');
% hold off;
% subplot(223);
% scatter(medInt, skewInt);
% hold on;
% fitLine  = polyfit(medInt, skewInt, 1);
% YfitLine  = polyval(fitLine, medInt);
% plot(medInt,YfitLine,'Color','r');
% xlim([min(medInt), max(medInt)]);
% ylim([min(skewInt), max(skewInt)]);
% xlabel('median','FontSize',16,'FontName','Arial');
% ylabel('skew','FontSize',16,'FontName','Arial');
% hold off;
% subplot(224);
% scatter(meanInt, skewInt);
% hold on;
% fitLine  = polyfit(meanInt, kurtInt, 1);
% YfitLine  = polyval(fitLine, meanInt);
% plot(meanInt,YfitLine,'Color','r');
% xlim([min(meanInt), max(meanInt)]);
% ylim([min(kurtInt), max(kurtInt)]);
% xlabel('mean','FontSize',16,'FontName','Arial');
% ylabel('kurtosis','FontSize',16,'FontName','Arial');
% hold off;

% if kstest(medInt)
%     if skewness(medInt) > 0.2
%         medInt = log10(medInt+1);
%     elseif skewness(medInt) < -0.2
%         medInt = medInt.^2;
%     end
% end

% skewInt = prepScore(skewInt,'inv');
% thought: maybe distance from the 75th %ile would be better than straight
% maximum

% [ht,~] = size(images{1});
% cutoff = floor(ht/3);
% % thr = 2.2; % optimized to balance sens/spec
% topBounds = 1:cutoff;
% botBounds = ht-cutoff+1:ht;
% bimodal = zeros(nFrames,1);
% for i=1:nrf
%     flatImg = max(images{i},[],2);
%     top = flatImg(topBounds);
% %     top = (top-mean(top))./std(top);
%     bot = flatImg(botBounds);
% %     bot = (bot-mean(bot))./std(bot);
%     % DISPLAY
%     figure;
%     hist(top);
%     alpha(0.5);
%     h = findobj(gca,'Type','patch');
%     set(h,'FaceColor',[1 0 0]); 
%     hold on;
%     hist(bot);
%     alpha(0.5);
%     hold off;
%     varTop = var(top);
%     varBot = var(bot);
%     if varTop/varBot > 2 || varBot/varTop > 2
%         [~,p] = ttest2(top,bot,'Vartype','unequal');
%     else
%         [~,p] = ttest2(top,bot);
%     end
% 	bimodal(i) = log10(p);
% end
% 
% [~,I] = sort(bimodal);
% figure;
% for i=1:9
%     subplot(3,3,i); imshow(images{I(i)});
% end

%% Find bimodal images
% A bimodal image will have a significantly lower norm of residuals when fitted
% with a cubic than a line
% power = 3;
% [ht,~] = size(images{1});
% bimodal = zeros(nrf,1);
% row = (1:ht)';
% for i=1:nrf
%     flatImg = mean(images{gf(i)},2);
%     
%     % Fit lines
%     fitLine  = polyfit(row, flatImg, 1);
%     fitCubic = polyfit(row, flatImg, power);
%     
%     YfitLine  = polyval(fitLine,  row);
%     YfitCubic = polyval(fitCubic, row);
%     % Get residuals
%     resid1 = flatImg - YfitLine(:);
%     resid3 = flatImg - YfitCubic(:);
%     
%     normResids1(1) = norm(resid1);
%     normResids3(1) = norm(resid3);
%     
%     bimodal(i) = normResids1-normResids3;
% end
% 
% %%%%%%%%%%%
% % DISPLAY %
% %%%%%%%%%%%
% [~,sortBimodal] = sort(bimodal, 'descend');
% % [~,minBimodal] = min(bimodal);
% % [~,maxBimodal] = max(bimodal);
% % minImg = images{minBimodal};
% % maxImg = images{maxBimodal};
% 
% for i=0:9
%     minImg=images{sortBimodal(end-i)};
%     maxImg=images{sortBimodal(i+1)};
%     minFlatImg = mean(minImg,2);
%     maxFlatImg = mean(maxImg,2);
%     figure
%     subplot(321); imshow(minImg); title('least bimodal');
%     subplot(322); imshow(maxImg); title('most bimodal');
%     % least 1
%     subplot(323); plot(mean(minImg,2));
%     title('least bimodal, power=1'); xlabel('row'); ylabel('mean intensity');
%     hold on;
%     fitLine  = polyfit(row, minFlatImg, 1);
%     YfitLine = polyval(fitLine, row);
%     plot(row,YfitLine,'Color','r');
%     xlim([1 ht]);
%     hold off;
%     % most 1
%     subplot(324); plot(mean(maxImg,2));
%     title('most bimodal, power=1');  xlabel('row'); ylabel('mean intensity');
%     hold on;
%     fitLine  = polyfit(row, maxFlatImg, 1);
%     YfitLine = polyval(fitLine, row);
%     plot(row,YfitLine,'Color','r');
%     xlim([1 ht]);
%     hold off;
%     % least 3
%     subplot(325); plot(mean(minImg,2));
%     tstr = (['least bimodal, power=',num2str(power)]);
%     title(tstr); xlabel('row'); ylabel('mean intensity');
%     hold on;
%     fitLine  = polyfit(row, minFlatImg, power);
%     YfitLine = polyval(fitLine, row);
%     plot(row,YfitLine,'Color','r');
%     xlim([1 ht]);
%     hold off;
%     % most 3
%     subplot(326); plot(mean(maxImg,2));
%     tstr = (['most bimodal, power=',num2str(power)]);
%     title(tstr);  xlabel('row'); ylabel('mean intensity');
%     hold on;
%     fitLine  = polyfit(row, maxFlatImg, power);
%     YfitLine = polyval(fitLine, row);
%     plot(row,YfitLine,'Color','r');
%     xlim([1 ht]);
%     hold off;
% end
% 
% %% Normalize for output
% % if kstest(bimodal)
% %     if skewness(bimodal) > 0.2
% %         bimodal = log10(bimodal);
% %     elseif skewness(bimodal) < -0.2
% %         bimodal = bimodal.^2;
% %     end
% % end
% bimodal = prepScore(bimodal,'inv');


% CODE GRAVEYARD


% cutoff = floor(ht/3);
% thr = 2.2; % optimized to balance sens/spec
% topBounds = 1:cutoff;
% botBounds = ht-cutoff+1:ht;
% bimodal = false(nFrames,1);

% flatImg = mean(images{i},2);
% mTop    = mean(flatImg(topBounds));
% sdTop   = std(flatImg(topBounds));
% mBot    = mean(flatImg(botBounds));
% sdBot   = std(flatImg(botBounds));
% if (mTop+(thr*sdTop)) < (mBot-(thr*sdBot)) || ...
%         (mTop-(thr*sdTop)) > (mBot+(thr*sdBot))
%     bimodal(i) = true;
% end
