function [  ] = determine_coord_stats( fname,statoutfname, coords, um_per_pix, clip_start_end ,clipped_row_col )
% Robert Cooper 01-25-12
% This function takes in a list of coordinates in a m-2 matrix, and
% calculates the mean nearest neighbor, cell area created by the
% coordinates, and calculates the density of the coordinates as well as
% their density for a given micron per pixel (@arg um_per_pix)


%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Mean N-N %%
%%%%%%%%%%%%%%%%%%%%%%%%

dist_between_pts=squareform(pdist(coords)); % Measure the distance from each set of points to the other
max_ident=eye(length(dist_between_pts)).*max(dist_between_pts(:)); % Make diagonal not the minimum for any observation

[minval minind]=min(dist_between_pts+max_ident); % Find the minimum distance from one set of obs to another

mean_nn_dist=mean(minval.*um_per_pix); % Distance in microns

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Voronoi Cell Area %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[V,C] = voronoin(coords); % Returns the vertices of the Voronoi edges in VX and VY so that plot(VX,VY,'-',X,Y,'.')

for i=1:length(C)
   
    vertices=V(C{i},:);
    
    if (all(C{i}~=1) && all(vertices(:,1)<clip_start_end(2,2)) && all(vertices(:,2)<clip_start_end(1,2)) ...
                     && all(vertices(:,1)>clip_start_end(2,1)) && all(vertices(:,2)>clip_start_end(1,1)))  
        cellvert=V(C{i},:); 
        cellarea(i)=polyarea(V(C{i},1),V(C{i},2));
        
%         figure(1);
%         patch(V(C{i},1),V(C{i},2),i);

    end
end
% figure(2);
% voronoi(coords(:,1),coords(:,2));
if exist('cellarea','var')
    cellarea= cellarea((cellarea~=0)).*(um_per_pix.^2); % Clip out unbounded cells, convert to square microns
    mean_cellarea=mean(cellarea);
else
    cellarea=0; 
    mean_cellarea=0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine Number of Cells, Density %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numcells=length(coords); % Total number of cells
total_cell_area=sum(cellarea); % Total cell area in um
total_coord_area=((clipped_row_col(1)*clipped_row_col(2))*(um_per_pix^2)/(1000^2));

density=numcells/total_coord_area; % cells/mm^2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Output List Formatting %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
statout=[numcells density mean_nn_dist total_coord_area*(1000^2) mean_cellarea length(cellarea) total_cell_area];

if exist(statoutfname,'file')
    
%     disp(statoutfname);
    fid=fopen(statoutfname,'a');
    fprintf(fid,['"' fname '",']);% 1st/2nd column- filename/Detection Type
    fclose(fid);
    dlmwrite(statoutfname,statout,'-append'); % 2-6 columns- data


else
    fid=fopen(statoutfname,'w');
    % Create header
    fprintf(fid,['"Filename","Number of Cells","Cell Density (cells/mm^2)","Mean N-N (um)",'...
                 '"Cropped Coordinate Area (um^2)","Mean Voronoi Cell Area (um^2)",'...
                 '"Number of Bounded Cells","Total Voronoi Area (um^2)",\n']);
    fprintf(fid,['"' fname '",']); % 1st/2nd column- filename/Detection Type
    fclose(fid);
    dlmwrite(statoutfname,statout,'-append'); % 2-6 columns- data

end


end

