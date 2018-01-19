function [ ancc, bf ] = getANCC( fails, ancc, nccs )
%getANCC corrects the average normalized cross correlation coefficients when a 2nd and 3rd pass of motion tracking is
%not desired.

% [fails, ancc, nccs]

nrf = numel(fails);
for i=2:nrf
    if fails(i)
        ancc(i) = nccs(i-1);
    end
    if ~fails(i) && fails(i-1)
        ancc(i) = nccs(i);
    end
end

bf = ancc == 0;

end

