function [ distn ] = prepScore( distn, dirinv )
%prepScore normalizes distn
%   Shifts the min of distn to zero, then normalizes to the max of distn
%   Inverts if higher values are detrimental

%% Shift and normalize to 1, invert if necessary
distn = (distn - min(distn));
distn = distn/max(distn);
if strcmpi(dirinv,'INV')
    distn = 1-distn;
end

end

% skewThr = 0.2;
% kurtThr = 1;
% %% Check for abnormality
% normdistn = (distn-mean(distn))./std(distn);
% if kstest(normdistn,'alpha',0.05)
%     %% Check skewness
%     skew = skewness(normdistn);
%     if skew > skewThr                   % right-skewed
%         distn = log10(distn+any(distn==0));
%     elseif skew < skewThr               % left-skewed
%         distn = distn.^2;
%     end
%     %% Check kurtosis
%     e = 2.718;
%     normdistn = (distn-mean(distn))./std(distn);
%     k = kurtosis(normdistn);
%     if k > kurtThr || k < -kurtThr
%         resp = distn-median(distn);
%         sign = resp > 0;
%         s = zeros(size(distn)); s(sign) = 1; s(~sign) = -1;
%         if k > kurtThr                  % leptokurtic
%             f = 1/sqrt(k/e);
%         elseif k < -kurtThr             % platykurtic
%             f = (k/e)^2;
%         end
%         distn = s.*abs(resp.^f);
%         figure, hist(distn)
%     end
% end