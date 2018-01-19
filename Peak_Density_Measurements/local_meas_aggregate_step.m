% close all;
% clear;
% Robert Cooper 03-13-2013
% This script calculates the local density, mean nearest neighbor, 
% mean intercell spacing at EVERY pixel in the image. It
% requires a standard-formatted LUT and a source set of coordinates. It
% assumes the input coordinates are of the format (x,y)
% 
% Verison 0.1 - It does what it says. Deal with it.
%

% YOU WILL NEED TO SET THESE UNTIL I MAKE THIS PROGRAM PRETTIER.
micron_box_size = [55];
scaling_path = 'R:\Rob Cooper\Structural_Metrics_2014\data\Normal Data\LUT.csv';
coord_path   = 'R:\Rob Cooper\Structural_Metrics_2014\data\Normal Data\AD_10253\Fovea Center Finding\AD_10253_790nm_OS_confocal_0009_ref_84_lps_12_lbss_12_sr_n_50_cropped_5_coords.txt'; 
im_path      = 'R:\Rob Cooper\Structural_Metrics_2014\data\Normal Data\AD_10253\Fovea Center Finding\AD_10253_790nm_OS_confocal_0009_ref_84_lps_12_lbss_12_sr_n_50_cropped_5.tif';

% Load the image
im = imread(im_path);

% Load the scale LUT
fid = fopen(scaling_path,'r');
scaling = textscan(fid , '%s%f%f', 'delimiter', ',');
fclose(fid);

% Pick out the scaling value of the person we're looking at
[match matchind] = max(cellfun(@(cellname) ~isempty(regexpi(coord_path,cellname)),scaling{1}) );

um_per_pix = ((scaling{2}(matchind)/24)*291) / scaling{3}(matchind);

% Load the coordinates (as designated above)
coords = ceil(dlmread(coord_path));

coords = coords * [0 1; 1 0];

% Make a mask of all coordinates in the image
fullcoordmask = zeros(size(im) );
inds = sub2ind(size(fullcoordmask),round(coords(:,1)),round(coords(:,2)));
fullcoordmask(inds) = 1;

% Determine which cells are bound
[V,C] = voronoin(coords,{'QJ'}); % Returns the vertices of the Voronoi edges in VX and VY so that plot(VX,VY,'-',X,Y,'.')
cellvert = [];
bound = zeros(size(coords,1),1);
for i=1:length(C)
   
    vertices=V(C{i},:);
    
    if (all(C{i}~=1)  && all(vertices(:,1)<max(coords(:,1))) && all(vertices(:,2)<max(coords(:,2)) ) ... % Second row are the Column limits
                      && all(vertices(:,1)>min(coords(:,1))) && all(vertices(:,2)>min(coords(:,2)) ) )    % First row is the Row limits
        coords_bound(i,:) = coords(i,:);
        bound(i) = 1;
    end
end

coords_bound=coords_bound(coords_bound(:,1)~=0,:); % Clip out the unbounded cells

% Make a mask of the bound coordinates in the image
coordmask = zeros(max(coords_bound(:,1)),max(coords_bound(:,2)) );
inds = sub2ind(size(coordmask),round(coords_bound(:,1)),round(coords_bound(:,2)));
coordmask(inds) = 1;

% Make a MIC mask of all bound cells in the image
icmask = zeros(max(coords_bound(:,1)),max(coords_bound(:,2)) );

% Make a N-N mask of all bound cells in the image
nnmask  = zeros(max(coords_bound(:,1)),max(coords_bound(:,2)) );

% Calculate N-N and M-I-C distances
dt = DelaunayTri(coords);
m=1;
max_cell_dist=[];
inter_cell_dist=[];
% Find all instances of each coordinate point
for k=1 : size(coords,1)
   
    [i j] =find(dt.Triangulation == k);

    conn_ind = dt.Triangulation(i,:);

    coord_row = unique(conn_ind( conn_ind ~= k)); % Find all of the unique coordinate points that isn't the "center" coordinate

    if(size(i,1)~=1)
        coord_row = [k; coord_row]; % Add the "center" to the top, so we know the order for the distances
    else
        coord_row = [k; coord_row']; 
    end

    cell_dist = squareform(pdist([coords(coord_row,1) coords(coord_row,2)]));
        
    if bound(k) == 1 % If its bound, then we've flagged it as such, and can use it in the triangulation
        % Only take the first row because that is the cell of interest's
        % relative distance to its neighboring cells
        correct_inter_cell_dist(m) = um_per_pix*(sum(cell_dist(1,:)) / (length(cell_dist(1,:))-1));
        correct_max_cell_dist(m) = um_per_pix*max(cell_dist(1,:));
        correct_nn_cell_dist(m) = um_per_pix*min(cell_dist(1,2:end));
        
        ind = sub2ind(size(icmask),round(coords(k,1)),round(coords(k,2)));
        icmask(ind) = correct_inter_cell_dist(m);
        nnmask(ind)  = correct_nn_cell_dist(m);
        
%         figure(1); triplot(dt); hold on; plot(coords(coord_row,1),coords(coord_row,2),'r.'); plot(coords(k,1),coords(k,2),'g.');  hold off;
        m=m+1;
    end
    
    inter_cell_dist = [inter_cell_dist um_per_pix*(sum(cell_dist(1,:)) / (length(cell_dist(1,:))-1))];
    max_cell_dist = [max_cell_dist um_per_pix*max(cell_dist(1,:))];
end

mean_inter_cell_dist = mean(inter_cell_dist);
mean_max_cell_dist = mean(max_cell_dist);

% figure(1); imshow(coordmask); colormap gray; title('Coordinate mask');
% figure(2); imshow(micmask);   colormap jet;  title('M-I-C mask');
% figure(3); imshow(nnmask);    colormap jet;  title('N-N mask');


% Make cell counting kernel (just a ones matrix)
pix_box_size  = round(micron_box_size/um_per_pix); % The size of the kernel box

densitypercell = (1/( (micron_box_size*micron_box_size)/(1000*1000) )); % The density per cell that it finds, in cells/mm

kernel = ones(pix_box_size,pix_box_size);

% Perform the convolutions
cellcountmap = conv2(coordmask,kernel,'valid');
densitymap   = conv2(fullcoordmask,kernel.*densitypercell,'valid');
icmask  = conv2(icmask,kernel,'valid');
nntotalmap   = conv2(nnmask,kernel,'valid');

% Make our maps!
icmap     = icmask./cellcountmap;
nnmap      = nntotalmap ./cellcountmap;

% Determine centers of max density, and min N-N and I-C spacing
max_density = max(densitymap(:));
min_ic     = min(icmap(:));
min_nn      = min(nnmap(:));

[densrows denscols] = find(densitymap == max_density);
numdens  = length(densrows);
[icrows   iccols] = find(icmap     == min_ic);
nummic   = length(icrows);
[nnrows     nncols] = find(nnmap      == min_nn);
numnn    = length(nnrows);


avgcol = round(mean(denscols));
avgrow = round(mean(densrows));

% Display the results to screen.
figure(4); imagesc(densitymap); colormap jet; title('Density map'); axis image; colorbar; hold on; 
plot(denscols, densrows,'w+'); 
plot(avgcol, avgrow,'b+'); 
hold off;
% figure(5); imagesc(icmap);     colormap jet; title('I-C map');   axis image; colorbar; hold on; plot(iccols,icrows,'w+');hold off
% figure(6); imagesc(nnmap);      colormap jet; title('N-N map');     axis image; colorbar; hold on; plot(nncols,nnrows,'w+');hold off



