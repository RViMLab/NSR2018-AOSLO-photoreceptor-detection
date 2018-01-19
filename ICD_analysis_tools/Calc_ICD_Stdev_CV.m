%This script will pull a set of csv files containing the ICD number for
%each bounded cell in a set. Files should be named in the format:
%IC_distance_subj_ID_... where subj_ID is of the form referral code_number
%(ex: JC_10321) and calculate the mean, standard deviation and coefficient
%of variation, saved in a structure with as the fields avgval, stdev, CV
%respectively. Save this structure and also save the outputs to an excel
%file

%Select the folder with ICD files, extract their names, count how many of
%them
icddir = uigetdir(pwd,'Select the folder with the ICD files');
icdFiles = dir([icddir '\*.csv']);

numsubs = length(icdFiles);

icdstruct = struct('Subnum','','Avgval',[],'Stdev',[],'CV',[]);

resultsfilefullpath = [icddir '\ICDsubresults.xls'];
%Loop through each file, gextract ICD information, calc mean and stdev
for i = 1:numsubs
    %extract subject ID
  %  [tok, remain] = strtok(icdFiles(i).name,'_');
  %  [tok, remain] = strtok(remain,'_');
    [referer, remain] = strtok(icdFiles(i).name,'_');
    [subnum, remain] = strtok(remain,'_');
    subid = [referer '_' subnum];
    %load sub ICD, calc mean, stdev, CV
    icdvals = load([icddir '\' icdFiles(i).name]);
    icdvals(icdvals<=0) = [];
    avgval = mean(icdvals);
    stdev = std(icdvals);
    cv = stdev/avgval;
    
    %save as a struct
    icdstruct(i).subnum = subid;
    icdstruct(i).Avgval = avgval;
    icdstruct(i).Stdev = stdev;
    icdstruct(i).CV = cv;
    
    %Write these values to an xls file
    xlrange = ['A' num2str(i) ':D' num2str(i)];
    xlswrite(resultsfilefullpath, {subid, avgval, stdev, cv},xlrange); 
end

save([icddir '\icdstruct.mat'], 'icdstruct');
    