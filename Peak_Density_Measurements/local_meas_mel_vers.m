
function [max_density numdens min_mic nummic min_nn numnn densitymap micmap nnmap]=local_meas_mel_vers(micron_box_size, max_window)
%function [max_density min_mic min_nn]=local_meas(micron_box_size)
% Robert Cooper 03-13-2013
% This script calculates the local density, nearest neighbor(nn) mean intercell spacing (mic) at EVERY pixel in the image. It
% requires a standard-formatted LUT and a source set of coordinates. It
% assumes the input coordinates are of the format (x,y)
% 
% Verison 0.1 - It does what it says. Deal with it.
%
% Actual density values at each point are stored in the matrix  "micmap". Everything
% else is normalized for viewing.
%clear all;
% YOU WILL NEED TO SET THESE UNTIL I MAKE THIS PROGRAM PRETTIER.
%micron_box_size = boxes();
scaling_path = 'C:\Users\aolab\Documents\MATLAB\Peak_Density_Measurements\scaleLUT.csv';
coord_path   = 'Z:\Data\0Current\MM_0362\AO_MEH_SLO\17_05_2017_OD\Montages\1p5\MM_0362_OD_1p5_0p7014umpx_foveal_centre_split_coords.txt'; 

% Load the scale LUT
fid = fopen(scaling_path,'r');
scaling = textscan(fid , '%s %f %f', 'delimiter', ',');
fclose(fid);

% Pick out the scaling value of the person we're looking at
[match matchind] = max(cellfun(@(cellname) ~isempty(regexpi(coord_path,cellname)),scaling{1}) );

um_per_pix = ((scaling{2}(matchind)/24)*291) / scaling{3}(matchind);

% Load the coordinates (as designated above)
coords = dlmread(coord_path);

minx = min(coords(:,1));
miny = min(coords(:,2));

% Subtract out the minimum coordinate so that we're centered on 0,0
coords(:,1) = 1+coords(:,1)-minx;
coords(:,2) = 1+coords(:,2)-miny;


%% TO GET THE OFFSET minval + halfboxwidth -1
%%
% Make a mask of all coordinates in the image
fullcoordmask = zeros(max(coords(:,1)),max(coords(:,2)) );
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
micmask = zeros(max(coords_bound(:,1)),max(coords_bound(:,2)) );

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
        
        ind = sub2ind(size(micmask),round(coords(k,1)),round(coords(k,2)));
        micmask(ind) = correct_inter_cell_dist(m);
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
%Made change from 'valid' to 'same'
cellcountmap = conv2(coordmask,kernel,'same');
densitymap   = conv2(fullcoordmask,kernel.*densitypercell,'same');
mictotalmap  = conv2(micmask,kernel,'same');
nntotalmap   = conv2(nnmask,kernel,'same');

densMapName = ['Pre-trim_Density_Map_' num2str(micron_box_size) '.csv'];
dlmwrite(densMapName, densitymap);

% Make our maps!
micmap     = mictotalmap./cellcountmap;
nnmap      = nntotalmap./cellcountmap;

%Change max_window to pixels of max window size (this part added 3/22/13)
max_window_pix = (max_window/um_per_pix);  %Size of max window in pixels will be used for cropping area
tempID = scaling{1}(22); %Change second # in () to order # from scaleLUT
fprintf('%s%s%s%f','Subject ID: ',tempID{1},' Max window in pixels: ',max_window_pix);
half_max_window = round(max_window_pix/2);        %Size to crop from each edge of image

%Crop off data that is invalid with the largest window size
densitymap = densitymap((1+half_max_window):(end - half_max_window),((1+half_max_window):(end - half_max_window)));

% Determine centers of max density, and min N-N and M-I-C spacing
max_density = max(densitymap(:));
min_mic     = min(micmap(:));
min_nn      = min(nnmap(:));

[densrows denscols] = find(densitymap == max_density);
numdens  = length(densrows);
[microws miccols]   = find(micmap == min_mic);
nummic   = length(microws);
[nnrows  nncols]    = find(nnmap  == min_nn);
numnn    = length(nnrows);

%Convert the x,y coords from matrix format to coordinates in the image in
%pixels
imageDens = ([(densrows + minx + half_max_window - 1), (denscols + miny + half_max_window - 1)]);
imageMIC = ([(microws + minx + half_max_window - 1) (miccols + miny + half_max_window - 1)]);
imageNN = ([(nnrows + minx + half_max_window - 1) (nncols + miny + half_max_window - 1)]);

%Save the offset info
offset(1,1) = minx;
offset(2,1) = half_max_window;
offset(3,1) = (minx + half_max_window -1);
offset(1,2) = miny;
offset(2,2) = half_max_window;
offset(3,2) = (miny + half_max_window -1);
dlmwrite('Offset.csv', offset, 'delimiter', '\t')


%Output the coordinates of peak density, min mic, and min nn using
%coordinates in the image in pixels
DensName = ['Peak_Density_Coord_' num2str(micron_box_size) '.csv'];
MICName = ['Min_MIC_Coord_' num2str(micron_box_size) '.csv'];
NNName = ['Min_NN_Coord_' num2str(micron_box_size) '.csv'];
dlmwrite(DensName,imageDens)
dlmwrite(MICName,imageMIC)
dlmwrite(NNName,imageNN)
%dlmwrite('DensMap.csv', densmap)

% Display the results to screen.
figure(4); imagesc(densitymap); colormap jet; title('Density map'); axis image; colorbar; hold on; plot(denscols,densrows,'w+');hold off
figure(5); imagesc(micmap);     colormap jet; title('M-I-C map');   axis image; colorbar; hold on; plot(miccols,microws,'w+');hold off
figure(6); imagesc(nnmap);      colormap jet; title('N-N map');     axis image; colorbar; hold on; plot(nncols,nnrows,'w+');hold off



