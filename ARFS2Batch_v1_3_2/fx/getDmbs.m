function [ dmb, terminate ] = getDmbs(path)
%getDmbs Opens a window to select the .dmb's then converts that information into a structure

terminate = false;
defPath = path;
%% USER
[dmb_names, dmb_path] = uigetfile('*.dmb','Select .dmb''s',...
    'MultiSelect','on',defPath);
if numel(dmb_names) == 1 && ~dmb_names
    dmb = [];
    terminate = true;
    return;
end
if ~iscell(dmb_names)
    dmb_names = {dmb_names};
end

%% Convert to structure
dmb(numel(dmb_names)).name = [];
for i=1:numel(dmb_names)
    dmb(i).name = dmb_names{i};
    dmb(i).path = dmb_path;    
end

end
