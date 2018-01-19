function [ imsize ] = conecountingfunc( fname, pname,outpath, lutData )
% This is a hodge-podge function that is the work of more than 5-6
% different programmers adding to/removing from it over the years. If you are reading
% this, I suggest stopping now before your eyes begin to bleed. As if it
% needed to be said, this function needs to be rewritten.
% -- RFC

% NOTE: This section only really works on post- Neitz subjects...
[idpiece1, remain]=strtok(fname,'_'); %Take Referrer
[idpiece2, ~]=strtok(remain,'_'); %Take ID #
subID=[idpiece1 '_' idpiece2]; 
clear idpiece1 idpiece2;


LUTindex=find(strcmp(lutData{1},subID));

axiallength = lutData{2}(LUTindex);
pixelsperdegree = lutData{3}(LUTindex);


%Read in image
imageA = imread(fullfile(pname, fname));

%  Converting color 2 grayscale if color image: modification - ht
if(ndims(imageA) > 2) %#ok<ISMAT>
    imageA = rgb2gray(imageA);
end

% Image size in pixels
[imsizey, imsizex] = size(imageA);

micronsperdegree = (291*axiallength)/24;
micronsperpixel = 1 / (pixelsperdegree / micronsperdegree);
areamm = ((imsizex*imsizey*micronsperpixel*micronsperpixel)./(1000.^2));

%--------------------------------------------------------------------------------------------------
% First pass to find cones and set filter
CutOffinit = 0.6;

Thrshld = 0;  % modification : HT
tic
%verify input validity
ImgDim = size(imageA);
if length(ImgDim) == 3;
    warning('This image is color and will be converted to grayscale')
    imageA = imageA(:,:,1);
end

%Begin algorithm
imageA = double(imageA);
fc = imcomplement(imageA);
[M, N] = size(fc);


%FIR filter design
[f1, f2] = freqspace(15, 'meshgrid');
H = ones(15);
fr = sqrt(f1.^2 + f2.^2);
H(fr > CutOffinit) = 0;

window = fspecial('disk', 7);
% window = padarray(window./max(window(:)), [1+(496/2) 1+(496/2)] );
% window = fspecial('disk', 7);
window = window./max(window(:));
h = fwind2(H, window);
fc = imfilter(fc, h, 'replicate', 'same');
% fc = imfilter(fc, h, 0, 'same');

%Morphological markers generation
LocalMins = imregionalmin(fc, 4);
se = strel('disk', 1, 0);

ConeMark = imdilate(LocalMins, se);

[L, numMark] = bwlabel(ConeMark);
stats = regionprops(L, 'centroid');
X = zeros(numMark, 1);
Y = X;
g = zeros(M, N);

for ii = 1:numMark
    loc = stats(ii).Centroid; %(x, y)
    loc = round(loc); %integral output
    if imageA(loc(2), loc(1)) > Thrshld
        g(loc(2), loc(1)) = 1;
    end
end

g = im2bw(g);
[Y, X] = find(g == 1);

S = [X Y];

toc

% Quicker way to find N-N distance... RFC 06-20-2012
dist_between_pts=squareform(pdist(S)); % Measure the distance from each set of points to the other
max_ident=eye(length(dist_between_pts)).*max(dist_between_pts(:)); % Make diagonal not the minimum for any observation

[minval]=min(dist_between_pts+max_ident,[],2); % Find the minimum distance from one set of obs to another

nmmicronpix  = mean(minval); % Removed the code

conefreqpix = (1./nmmicronpix);
normpowerpix =.5;
CutOffnew = (conefreqpix.*1.2)/normpowerpix;

%Begin algorithm - second time through
ffc = imcomplement(imageA);
[MM, NN] = size(fc);

%FIR filter design - don't need to repeat setup steps as they are the exact
%same. Should save some exec time.
HH = ones(512, 512);
HH(fr > CutOffnew) = 0;
hh = fwind2(HH, window);
ffc = imfilter(ffc, hh, 'replicate', 'same');

%Morphological markers generation
LocalMinsfin = imregionalmin(ffc, 4);
ConeMarkfin = imdilate(LocalMinsfin, se);

[LL, numMarkfin] = bwlabel(ConeMarkfin);
statsfin = regionprops(LL, 'centroid');
XX = zeros(numMarkfin, 1);
YY = XX;
gg = zeros(MM, NN);

for jj = 1:numMarkfin
    loc = statsfin(jj).Centroid; %(x, y)
    loc = round(loc); %integral output
    if imageA(loc(2), loc(1)) > Thrshld
        gg(loc(2), loc(1)) = 1;
    end
end

gg = im2bw(gg);
[YY, XX] = find(gg == 1);

SS = [XX YY];

% Quicker way to find N-N distance... RFC 06-20-2012
dist_between_pts=squareform(pdist(SS)); % Measure the distance from each set of points to the other
max_ident=eye(length(dist_between_pts)).*max(dist_between_pts(:)); % Make diagonal not the minimum for any observation

[minval, minind]=min(dist_between_pts+max_ident,[],2); % Find the minimum distance from one set of obs to another

nnmicronfinal = mean(minval.*micronsperpixel);


% Clip edge cones to reduce artifacting
clipped_coords=coordclip_npoly([YY XX],[2 max(YY)-1],[2 max(XX)-1]);

% Calc this after clipping, or you will have huge gaps between manual and
% auto.
numConesAuto = length(clipped_coords);
ConeDensityAuto = numConesAuto/areamm; 

% Return list of coordinates from add/remove program
manual_mod_cones=cone_add_remove(uint8(imageA),clipped_coords*[0 1;1 0],'var');


if (length(manual_mod_cones)==1) && manual_mod_cones==0
    close all;
    error('***** User exited program! *****');
    
end
imsize = size(imageA);
% Clip again so that there isnt any edge-added cones, even if the
% user added them...
manual_mod_cones=coordclip_npoly(manual_mod_cones,[2 max(XX)-1],[2 max(YY)-1]);

coneX = manual_mod_cones(:,1); 
coneY = manual_mod_cones(:,2);
numConesMan = length(manual_mod_cones); 


ConeDensityMan = numConesMan/areamm; %corrected to include manually selected cones (7/22, mws)
fprintf('The total number of cones found (manual and auto) is %4.0f cells. \n',numConesMan);
fprintf('The cone density with manually added cones is %9.2f cells/mm^2 . \n',ConeDensityMan);
fprintf(' \n');
fprintf('The total number of cones found (automated) is %4.0f cells. \n',numConesAuto);
fprintf('The automated cone density is %9.2f cones/mm^2 .\n',ConeDensityAuto);
fprintf(' \n');
change=numConesMan-numConesAuto;
% If positive, that means that globally, the user added cells
if change>=0
    fprintf('The user manually added %3.0f cells. \n',change);
    changetest='added';
elseif change<0
    fprintf('The user manually removed %3.0f cells. \n',abs(change));
    changetest='removed';
end




%RFC 2011- Outputs displayed data to file
statout=[axiallength pixelsperdegree numConesMan ConeDensityAuto numConesAuto ConeDensityMan change];
statoutfname=fullfile(outpath,[getparent(pname,'short') '_density_info.csv']);

if exist(statoutfname,'file')

    fid=fopen(statoutfname,'a');
    fprintf(fid,['"' fname '","Auto + Manual",']);% 1st/2nd column- filename/Detection Type
    fclose(fid);
    dlmwrite(statoutfname,statout,'-append'); % 2-6 columns- data



else
    fid=fopen(statoutfname,'w');
    % Create header
    fprintf(fid,['"Filename","Detection Type","Axial Length","Pixels per Degree","Total Number of Cones","Auto Only Cone Density",'...
                '"Number of Auto Cones","Auto+Manual Cone Density","Number of Manually ' changetest ' Cones",\n']);
    fprintf(fid,['"' fname '","Auto + Manual",']); % 1st/2nd column- filename/Detection Type

    dlmwrite(statoutfname,statout,'-append'); % 2-6 columns- data


    fclose(fid);
end


dataforfile = [coneX coneY];


dlmwrite(fullfile(outpath, [fname(1:end-4) '_coords.txt']),dataforfile,'delimiter','\t');


end

