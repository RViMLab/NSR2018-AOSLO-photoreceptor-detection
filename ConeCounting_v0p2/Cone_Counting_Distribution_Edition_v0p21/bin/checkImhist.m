function [ imgs ] = checkImhist( imgs, mag, zoom )
%checkImhist normalizes the sample image to the template image if the
%intensity distribution differs significantly
%
%imgs should be a cell array of images with either linear or log
%scaling, mag should be the index of the sample image, zoom will either be
%a string '-' or '+' indicating where the template image is.
%
%Checks parameters: mean, standard deviation, kurtosis, and skewness

a = 0.01; %alpha

templateInd = mag-1;
if strcmp(zoom,'-')
    templateInd = mag+1;
end

u8TemImg   = imgs{templateInd};
mTemplate  = mean(u8TemImg(:));
dblTemVec  = double(u8TemImg(:));
sdTemplate = std(dblTemVec);
kurtTem    = kurtosis(dblTemVec);
skewTem    = skewness(dblTemVec);

u8SamImg   = imgs{mag};
mSample    = mean(u8SamImg(:));
dblSamVec  = double(u8SamImg(:));
sdSample   = std(dblSamVec);
kurtSam    = kurtosis(dblSamVec);
skewSam    = skewness(dblSamVec);

try
    dMeans  = abs(mSample-mTemplate)/mTemplate;
    dStdevs = abs(sdSample-sdTemplate)/sdTemplate;
    dKurt   = abs(kurtSam-kurtTem)/kurtTem;
    dSkew   = abs(skewSam-skewTem)/skewTem;
catch % If any template parameters == 0
    if mTemplate == 0 && mSample ~= 0
        dMeans = a+1;
    else
        dMeans = a-1;
    end
    if sdTemplate == 0 && sdSample ~= 0
        dStdevs = a+1;
    else
        dStdevs = a-1;
    end
    if kurtTem == 0 && kurtSam ~= 0
        dKurt = a+1;
    else
        dKurt = a-1;
    end
    if skewTem == 0 && skewSam ~= 0
        dSkew = a+1;
    else
        dSkew = a-1;
    end
end


if dMeans > a || dStdevs > a || dKurt > a || dSkew > a
    % Normalize all
    for i=1:length(imgs)
        if ~isempty(imgs{i}) && i~=templateInd
            img = imgs{i};
            imgs{i} = histeq(img,imhist(u8TemImg));
        end
    end
end

end

