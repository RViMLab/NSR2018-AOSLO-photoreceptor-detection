function [images] = readAndDesinusoid(apath, fname, desinusoid_matrix, wb)
%% desinusoid_single desinusoids a single video and returns it as a cell array of images
%
% Originally written, I believe, by Rob F. Cooper
% Update by Brandon Wilk to account for the loss of some functions after an update
% Major change by Alex Salmon (2016.03.10), stripped GUI, super tailored to ARFS experiments.
% Adapted to ARFS2Batch (2016.03.24)
% Has not passed safety inspections.

%% Get desinusoid matrix dimension
% [nRow_mat, nCol_mat] = size(desinusoid_matrix);

%% Set up video reader
try
vr      = VideoReader(fullfile(apath, fname));
nFrames = round(vr.Duration*vr.FrameRate);
% nCol_img = vr.Width;
% nRow_img = vr.Height;

% Bring horizontal warping into this function (todo)
%% Check whether video and matrix sizes match 
% if ( cal_file.data.horizontal_warping && (nCol_img ~= nRow_mat)) || ...
%         (~cal_file.data.horizontal_warping && (nRow_img ~= nCol_mat))
%     images = [];
%     return; % give up like a quitter.
% end

%% Read and store frames
images = cell(nFrames,1);
waitbar(0,wb,strrep(sprintf('Reading %s...',fname),'_','\_'));
for i=1:nFrames
    % Dewarping and copying the data directly to the frame
%     if cal_file.data.horizontal_warping
    images{i} = uint8((single(readFrame(vr))) * desinusoid_matrix);
    waitbar(i/nFrames,wb);
%     else
%         images{i} = uint8(desinusoid_matrix * (single(readFrame(vr))));
%     end
end

catch MException
    fprintf('\nI''m sorry I failed you: %s\n', fname);
    fprintf(MException.message);
    fprintf('\n');
    images = MException;
end





