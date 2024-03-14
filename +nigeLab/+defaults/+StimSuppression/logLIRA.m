function varargout = logLIRA(varargin)
%% defaults.StimSuppression    Initialize parameters for logLIRA stimualtion suppression
%
%   pars = nigeLab.defaults.StimSuppression.logLIRA('NAME',value,...);
%
%
% 2024 (Francesco Negri, Tommaso Lambresa)



pars.blankingPeriod=1e-3;                             %optional

pars.saturationVoltage=0.95;                          %optional
                                                      %It specifies the recording system operating range
                                                      %in mV as specified in the datasheet. This is useful
                                                      %to properly detect saturation. By default it si the 95% of the absolute
                                                      %value of the input signal default it si the 95% of the absolute value of the input signal

pars.minClippedNSamples=[];                           %optional
                                                      %It is the minimum number of consecutive clipped samples
                                                      %to mark the artifact as a clipped one. It should be a
                                                      %1x1 positive integer. By default, it is 2.

pars.randomSeed=randi(1e5);                           %optional 
                                                      %It is the random seed provided to Matlab's Random
                                                      %Number Generator to ensure reproducibility. It must
                                                      %be a positive integer.




%% Parse output
if nargin < 1
    varargout = {pars};
else
    varargout = cell(1,nargin);
    f = fieldnames(pars);
    for i = 1:nargin
        idx = ismember(lower(f),lower(varargin{i}));
        if sum(idx) == 1
            varargout{i} = pars.(f{idx});
        end
    end
end