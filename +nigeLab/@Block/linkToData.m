function flag = linkToData(blockObj,preExtractedFlag)
%% LINKTODATA  Connect the data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = linkToData(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% DEFAULTS
flag = false;

% If not otherwise specified, assume extraction has not been done.
if nargin < 2
   preExtractedFlag = false;
end
% Warning list
warningString = {'RAW'; ...
   'STIMULATION'; ...
   'DC-AMP'; ...
   'LFP'; ...
   'FILTERED'; ...
   'CAR'; ...
   'SPIKES'; ...
   'CLUSTERS';...
   'SORTED';...
   'ADC'; ...
   'DAC'; ...
   'DIG-IN'; ...
   'DIG-OUT'; ...
   'EXPERIMENT-NOTES'; ...
   'PROBES'};

warningRef     = false(1,numel(warningString));

%% GET CHANNEL INFO
parseChannelID(blockObj);
if isempty(blockObj.Mask)
   blockObj.Mask = 1:blockObj.NumChannels;
else
   blockObj.Mask = reshape(blockObj.Mask,1,numel(blockObj.Mask));
end

%% LINK EACH DATA TYPE
warningRef(1)        = blockObj.linkRaw;
warningRef([2,3])    = blockObj.linkStim;
warningRef(4)        = blockObj.linkLFP;
warningRef(5)        = blockObj.linkFilt;
warningRef(6)        = blockObj.linkCAR;
warningRef(7)        = blockObj.linkSpikes;
warningRef(8)        = blockObj.linkClusters;
warningRef(9)        = blockObj.linkSorted;  
warningRef(10)       = blockObj.linkADC;
warningRef(11)       = blockObj.linkDAC;
warningRef([12,13])  = blockObj.linkDigIO;
warningRef(14)       = blockObj.linkMeta;
warningRef(15)       = blockObj.linkProbe;

%% GIVE USER WARNINGS
if any(warningRef) && ~preExtractedFlag
   warningIdx = find(warningRef);
   warning(sprintf(['Double-check that data files are present. \n' ...
      'Consider re-running doExtraction.\n'])); %#ok<SPWRN>
   for ii = 1:numel(warningIdx)
      fprintf(1,'\t-> Could not find all %s data files.\n',...
         warningString{warningIdx(ii)});
   end
   
end

blockObj.save;
flag = true;
end

