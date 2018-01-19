function recordErr( err, fid )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

fprintf(fid, '\n%s\n', err.message);
for k=1:numel(err.stack)
    fprintf(fid, 'file: %s\n',err.stack(k).file);
    fprintf(fid, 'name: %s\n',err.stack(k).name);
    fprintf(fid, 'line: %i\n',err.stack(k).line);
end

end

