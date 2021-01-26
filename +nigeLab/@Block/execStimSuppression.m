%%
function sig = execStimSuppression(blockObj,nChan)
%% SUPPRESSSTIM loads raw signal and returns a stimulation-pulse free signal
%
%  sig = suppressStim(blockObj,nChan) returns raw signal from channel nChan
%  cleaned from the stimulation pulses. It identifies the stimulation
%  pulses using the Stim event field if present. If not present, it fails
%  returning an error. Pulses are corrected depending on the specified
%  method.
%
%  --------
%   INPUTS
%  --------
%
%  nChan channel index.
%
%  --------
%   OUTPUTS
%  --------
% sig (float), cleaned raw signal
%
%
% regressionMethod = 'poly3';
% regressionPars = {'Robust','LAR'};


% check for stimTS to exist. If not provided load from disk. If not present
% in the nigelObj throw an error

if isfield(blockObj.Events,'Stim')
    StimTS = blockObj.Events.Stim.data.ts;
    % often times a lien of zeros is created at the beginning of the
    % file for allocation purposes. This takes care of it.
    StimTS(StimTS==0) = [];
else
    error('nigelab:removeStim','Stim field not present in Events!\n Please provide stimTS explicitely.');
end

SUPPRpars = blockObj.Pars.StimSuppression;
SUPPRpars.fs = blockObj.SampleRate;
fs = blockObj.SampleRate;

% convert 'all' to numeric index
if strcmp(SUPPRpars.StimIdx,'all')
    SUPPRpars.StimIdx = 1:numel(StimTS);
end

% check that a length for teh stimulation pulse is  provided
if ~ismember('stimL',fieldnames(SUPPRpars)) || isempty(SUPPRpars.stimL)
    stimLength = blockObj.Events.Stim.data.snippet;
    stimLength = stimLength(:,2);
    stimLength(stimLength==0) = [];
elseif isscalar(SUPPRpars.stimL)
    stimLength = ones(size(StimTS))*SUPPRpars.stimL;
elseif size(SUPPRpars.stimL,1) ~= size(StimTS,1)
    error('nigelab:removeStim','Number of stimulation pulses(stimTS) and stimulation durations(stimL) does not correspond!');
end

% load signal
sig = blockObj.Channels(nChan).Raw(:);


[StimI,I] = unique(floor(StimTS*fs));
stimLength = ceil(stimLength(I)*fs);
stimSamples = arrayfun(@(i) StimI(i):StimI(i)+stimLength(i),1:numel(StimI),'UniformOutput',false);
SUPPRpars.StimLength = stimLength;
SUPPRpars.StimSamples = stimSamples;
SUPPRpars.StimI = StimI;


SUPPRfun = ['SUPPR_' SUPPRpars.Method];
SUPPRargsout = cell(1,nargout(SUPPRfun));
[SUPPRargsout{:}] = feval(SUPPRfun,sig,SUPPRpars);
sig = SUPPRargsout{1};
end


