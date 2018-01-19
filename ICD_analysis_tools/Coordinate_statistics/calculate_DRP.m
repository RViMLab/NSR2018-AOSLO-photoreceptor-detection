function [ density_per_annulus um_drp_sizes est_spacing] = calculate_DRP( coords , coord_bounds , um_per_pix, density_dc, reliability )
% Robert Cooper 06-28-2012
%   This script is calculates the DRP of an input set of coordinates,
%   including the compensation factor referenced. This script is based on
%   R.W. Rodieck's 1990 Density Recovery Profile paper.
%
% Input Args:
%   @coords: This should be an Nx2 column of data, with column 1 being X
%   coordinates and column 2 being Y coordinates.
%
%   @coords_bounds: This should be a two element array containing the minimum and maximum
%   X and Y size, in the format [xMin xMax;
%				 yMin yMax]
%
%   @um_per_pix: The micron per pixel scale of the image- used in calculating the bin size.
%
%   @density_dc: The density of the whole area- used in calculating the bin size.
%
%   @reliability: The reliability factor- if you have highly reliable data, use a higher number
%


width  = coord_bounds(1,2)-coord_bounds(1,1);
height = coord_bounds(2,2)-coord_bounds(2,1);

% Equation for determine min bin size Rodieck (1990)
s = min( [width, height] ) * (um_per_pix/1000); % smallest length of the two sides
k = reliability; %Reliability factor
D = density_dc; % Density in um^2

um_per_bin = (1000 * k / ( s * D *sqrt(pi) ));
pix_per_bin = round(um_per_bin/um_per_pix);

% If it's at a subpixel level, cap it to be a single pixel and a single
% micron/pixel
if pix_per_bin == 0
    pix_per_bin = 1;
    um_per_bin = um_per_pix;
end

num_of_bins = round((1000*s/um_per_bin)/2)+2;
if num_of_bins<5
   num_of_bins=5;
end

drp_sizes = zeros(num_of_bins,1);
drp_sizes(1) = 1; % To prevent dividing by zero later
for i = 2: num_of_bins-1
   
    drp_sizes(i) = pix_per_bin * (i-1);
    
end
% Make sure we don't have duplicate sizes.
drp_sizes = unique(drp_sizes);
um_drp_sizes = drp_sizes * um_per_pix;

num_cells_in_annulus = zeros(size(coords,1),length(drp_sizes));
density_per_annulus = zeros(length(drp_sizes)-1,1);
edgefactor = 1 - 1/pi; % Edge factor integrated

for i=2 :1: length(drp_sizes)

xMin = coord_bounds(1,1) + drp_sizes(i);
xMax = coord_bounds(1,2) - drp_sizes(i);

yMin = coord_bounds(2,1) + drp_sizes(i);
yMax = coord_bounds(2,2) - drp_sizes(i);

xBounds = [xMin xMax];
yBounds = [yMin yMax];

% Establish which cells are inside and outside the region we'll use.

cell_coords_xor = coordclip(coords,xBounds,yBounds,'xor');
cell_coords_inside = coordclip(coords,xBounds,yBounds,'i');
cell_coords_and = coordclip(coords,xBounds,yBounds,'and');

numcellsinside = size(cell_coords_inside,1);
numcellsxor = size(cell_coords_xor,1);
numcellsand = size(cell_coords_and,1);

% This plot shows the clipped areas
% figure(i-1); plot(cell_coords_inside(:,2),cell_coords_inside(:,1),'b.',cell_coords_xor(:,2),cell_coords_xor(:,1),'g.',...
%            cell_coords_and(:,2),cell_coords_and(:,1),'r.',[xMin xMin xMax xMax xMin],[yMin yMax yMax yMin yMin],'c')

% xor_dist_to_edge = dist_to_edge(cell_coords_xor,'closest',coord_bounds);% * um_per_pix/1000;

coords_reordered = [cell_coords_inside;cell_coords_xor;cell_coords_and];

% [coords_reordered ind] = unique(coords_reordered,'rows');
% cell_coords_repeat = setxor(1:length(coords_reordered),ind);

% coords_reordered=coords_reordered(cell_coords_repeat,:);

% Take reordered coordinates and find the distance between them all - each
% coord is along the row
um_dist_between_pts = pdist2(coords_reordered,coords_reordered).*um_per_pix;

unadjustedarea = pi*(drp_sizes(i)*drp_sizes(i) - drp_sizes(i-1)*drp_sizes(i-1));   %In pixels

% edgefactor = 1 - ( acos(xor_dist_to_edge/drp_sizes( i )) / pi ); %edge
% factor calculated for each
edgearea = (unadjustedarea * edgefactor * (um_per_pix*um_per_pix) / (1000*1000));

cornerfactor = 1 - ( ((2*drp_sizes(i)) / (pi*width*height) ) * (width + height) )...
             + ( (drp_sizes(i)*drp_sizes(i)) / (pi*width*height) );
cornerarea = (unadjustedarea * cornerfactor * (um_per_pix*um_per_pix) / (1000*1000)); %ones(1,length(cell_coords_and)) .* 


unadjustedarea = unadjustedarea * (um_per_pix*um_per_pix) / (1000*1000); %ones(1,length(cell_coords_inside)) .*


num_cells_in_annulus(:,i-1) = sum( (um_drp_sizes(i-1) < um_dist_between_pts) & ...
                                   (um_dist_between_pts <= um_drp_sizes(i)), 2);

centerdens = num_cells_in_annulus(1:numcellsinside,i-1) / unadjustedarea;


edgedens = num_cells_in_annulus(numcellsinside+1 : numcellsinside+numcellsxor,i-1) ./ edgearea;


cornerdens = num_cells_in_annulus(numcellsinside+numcellsxor+1:...
                                numcellsinside+numcellsxor+numcellsand,i-1 ) / cornerarea;

density_per_annulus(i-1) = mean([centerdens; edgedens; cornerdens]);


%       disp('.');
%     for j=1 : length(coords)


%     coords(i,1)
%     coords(i,2)
%     
%     figure(2);
%     imagesc(annulus); colormap gray;
%       hold on;
%       plot(cell_coords_inside(:,2),cell_coords_inside(:,1),'b.',cell_coords_xor(:,2),cell_coords_xor(:,1),'g.',...
%           cell_coords_and(:,2),cell_coords_and(:,1),'r.',[xMin xMin xMax xMax xMin],[yMin yMax yMax yMin yMin],'c')
%       hold off;
    
%         lt = (um_dist_between_pts <= um_drp_sizes(i));
%         gt = (um_drp_sizes(i-1) < um_dist_between_pts);
%         num_cells_in_rad(i-1) = sum(sum( lt.*gt)); 
% 
% %     end
% 
%     % Subtract one to account for the cell itself being included
%     density_per_rad(i-1) = num_cells_in_rad(i-1) / drp_area(i-1);
    
end

um_drp_sizes = um_drp_sizes(2:end)';

% Auto-peak finding approach.
change = diff(um_drp_sizes);
resamplex=change/10;
minsample=min(um_drp_sizes);
maxsample=max(um_drp_sizes);
interpdrpx = minsample:resamplex:maxsample;
% If we don't have enough to fit splines, then just pick the 2nd value
if length(um_drp_sizes) >= 2 && length(density_per_annulus) >= 2 && length(interpdrpx) >= 2 
    splined= spline(um_drp_sizes,density_per_annulus,interpdrpx);

    % Start looking for points AFTER the known "0's"
    lastzero=1;
    for i=1:length(splined)
        if splined(i) == 0
            lastzero = i;
        else
            break
        end
    end

    localextremabins = interpdrpx(lastzero:end);
    localextrema = splined(lastzero:end);
    
    if length(localextrema) >= 3
        % Find the first local maxima.
        % for i=1:length(localextrema)
        %     if localextrema(i) == 0 && localextrema(i-1) > 0
        %         localmaxx = localextremabins(i);
        %         localmaxy = splined(i+lastzero);
        %     end
        % end

        % Could write my own localmax finder, but I am too lazy...
        [localmaxy, localmaxx]= findpeaks(localextrema,localextremabins);

        %Only use the first peak that is higher than the mean height (designed to
        %kill off the ER-level peaks)
        mean_density = mean(density_per_annulus);
        for i=1:length(localmaxy)
            if localmaxy(i) >= mean_density 
                localmaxx = localmaxx(i);
                localmaxy = localmaxy(i);
                break;
            end
        end
        if ~isempty(localmaxx)
            est_spacing = localmaxx;
        else
            % If there aren't peaks, pick the first peak that is above
            % the mean density.
            for i=1:length(localextrema)
                if localextrema(i) >= mean_density 
                    est_spacing = localextremabins(i);
                    localmaxy=localextrema(i);
                    break;
                end
            end
        end
    else
        est_spacing = localextrema(1);
    end
else
    est_spacing= um_drp_sizes(2);
end

% figure(1); bar(um_drp_sizes,density_per_annulus); hold on; plot(interpdrpx,splined); 
% % Plot our markers
% plot(est_spacing,localmaxy,'r*');  
% plot(um_drp_sizes,repmat(mean_density,length(um_drp_sizes),1),'r'); 
% hold off;
% saveas(gcf,[tag '_' num2str(est_spacing) '_spac.png'],'png');
% pause;
end

