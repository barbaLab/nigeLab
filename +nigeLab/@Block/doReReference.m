function flag = doReReference(blockObj)
%% DOREREFERENCE  Perform common-average re-referencing (CAR)
%
%  b = nigeLab.Block();
%  doExtraction(b);
%  doReReference(b);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK FOR PROBLEMS
flag = false; % Create flag for reporting successful execution
blockObj.checkActionIsValid();
nigeLab.utils.checkForWorker('config');

if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

if isempty(blockObj.Mask) % need to set the mask before doing CAR
   warning(sprintf(['Channel Mask (blockObj.Mask) has not been set yet.\n' ...
      'Try blockObj.setChannelMask method.\n'])); %#ok<SPWRN>
   return;
end

%% GET METADATA FOR THIS REFERENCING
fType = blockObj.FileType{strcmpi(blockObj.Fields,'CAR')};
probe = unique([blockObj.Channels.probe]);
nSamples = length(blockObj.Channels(1).Filt);
nProbes = numel(probe);
refMean = zeros(nProbes,nSamples);

doSuppression = blockObj.Pars.Filt.STIM_SUPPRESS;
stimProbeChannel     = blockObj.Pars.Filt.STIM_P_CH;

if doSuppression % Note: this part is probably deprecated
   if isnan(stimProbeChannel(1))
      error('STIM Probe Number not specified (''STIM_P_CH(1)'')');
   elseif isnan(stimProbeChannel(2))
      error('STIM Channel Number not specified (''STIM_P_CH(2)'')');
   end
end

if (~isnan(stimProbeChannel(1)) && ~isnan(stimProbeChannel(2)))
   doSuppression = true;
end

%% COMPUTE THE MEAN FOR EACH PROBE
blockObj.reportProgress('Computing CAR',0,'toWindow');
for iCh = blockObj.Mask
   if ~doSuppression
      % Filter and and save amplifier_data by probe/channel
      iProbe = blockObj.Channels(iCh).probe;
      nChanPb = sum(iProbe == [blockObj.Channels.probe]);
      data = blockObj.Channels(iCh).Filt(:);
      refMean(iProbe,:)=refMean(iProbe,:) + data ./ nChanPb;
   else
      warning('STIM SUPPRESSION method not yet available.');
      return;
   end
   pct = round(100 * (iCh / numel(blockObj.Mask)));
   blockObj.reportProgress('Computing CAR',pct,'toWindow');
   PCT = round((pct/100) * 20); 
   blockObj.reportProgress('Computing CAR.',PCT,'toEvent');
end

%% SAVE EACH PROBE REFERENCE TO THE DISK
refMeanFile = cell(numel(probe),1);

for iProbe = 1:nProbes
   refName = fullfile(sprintf(...
      strrep(blockObj.Paths.CAR.file,'\','/'),...
      num2str(probe(iProbe)),'REF'));
   refMeanFile{iProbe} = nigeLab.libs.DiskData(...
      fType,refName,refMean(iProbe,:),'access','w');
end

%% SUBTRACT CORRECT PROBE REFERENCE FROM EACH CHANNEL AND SAVE TO DISK
str = nigeLab.utils.getNigeLink('nigeLab.Block','doReReference',...
   'common-average noise');
str = sprintf('Removing %s',str);
for iCh = blockObj.Mask
   % Do re-reference
   data = doCAR(blockObj.Channels(iCh),...
      refMean(blockObj.Channels(iCh).probe));
   
   % Get filename
   pNum  = num2str(blockObj.Channels(iCh).probe);
   chNum = blockObj.Channels(iCh).chStr;
   fName = sprintf(strrep(blockObj.Paths.CAR.file,'\','/'), ...
      pNum, chNum);
   
   % Save CAR data
   blockObj.Channels(iCh).CAR = nigeLab.libs.DiskData(...
      fType,fName,data,'access','w');
   blockObj.Channels(iCh).CAR = lockData(blockObj.Channels(iCh).CAR);
   blockObj.Channels(iCh).refMean = lockData(...
      refMeanFile{blockObj.Channels(iCh).probe});
   
   % Update user
   pct = 100 * (iCh / numel(blockObj.Mask));
   blockObj.reportProgress(str,pct,'toWindow');
   PCT = 20 + round((pct/100) * 80); 
   blockObj.reportProgress('Removing CAR.',PCT,'toEvent');
   blockObj.updateStatus('CAR',true,iCh);
end
blockObj.linkToData('CAR');
blockObj.save;
flag = true;

   function data = doCAR(channelData,reference)
      data = channelData.Filt(:);
      data = data - reference;
   end

end

