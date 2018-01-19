
% Robert Cooper 4-11-2012
% Requires: Image Processing and Statistics toolboxes.
%
% This script is the starter script for the cone counting program
% distribution edition. EVERYTHING HERE IS PROVIDED AS IS. I make no claims
% of any warranty or any other guarantee on the maintenance of this
% software.
%
% This script will run a cone coordinate selection procedure on all of the images in the 'etc' folder in
% this program's subdirectory. Note that you MUST update the LUT.csv in the format: ID,axial,pix/degree, or it 
% will SKIP the images that it can't find an ID lookup for!
%
% By default it attempts to analyze a 55, 40 and 25 micron box. Therefore, the input boxes must be at
% LEAST 60 microns for proper operation. The results of running the program
% with any sizes smaller than that are undefined!
% To change the micron size that is analyzed, simply change the sizes array below.

close all;
clear all;
clc;

warning off

%---------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------
%% Perform the analysis for each of the below sizes (in microns) on each respective trial
sizes = [ 55, 40, 25 ];
%---------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------



progBar = waitbar(0,'Beginning cone counting...');

% Check version number
ver = version('-release');
if str2double(ver(1:4)) < 2011 % If less than 2011, must use RandStream generator
    newstream= RandStream('mt19937ar','Seed',sum(100*clock));
    RandStream.setGlobalStream(newstream);
else % 2011-12 has a rng function that allows easy resetting of the random num generator
    rng('shuffle');
end
% Find what path this script is running from
thisPath=which('cone_counting.m');

% Get the absolute path
basePath=thisPath(1:end-15);

% Add the bin directory to run the remainder of the files
path(path,fullfile(basePath,'bin'))

%%  Formerly ConeCountingv13_auto_random_batch
pname = fullfile(basePath,'etc');

filelist=read_folder_contents(pname,'tif');
[sfl,~] = size(filelist);
alex = randperm(sfl);

outpath = fullfile(basePath,'coordinate_analysis');

if ~exist(outpath,'dir')
    mkdir(outpath);
end    

% Hard coded for distribution
fLUT = 'LUT.csv';
pLUT = pname;

fid=fopen(fullfile(pLUT,fLUT),'r');
lutData=textscan(fid,'%s%f%f','Delimiter','",','MultipleDelimsAsOne',1);
fclose(fid);

analyzepath = fullfile(basePath,'coordinate_analysis');



for i = 1:sfl;
    
    waitbar((i/sfl),progBar,['Counting image ' num2str(i) ' of ' num2str(sfl)]);
    
%     disp(i); % Display which image we're on

    imsize = conecountingfunc( filelist{alex(i)}, pname, outpath, lutData );

    %% Formerly	coord_stats_calculator
    for j=1: length(sizes)

        micronsize = sizes(j);
        coord_stats(analyzepath, [filelist{alex(i)}(1:end-4) '_coords.txt'],lutData,micronsize,imsize, fullfile(pname,filelist{alex(i)}) );

        waitbar((i/sfl) , progBar, ['Analyzing ' filelist{alex(i)} '...']);
    end

end
    waitbar(1,progBar,'Done!');
    pause(1);
    delete(progBar)



warning on;




