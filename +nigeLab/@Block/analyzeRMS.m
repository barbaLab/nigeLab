function rms_out = analyzeRMS(blockObj,type,sampleIndices)
%% ANALYZERMS  Get RMS for full recording for each type of stream
%
%  ANALYZERMS(blockObj);
%  ANALZYERMS(blockObj,{'Raw','LFP'});
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% DEFAULTS
if nargin < 2
   type = {'Raw','Filt','CAR','LFP'};
   type = type(blockObj.getStatus(type));
end

if nargin < 3
   sampleIndices = 1:blockObj.Samples;
end

blockObj.RMS = [];

%% COMPUTE RMS FOR EVERY CHANNEL ON WAVEFORMS OF INTEREST
tic;
fprintf(1,'\nComputing channel-wise RMS...000%%\n');
rms_out = struct('Raw',cell(blockObj.NumChannels,1),...
      'Filt',cell(blockObj.NumChannels,1),...
      'CAR',cell(blockObj.NumChannels,1),...
      'LFP',cell(blockObj.NumChannels,1));
for iCh = blockObj.Mask
   x = struct;
   for iT = 1:numel(type)
      data = blockObj.Channels(iCh).(type{iT})(:);
      x.(type{iT}) = rms(data);
      rms_out(iCh).(type{iT}) = rms(data(sampleIndices));
   end
   if isempty(blockObj.RMS)
       blockObj.RMS = [struct2table(x)];
   else
       blockObj.RMS = [blockObj.RMS; struct2table(x)];
   end
   pct = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
end
toc;

end