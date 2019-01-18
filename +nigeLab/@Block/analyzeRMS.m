function analyzeRMS(blockObj,type)
%% ANALYZERMS  Get RMS for full recording for each type of stream
%
%  ANALYZERMS(blockObj);
%  ANALZYERMS(blockObj,{'Raw','LFP'});
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% DEFAULTS
if nargin < 2
   type = {'Raw','Filt','CAR','LFP'};
end
type = type(ismember(type,blockObj.Fields(blockObj.Status)));
blockObj.RMS = [];

%% COMPUTE RMS FOR EVERY CHANNEL ON WAVEFORMS OF INTEREST
tic;
fprintf(1,'\nComputing channel-wise RMS...000%%\n');
for iCh = blockObj.Mask
   x = struct;
   for iT = 1:numel(type)
      data = blockObj.Channels(iCh).(type{iT})(:);
      x.(type{iT}) = rms(data);
   end
   blockObj.RMS = [blockObj.RMS; struct2table(x)];
   pct = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
end
toc;

end