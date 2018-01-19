function [ncc] = getNCC(img1, img2)
%getNCC This NCC is meant for strip registration
%   Originally written by Dr. Alf Dubra
%   Adapted for this project by Alex Salmon

% roundoff threshold
threshold = 1e-6;

% Make sure img1 is smaller than img2
if numel(img1) > numel(img2)
    tmpImg   = img2;
    img2     = img1;
    img1     = tmpImg;
end

[nRows1, nCols1] = size(img1);
[nRows2, nCols2] = size(img2);

% pad both images
pad1 = zeros(nRows1+nRows2-1, nCols1+nCols2-1);
pad2 = zeros(nRows1+nRows2-1, nCols1+nCols2-1);

pad1(1:nRows1, 1:nCols1)     = img1;
pad2(nRows1:end, nCols1:end) = img2;

% Using the correlation theorem to calculate the cross-correlation
crossCorr = real(ifft2(conj(fft2(pad1)).*fft2(pad2)));

% normalization
pupilImg1 = zeros(size(pad1));
pupilImg2 = pupilImg1;

pupilImg1(1:nRows1, 1:nCols1)     = 1;
pupilImg2(nRows1:end, nCols1:end) = 1;

normFactor1 = real(ifft2(conj(fft2(pad1.^2)).*fft2(pupilImg2)));
normFactor2 = real(ifft2(conj(fft2(pupilImg1)).*fft2(pad2.^2)));
    
% roundoff errors lead to negative values in the autocorrelation
% and thus the need to remove them manually
normFactor1 = normFactor1.*(normFactor1 >= 0);
normFactor2 = normFactor2.*(normFactor2 >= 0);
 
zeroCrossCorrMask = (normFactor1 > threshold) & (normFactor2 > threshold);

% including eps to avoid problems when denominator is null
ncc = zeroCrossCorrMask.*crossCorr./sqrt(eps+normFactor1.*normFactor2);

end