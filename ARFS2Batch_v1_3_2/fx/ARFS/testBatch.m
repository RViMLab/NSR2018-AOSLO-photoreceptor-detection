function [  ] = testBatch(ffName)
% testBatch

fParts = strsplit(ffName,filesep);
% path   = strjoin(fParts(1:end-1),filesep);
fName  = fParts{end};

dlgTitle = ['Test parameters for ',fName];
prompt = {
    '# of NCC rows to ignore:';
    '# of NCC columns to ignore:';
    'Lines per strip:';
    'Lines between strips start:';
    'Min overlap for cropping:';
    '# of frames to register:';
    'Max strip displacement:';
    'Strip NCC threshold (0,1):';
    'DCT terms retained (%):';
    };
defaults = {
    '10';
    '150';
    '20';
    '20';
    '5';
    '50';
    '200';
    '0.85';
    '50.0'
    };
numLines = 1;
options.Resize = 'on';

inputInvalid = true;
while inputInvalid
    response = inputdlg(prompt,dlgTitle,numLines,defaults,options);
    defaults = response;
    
end


end

