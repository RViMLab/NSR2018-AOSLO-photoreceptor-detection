close all;
clear;
% Robert Cooper 03-13-2013
% This script calculates the local density, mean nearest neighbor, 
% mean intercell spacing at EVERY pixel in the image. It
% requires a standard-formatted LUT and a source set of coordinates. It
% assumes the input coordinates are of the format (x,y)
% 
% Version 0.1 - It does what it says. Deal with it.
%

% YOU WILL NEED TO SET THESE UNTIL I MAKE THIS PROGRAM PRETTIER.
micron_box_size = [21:2:39,42,45];
reference_micron_value = 37;
scaling_path = 'C:\Users\aolab\Documents\MATLAB\Peak_Density_Measurements\scaleLUT.csv';
coord_path   = 'Z:\Data\1Controls\MM_0364_Tom\AO_MEH_SLO\25_07_2017_OS\Montages\MM_0364_OS_15um_pinhole_0p75_0p3687umpx_crop1_coords_manual.txt';
im_path      = 'Z:\Data\1Controls\MM_0364_Tom\AO_MEH_SLO\25_07_2017_OS\Montages\MM_0364_OS_15um_pinhole_0p75_0p3687umpx_crop1.tif';
outpath      = 'Z:\Data\1Controls\MM_0364_Tom\AO_MEH_SLO\25_07_2017_OS\Montages';

% Load the image
im = imread(im_path);

% Load the scale LUT
fid = fopen(scaling_path,'r');
scaling = textscan(fid , '%s%f%f', 'delimiter', ',');
fclose(fid);

% Pick out the scaling value of the person we're looking at
[match matchind] = max(cellfun(@(cellname) ~isempty(regexpi(coord_path,cellname)),scaling{1}) );

%Check to make sure the subject ID was found
if match == 0
    error('Subject information was not entered in LUT, please correct!')
end

um_per_pix = ((scaling{2}(matchind)/24)*291) / scaling{3}(matchind);

% Load the coordinates (as designated above)
coords = ceil(dlmread(coord_path));

coords = coords * [0 1; 1 0];

for m=1:length(micron_box_size)

% Make a mask of all coordinates in the image
fullcoordmask = zeros(size(im) );
inds = sub2ind(size(fullcoordmask),round(coords(:,1)),round(coords(:,2)));
fullcoordmask(inds) = 1;

% Make cell counting kernel (just a ones matrix)
pix_box_size  = round(micron_box_size(m)/um_per_pix); % The size of the kernel box
pix_half_size = micron_box_size(m)/(2*um_per_pix);

densitypercell = (1/( (micron_box_size(m)*micron_box_size(m))/(1000*1000) )); % The density per cell that it finds, in cells/mm

kernel = ones(pix_box_size,pix_box_size);

% Perform the convolution
densitymap   = conv2(fullcoordmask,kernel.*densitypercell,'valid');

% Determine centers of max density, and min N-N and I-C spacing
max_density = max(densitymap(:));

[densrows denscols] = find(densitymap == max_density);
numdens  = length(densrows);

% Find the average location of the densities- they should all be close if
% this is a normal fovea!
avgcol(m) = round(mean(denscols+pix_half_size));
avgrow(m) = round(mean(densrows+pix_half_size));
if micron_box_size(m) == reference_micron_value
    reference_map = densitymap;
    reference_offset = pix_half_size;
end

% Display the results to screen.
% figure(m); imagesc(densitymap); colormap jet; title('Density map'); axis image; colorbar; hold on; 
% plot(denscols, densrows,'w+');  
% hold off;

end

averagecolloc = round(mean(avgcol));
averagerowloc = round(mean(avgrow));

% BW = reference_map >0;
% s = regionprops(BW, reference_map, {'WeightedCentroid'});

figure;
imagesc(im); title('Used Image'); axis image; hold on; colormap gray;
plot(avgcol, avgrow,'b+');
plot(averagecolloc, averagerowloc,'r+');

hold off;

peak_density = reference_map(round(averagerowloc-reference_offset), round(averagecolloc-reference_offset));

saveas(gcf,[outpath '_' num2str(averagecolloc) '_' num2str(averagerowloc) '_peak' num2str(round(peak_density)) '_onimage.fig'],'fig');

figure;
imagesc(reference_map); colormap jet; axis image; hold on;
plot(averagecolloc-reference_offset, averagerowloc-reference_offset,'w+');
% plot(s.WeightedCentroid(1), s.WeightedCentroid(2),'w+');


% C = contourc(reference_map);
% contourf(C);

hold off;
disp(['Peak density at image coordinates: (' num2str(averagecolloc) ',' num2str(averagerowloc) ') was: ' num2str(peak_density)]);
saveas(gcf,[outpath '_' num2str(averagecolloc) '_' num2str(averagerowloc) '_peak' num2str(round(peak_density)) '.fig'],'fig');
