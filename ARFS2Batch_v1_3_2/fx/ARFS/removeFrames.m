function [ data ] = removeFrames( data, bf )
%removeFrames removes the true indices in bf from data

% remove frames
data.frames(bf) = [];

% Adjust scores
scoreFields = fieldnames(data.scores);
for i=1:numel(scoreFields)
    eval(sprintf('data.scores.%s(bf) = [];',scoreFields{i}));
end

% Update motion trace
if isfield(data,'x')
    data.x(bf) = [];
    data.y(bf) = [];
end

if isfield(data,'saccades')
    data.saccades(bf) = [];
end

end









