function [ mosaic_stats ] = determine_mosaic_stats_ICDout( coords, scale, bounds ,clipped_row_col,reliability, ICDdatapath, subID )
% Robert Cooper 09-24-14
% This function takes in a list of coordinates in a m-2 matrix, and
% calculates the mean nearest neighbor, cell area created by the
% coordinates, and calculates the density of the coordinates

%% Coords are in X,Y!
warning('on','all');
%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Mean N-N %%
%%%%%%%%%%%%%%%%%%%%%%%%

dist_between_pts=pdist2(coords,coords); % Measure the distance from each set of points to the other
max_ident=eye(length(dist_between_pts)).*max(dist_between_pts(:)); % Make diagonal not the minimum for any observation

[minval minind]=min(dist_between_pts+max_ident); % Find the minimum distance from one set of obs to another

mean_nn_dist=mean(minval.*scale); % Distance in microns

% std(minval.*um_per_pix)
regularity_nn_index = mean_nn_dist/std(minval.*scale);

% wb = waitbar(.2,'Determining Voronoi');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Voronoi Cell Area %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% disp('VCAR');
% tic
[V,C] = voronoin(coords,{'QJ'}); % Returns the vertices of the Voronoi edges in VX and VY so that plot(VX,VY,'-',X,Y,'.')
% cellvert = [];
% coords_bound=zeros(size(coords));
sixsided=0;
bound = zeros(length(C),1);
cellarea = zeros(length(C),1);
numedges = zeros(length(C),1);
% figure(10); hold on;
for i=1:length(C)
   
    vertices=V(C{i},:);
    
    if (all(C{i}~=1)  && all(vertices(:,1)<bounds(4)) && all(vertices(:,2)<bounds(2)) ... % [ymin ymax xmin xmax] 
                     && all(vertices(:,1)>bounds(3)) && all(vertices(:,2)>bounds(1))) 

        cellarea(i) = polyarea(V(C{i},1),V(C{i},2));
        
        % Code to display number of sides for each voronoi domain
        numedges(i)=size(V(C{i},1),1);
        switch(numedges(i))
%             case 4
%                 color = 'm';
%             case 5
%                 color = 'c';
            case 6
%                 color = 'g';
              sixsided = sixsided+1;
%             case 7
%                 color = 'y';
%             case 8
%                 color = 'r';
%             case 9
%                 color = 'b';
        end
%         figure(10);
%         patch(V(C{i},1),V(C{i},2),ones(size(V(C{i},1))),'FaceColor',color);
%         hold on;
        
        coords_bound(i,:) = coords(i,:);
        bound(i) = 1;
    end
    

end
% hold off;
% toc
 figure(2);
   voronoi(coords(:,1),coords(:,2));
if ~isempty(coords_bound)
    coords_bound=coords_bound(coords_bound(:,1)~=0,:); % Clip out the unbounded cells
    cellarea= cellarea((cellarea~=0)).*(scale.^2); % Clip out unbounded cells, convert to square microns
    numedges = numedges(numedges~=0);
    
    mean_cellarea=mean(cellarea);
    regularity_voro_index = mean_cellarea/std(cellarea);
    regularity_voro_sides = mean(numedges)/std(numedges);
    
%     disp([ 'Mean: ' num2str(mean(numedges))  ' Std deviation: ' num2str(std(numedges)) ] );
    percent_six_sided = 100*sixsided/size(coords_bound,1);
else
    cellarea=0;
    mean_cellarea=0;
    regularity_voro_index=0;
    regularity_voro_sides=0;
    percent_six_sided=0;
end
% waitbar(0.4,wb,'Determining Density');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Number of Cells, Density Direct Count (D_dc) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numcells=length(coords); % Total number of cells
total_cell_area=sum(cellarea); % Total cell area in um
total_coord_area=((clipped_row_col(1)*clipped_row_col(2))*(scale^2)/(1000^2));

density_dc=numcells/total_coord_area; % cells/mm^2
if ~isempty(coords_bound)
    density_bound = (1000^2)*size(coords_bound,1)./total_cell_area;
else
    density_bound = 0;
end

% waitbar(0.6, wb, 'Determining DFT-derived spacing');
%% FOR FFT - Fit sigmoid to FFT output, find decending/decreasing beginning.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine FFT Power Spectra %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If sim_im isn't zero, then
% if length(sim_im)~=1
% %       [power_spect fft_spac] = determine_power_spectra(sim_im,24.04,736);
%       [power_spect fft_radius fft_spac corr] = annulus_xcorr(sim_im,scaling{2},scaling{3});
% else
%       [power_spect fft_radius fft_spac] = zeros(1,3);
% %       power_spect = 0;
% %       fft_radius = 0;
% %       fft_spac = 0;
% end


% waitbar(0.7,wb, 'Determining Inter-cell distance');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Inter-Cell Distance %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% disp('ICD');
% tic

dt = DelaunayTri(coords);
m=1;
% max_cell_dist=[];
% inter_cell_dist=[];

correct_inter_cell_dist = zeros(size(coords,1),1);
correct_max_cell_dist = zeros(size(coords,1),1);
correct_nn_cell_dist = zeros(size(coords,1),1);
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
        correct_inter_cell_dist(m) = scale*(sum(cell_dist(1,:)) / (length(cell_dist(1,:))-1));
        correct_max_cell_dist(m)   = scale*max(cell_dist(1,:));
        correct_nn_cell_dist(m)    = scale*min(cell_dist(1,2:end));
%         figure(1); triplot(dt); hold on; plot(coords(coord_row,1),coords(coord_row,2),'r.'); plot(coords(k,1),coords(k,2),'g.');  hold off;
        m = m+1;
    end
    
end
m = m-1;



if ~isempty(coords_bound)
    mean_correct_nn_dist = mean( correct_nn_cell_dist(1:m) );
    mean_correct_inter_cell_dist = mean(correct_inter_cell_dist(1:m));
   
    csvwrite([ICDdatapath '\' subID '_ICDvals.csv'], correct_inter_cell_dist);
    regularity_ic_index = mean(correct_inter_cell_dist(1:m))./std(correct_inter_cell_dist(1:m));
    mean_correct_max_cell_dist   = mean( correct_max_cell_dist(1:m) );
else
    regularity_ic_index = 0;
    mean_correct_nn_dist=0;
    mean_correct_inter_cell_dist=0;
    mean_correct_max_cell_dist=0;
end
% toc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Density Recovery Profile %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% waitbar(0.8,wb, 'Determining DRP');

[ density_per_rad um_drp_sizes drp_spac]=calculate_DRP(coords, [bounds(1:2); bounds(3:4)], scale, density_dc,reliability );

%   density_per_rad = 0;
%   um_drp_sizes = 0;
%   drp_spac=0;

% waitbar(1,wb, 'Done!');
% close(wb);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Output List Formatting %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% statout=[numcells density_dc mean_nn_dist total_coord_area*(1000^2) mean_cellarea length(cellarea) total_cell_area];

% Make the returned struct
mosaic_stats = struct('Number_Unbound_Cells', numcells,'Number_Bounded_Cells', length(cellarea), 'Total_Area', total_coord_area*(1000^2), 'Total_Voronoi_Area',total_cell_area,...                      
                      'Density_Bound',density_bound, 'NN_Distance_Corrected',mean_correct_nn_dist,'IC_Distance_Corrected',mean_correct_inter_cell_dist,'Max_Distance_Corrected',mean_correct_max_cell_dist,...
                      'Mean_Voronoi_Area', mean_cellarea,'Percent_Six_Sided_Voronoi',percent_six_sided,'DRP', drp_spac,...
                      'Voronoi_Area_RI',regularity_voro_index,'Voronoi_Sides_RI',regularity_voro_sides, 'NN_RI', regularity_nn_index, 'IC_RI', regularity_ic_index, 'IC_dist', correct_inter_cell_dist(1:m));
                  %'Density_Uncorrected', density_dc ,'NN_Distance_Uncorrected', mean_nn_dist, 'IC_Distance_Uncorrected',mean_inter_cell_dist, 'Max_Distance_Uncorrected',mean_max_cell_dist,...

end

