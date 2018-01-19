function [ maxNcc, dx, dy, failed ] = tryFF( sample, template, data )
%tryFF An attempt at full frame registration first
%   Detailed explanation goes here

ncc = getNCC(sample, template);
[ncc, failed] = processFF(ncc, data);

if failed
    maxNcc = 0;
    dx = 0;
    dy = 0;
    return;
end

maxNcc = max(ncc(:)); % for output
[ypeak,xpeak] = find(ncc==maxNcc);
dx = xpeak - data.size(2);
dx = -dx; % for some reason
dy = ypeak - data.size(1);

end

