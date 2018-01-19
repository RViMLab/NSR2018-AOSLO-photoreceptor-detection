%%multipleWindows will loop through Rob's local_meas program inserting
%%various micron_box_size (diffferent box widths for sampling window size)
%%Written by Melissa A. Wilk
%%Last modified March 14, 2013

%Clear workspace
clear all
close all

%Set box width/height values-->these need to be manually entered and
%changed if desired
boxes = [25 27 29 31 33 35 37 39 42 45];

%Loop through all box width values, running local_meas to determine
%density, mic, and nn values
for j = 1:length(boxes) 
   micron_box_size = boxes(j);
   max_window = max(boxes);
   [max_density numdens min_mic nummic min_nn numnn densitymap micmap nnmap]=local_meas_mel_vers(micron_box_size, max_window);
   allWindows(j,:) = [micron_box_size max_density numdens min_mic nummic min_nn numnn];
   %Write matrix to csv file
   densFile = ['Density_' num2str(micron_box_size) '.csv'];
   micFile = ['MIC_' num2str(micron_box_size) '.csv'];
   nnFile = ['NN_' num2str(micron_box_size) '.csv'];
   densitymap = densitymap';
   dlmwrite(densFile, densitymap)  
   dlmwrite(micFile, micmap)
   dlmwrite(nnFile, nnmap) 
   
   %Create grayscale image for the densities in each matrix
   imName = ['Density_' num2str(micron_box_size) '.tif'];
   matim = uint8(round(255*(densitymap-min(min(densitymap)))/(max(max(densitymap))-min(min(densitymap)))));
   imwrite(matim, imName, 'tif')
   
   %Create stacked 3D matrix with the matrix for each box size 
   matstack(:,:,j) = densitymap;
end

%Write peak info to csv file
dlmwrite('Peak_Info.csv', allWindows)

%%Get average and standard deviation for each location in the 3D matrix and create grayscale image
%Average matrix
avemat = mean(matstack,3);
avematName = 'Density_Ave.csv';
dlmwrite(avematName, avemat)
%Std Dev matrix
sdmat = std(matstack,0,3);      %Get SD of matrices
sdmatName = 'Density_StdDev.csv';    %Name of matrix output csv file
dlmwrite(sdmatName, sdmat)
%Average image
aveimName = 'Density_Ave.tif';
aveim = uint8(round(255*(avemat-min(min(avemat)))/(max(max(avemat))-min(min(avemat)))));
imwrite(aveim, aveimName, 'tif')
%Std Dev image
sdimName = 'Density_StdDev.tif';   %Name of image
sdim = uint8(round(255*(sdmat-min(min(sdmat)))/(max(max(sdmat))-min(min(sdmat)))));
imwrite(sdim, sdimName, 'tif')


