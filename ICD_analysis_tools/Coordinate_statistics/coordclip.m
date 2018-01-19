function [ clipped_coords ] = coordclip( coords , thresholdx, thresholdy, inoutorxor )
% Robert Cooper, 05-06-11
%   This function removes all coordinates less than or greater a specific
%   treshold, in an n-defined polygon around an image. Is blind to image size, and only
%   works off of coordinates. 
%
%  @Input Args:
%   coords- This is an N row, 2 column matrix containing the x|y
%           coordinate locations
%
%   thresholdr- This is the threshold pixel row coordinates that are allowed to
%           remain in the list. 
%   
%   thresholdc- This is the threshold pixel col coordinates that are allowed to
%           remain in the list. 
%   
%   inoutorxor- This flag determined whether or not coordinates greater or less
%           than threshold are kept. 'o' includes all coordinates outside
%           the threshold, 'i' includes all coordinates inside. 'o'
%           is the default.
%

if nargin<2 || nargin<1
    error('Requires Nx2 coordinate list and threshold value!');
elseif nargin<4
    inoutorxor='i';
end

% Making treshold variables
minYthresh=thresholdy(1);
maxYthresh=thresholdy(2);
minXthresh=thresholdx(1);
maxXthresh=thresholdx(2);


if strcmp(inoutorxor,'i')

    % Ensures that all coordinates are inside the box. - In accordance with
    % notebook decision
    clipped_coords=coords( (coords(:,1)>minXthresh) & (coords(:,1)<maxXthresh) &...
                        (coords(:,2)>minYthresh) & (coords(:,2)<maxYthresh),:);

    
elseif strcmp(inoutorxor,'o')
    
    clipped_coords=coords( (coords(:,1)<minXthresh) | (coords(:,1)>maxXthresh) ...
                        | (coords(:,2)<minYthresh) | (coords(:,2)>maxYthresh),:);

elseif strcmp(inoutorxor,'xor')

    % Check rows coordinates for includable entries - In accordance with
    % notebook decision
    clipped_coords = coords( xor( (coords(:,1)<=minXthresh) | (coords(:,1)>=maxXthresh) , ...
                               (coords(:,2)<=minYthresh) | (coords(:,2)>=maxYthresh) ) ,:);

    
elseif strcmp(inoutorxor,'and')
    
    % Check rows coordinates for includable entries - In accordance with
    % notebook decision
    clipped_coords = coords( ((coords(:,1)<=minXthresh) | (coords(:,1)>=maxXthresh)) & ...
                             ((coords(:,2)<=minYthresh) | (coords(:,2)>=maxYthresh)) ,:);
    
end



end

