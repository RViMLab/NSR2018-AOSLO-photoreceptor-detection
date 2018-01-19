% close all;
clear;
% Robert Cooper 03-13-2013
% This script calculates the local density, mean nearest neighbor, 
% mean intercell spacing at EVERY pixel in the image. It
% requires a standard-formatted LUT and a source set of coordinates. It
% assumes the input coordinates are of the format (x,y)
% 
% Verison 0.1 - It does what it says. Deal with it.
%

% YOU WILL NEED TO SET THESE UNTIL I MAKE THIS PROGRAM PRETTIER.
micron_box_size = 55;
patient_code = 'DH_0152';
scaling_path = 'C:\Users\Mo\Desktop\Cone_Counting_Batch_Random\etc\LUT.csv';
coord_path   = 'C:\Users\Mo\Desktop\Cone_Counting_Batch_Random\coordinate_analysis\DH_0152_OD_07_29_2014_1p75&1p00_0p8759_cropped_flattened_coords2.txt'; 
% coord_path   = '/remote_project_folders/Heat map/AD_1207_1p5_T_montage_0p7134umpp_0002_split.csv'

% Load the scale LUT
fid = fopen(scaling_path,'r');
scaling = textscan(fid , '%s %f %f', 'delimiter', ',');
fclose(fid);

% Pick out the scaling value of the person we're looking at
[match matchind] = max(cellfun(@(cellname) ~isempty(regexpi(coord_path,cellname)),scaling{1}) );

um_per_pix = ((scaling{2}(matchind)/24)*291) / scaling{3}(matchind);

% Load the coordinates (as designated above)
coords = dlmread(coord_path);

coords = coords * [0 1; 1 0];

% Make a mask of all coordinates in the image
fullcoordmask = zeros(ceil(max(coords(:,1))),ceil(max(coords(:,2))) );
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
coordmask = zeros(ceil(max(coords_bound(:,1))),ceil(max(coords_bound(:,2))) );
inds = sub2ind(size(coordmask),round(coords_bound(:,1)),round(coords_bound(:,2)));
coordmask(inds) = 1;

% Make a MIC mask of all bound cells in the image
icmask = zeros(ceil(max(coords_bound(:,1))),ceil(max(coords_bound(:,2))) );

% Make a STDEV mask of all bound cells in the image
stdmask = zeros(ceil(max(coords_bound(:,1))),ceil(max(coords_bound(:,2))) );

% Make a N-N mask of all bound cells in the image
nnmask  = zeros(ceil(max(coords_bound(:,1))),ceil(max(coords_bound(:,2))) );

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
        correct_inter_cell_dist(m)      = um_per_pix*(sum(cell_dist(1,:)) / (length(cell_dist(1,:))-1));
        correct_max_cell_dist(m)        = um_per_pix*max(cell_dist(1,:));
        correct_nn_cell_dist(m)         = um_per_pix*min(cell_dist(1,2:end));
        
        ind = sub2ind(size(icmask),round(coords(k,1)),round(coords(k,2)));
        icmask(ind)     = correct_inter_cell_dist(m);
        nnmask(ind)     = correct_nn_cell_dist(m);
%         figure(1); triplot(dt); hold on; plot(coords(coord_row,1),coords(coord_row,2),'r.'); plot(coords(k,1),coords(k,2),'g.');  hold off;
        m=m+1;
    end
    
    inter_cell_dist = [inter_cell_dist um_per_pix*(sum(cell_dist(1,:)) / (length(cell_dist(1,:))-1))];
    max_cell_dist = [max_cell_dist um_per_pix*max(cell_dist(1,:))];
end

mean_inter_cell_dist = mean(inter_cell_dist);
mean_max_cell_dist = mean(max_cell_dist);

% figure(1); imshow(coordmask); colormap gray; title('Coordinate mask');
% figure(2); imshow(icmask);   colormap jet;  title('I-C mask');
% figure(3); imshow(nnmask);    colormap jet;  title('N-N mask');


% Make cell counting kernel (just a ones matrix)
pix_box_size  = round(micron_box_size/um_per_pix); % The size of the kernel box

densitypercell = (1/( (micron_box_size*micron_box_size)/(1000*1000) )); % The density per cell that it finds, in cells/mm

kernel = ones(pix_box_size,pix_box_size);

%Saving icmask for standard deviation calculation
icmask_unconvolved = icmask;

% size(icmask)
% Perform the convolutions
cellcountmap    = conv2(coordmask,kernel,'valid');
densitymap      = conv2(fullcoordmask,kernel.*densitypercell,'valid');
icmask          = conv2(icmask,kernel,'valid');
nntotalmap      = conv2(nnmask,kernel,'valid');
% size(icmask)

% figure(50); imagesc(icmask);   colormap jet;  title('I-C mask');

% figure(4); imagesc(icmask);   colormap gray;  title('I-C mask');

% Make our maps!
icmap       = icmask./cellcountmap;
nnmap       = nntotalmap ./cellcountmap;

% Determine centers of max density, and min N-N and I-C spacing
max_density = max(densitymap(:));
min_ic      = min(icmap(:))
min_nn      = min(nnmap(:))

[densrows denscols] = find(densitymap == max_density);
numdens  = length(densrows);
[icrows   iccols] = find(icmap     == min_ic);
nummic   = length(icrows);
[nnrows     nncols] = find(nnmap      == min_nn);
numnn    = length(nnrows);

% locating the minimum ICD and standard deviation, choosing the first entry.
center_coordinate_row = icrows + pix_box_size/2 - 1;
center_coordinate_col = iccols + pix_box_size/2 - 1;
deconvolved_values = icmask_unconvolved(center_coordinate_row-floor(pix_box_size/2):center_coordinate_row+floor(pix_box_size/2),...
                                        center_coordinate_col-floor(pix_box_size/2)+1:center_coordinate_col+floor(pix_box_size/2)+1);
size(deconvolved_values)
deconvolved_values = nonzeros(deconvolved_values);

ICD_standard_dev = std(deconvolved_values)

check_value = mean(deconvolved_values)
['This should be equal to the min_ic, if not, make sure the box is the correct size']

% Display the results to screen.
plots = figure(1);
% subplot(131); 
imagesc(densitymap);  colormap jet; title('Density map'); axis image; colorbar; hold on; plot(denscols,densrows,'w+');hold off
%imagesc(icmap);       colormap jet; title('I-C map');     axis image; colorbar; hold on; plot(iccols,icrows,'w+');hold off
%imagesc(nnmap);       colormap jet; title('N-N map');     axis image; colorbar; hold on; plot(nncols,nnrows,'w+');hold off

[n bin] = hist(densitymap(:),31);

jetcolor = 255*jet(length(bin));
bin = bin + (bin(2)-bin(1))/2 + 1000;
bin = [0 bin];

densred = uint8(zeros(size(densitymap)));
densgrn = uint8(zeros(size(densitymap)));
densblu = uint8(zeros(size(densitymap)));

i=1; 
densred(densitymap<bin(i)) = jetcolor(i,1);
densgrn(densitymap<bin(i)) = jetcolor(i,2);
densblu(densitymap<bin(i)) = jetcolor(i,3);

for i=2:length(bin);
% [loci locj]=find( (densitymap<bin(i)) & (densitymap>=bin(i-1)) );
densred((densitymap<bin(i)) & (densitymap>=bin(i-1))) = jetcolor(i-1,1);
densgrn((densitymap<bin(i)) & (densitymap>=bin(i-1))) = jetcolor(i-1,2);
densblu((densitymap<bin(i)) & (densitymap>=bin(i-1))) = jetcolor(i-1,3);
end

densred(densitymap>bin(i)) = jetcolor(i-1,1);
densgrn(densitymap>bin(i)) = jetcolor(i-1,2);
densblu(densitymap>bin(i)) = jetcolor(i-1,3);


denscolor = cat(3,densred,densgrn, densblu);

imwrite(denscolor,[ patient_code '_' num2str(micron_box_size) 'um_box.tif']);



saveas(plots,[ patient_code '_' num2str(micron_box_size) 'um_box.eps'],'epsc')





