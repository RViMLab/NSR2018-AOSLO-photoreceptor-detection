%%This program will read in the average density csv file and determine the
%%coordinates of the first through fifth peak densities.  These coordinates
%%will be saved as a csv file.
%%Written by Melissa A. Wilk
%%Last updated April 11, 2013


%Open the average density csv file and load to workspace as a matrix
avemat = dlmread('Density_Ave.csv');

%Loop to determine the 5 maximum densities in the average matrix
numpeaks = 5;
maxes = zeros(numpeaks,1);
tempmat = avemat;
for j = 1:numpeaks
   maxes(j) = max(max(tempmat));
   tempmat = tempmat .* (tempmat<maxes(j));
end
dlmwrite('Average_Peak_Densities.csv',maxes)
tempmat = avemat;

%Loop to determine locations of 5 peaks in average density matrix
for i = 1:numpeaks;
    maxlocname = ['Max_' num2str(i) '_locations.csv'];
    [maxrows maxcols] = find(avemat == maxes(i));
    maxloc = [maxcols, maxrows];
    dlmwrite(maxlocname,maxloc)
end
    
