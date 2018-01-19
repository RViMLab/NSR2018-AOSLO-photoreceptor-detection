function [ dist_list ] = dist_to_edge( coords, edge, bounds)
% Robert Cooper 06-29-2012
%   This function finds the distance to the edge specified by the user. By
%   default, it finds the distance to the edge closest to the coordinates.
% Input Args:
%   @coords: This should be an Nx2 column of data, with column 1 being X
%   coordinates and column 2 being Y coordinates.
%
%   @edge: This should be one of two strings: 'closest' or 'farthest' to
%   designate which edge the script should look for.
%
%   @bounds: This should be a two element array containing the maximum
%   X and Y size possible (can be bigger than the maximum coordinates)


if strcmp(edge,'closest')
    
    % X coordinates
    closestX = min( abs(bounds(1,2)-coords(:,1)), abs(bounds(1,1)-coords(:,1)) );
    % Y coordinates
    closestY = min( abs(bounds(2,2)-coords(:,2)), abs(bounds(2,1)-coords(:,2)) );
    
    dist_list = min(closestX,closestY);
    
elseif strcmp(edge,'furthest')
    
    dist_list=[];
    
else
   
    
    
end


end

