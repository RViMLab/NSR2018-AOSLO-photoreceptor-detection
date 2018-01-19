function [ clipped_coords ] = coordclip_npoly( coords , thresholdr, thresholdc, lessorgreater )
% Robert Cooper, 05-06-11
%   This function removes all coordinates less than or greater a specific
%   treshold, in an n-defined polygon around an image. Is blind to image size, and only
%   works off of coordinates. 
%
%  @Input Args:
%   coords- This is an N row, 2 column matrix containing the row|col
%           coordinate locations
%
%   thresholdr- This is the threshold pixel row coordinates that are allowed to
%           remain in the list. 
%   
%   thresholdc- This is the threshold pixel col coordinates that are allowed to
%           remain in the list. 
%   
%   lessorgreater- This flag determined whether or not coordinates greater or less
%           than threshold are kept. 'l' includes all coordinates less than
%           the threshold, 'g' includes all coordinates greater than. 'g'
%           is the default.
%

if nargin<2 || nargin<1
    error('Requires Nx2 coordinate list and threshold value!');
elseif nargin<4
    lessorgreater='g';
end

% Determine max image size- assumes there are border coordinates (common in
% Kaccie Li's code).
imsizerow=max(coords(:,1));
imsizecol=max(coords(:,2));

% Making treshold variables
minrowthresh=thresholdr(1);
maxrowthresh=thresholdr(2);
mincolthresh=thresholdc(1);
maxcolthresh=thresholdc(2);


if strcmp(lessorgreater,'g')

    % Check rows coordinates for includable entries
    clipped_row=coords( (coords(:,1)>minrowthresh) & (coords(:,1)<maxrowthresh),:);
    % Using already clipped group, checks col coordinates for includable entries
    clipped_coords=clipped_row( (clipped_row(:,2)>mincolthresh) & (clipped_row(:,2)<maxcolthresh),:);
    
elseif strcmp(lessorgreater,'l')
    
    % Check rows coordinates for includable entries
    clipped_row=coords( (coords(:,1)<minrowthresh) & (coords(:,1)>maxrowthresh),:);
    % Using already clipped group, checks col coordinates for includable entries
    clipped_coords=clipped_row( (clipped_row(:,2)<mincolthresh) & (clipped_row(:,2)>maxcolthresh),:);
    
end



end

