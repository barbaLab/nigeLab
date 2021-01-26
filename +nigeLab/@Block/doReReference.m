function flag = doReReference(blockObj)
%DOREREFERENCE  Perform common-average re-referencing (CAR)
%
%  b = nigeLab.Block();
%  doExtraction(b);
%  doReReference(b);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

% CHECK FOR PROBLEMS
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if ~isempty(blockObj(i))
         if isvalid(blockObj(i))
            flag = flag && doReReference(blockObj(i));
         end
      end
   end
   return;
else
   flag = false;
end
blockObj.checkActionIsValid();

if ~genPaths(blockObj)
   warning('Something went wrong with extraction.');
   return;
end

% GET METADATA FOR THIS REFERENCING
probe = unique([blockObj.Channels.probe]);
nSamples = length(blockObj.Channels(1).Filt);
nProbes = numel(probe);
refMean = zeros(nProbes,nSamples);

% COMPUTE THE MEAN FOR EACH PROBE
blockObj.reportProgress('Computing-CAR',0,'toWindow');
curCh = 0;
nCh = numel(blockObj.Mask);
for iCh = blockObj.Mask
   curCh = curCh + 1;
      % Filter and and save amplifier_data by probe/channel
      iProbe = probe==blockObj.Channels(iCh).probe;
      nChanPb = sum(probe(iProbe) == [blockObj.Channels.probe]);
      data = blockObj.Channels(iCh).Filt(:);
      refMean(iProbe,:)=refMean(iProbe,:) + data ./ nChanPb;

   PCT = round(20*curCh/nCh);
   blockObj.reportProgress('Computing-CAR',PCT,'toWindow');
   blockObj.reportProgress('Computing-CAR',PCT,'toEvent','Computing-CAR');
end

% SAVE EACH PROBE REFERENCE TO THE DISK
refMeanFile = cell(numel(probe),1);
for iProbe = 1:nProbes
   PCT = 20 + round(10 * iProbe/nProbes);
   blockObj.reportProgress('Computing-CAR',PCT,'toWindow');
   blockObj.reportProgress('Computing-CAR',PCT,'toEvent','Computing-CAR');
   refName = fullfile(sprintf(...
      strrep(blockObj.Paths.CAR.file,'\','/'),...
      num2str(probe(iProbe)),'REF'));
   refMeanFile{iProbe} = nigeLab.libs.DiskData(...
      'MatFile',refName,refMean(iProbe,:),'access','w','overwrite',true);
end

% SUBTRACT CORRECT PROBE REFERENCE FROM EACH CHANNEL AND SAVE TO DISK
if ~blockObj.OnRemote
   str = nigeLab.utils.getNigeLink('nigeLab.Block','doReReference','CAR');
   str = sprintf('Removing-%s',str);
else
   str = 'Removing-CAR';
end
curCh = 0;
for iCh = blockObj.Mask
    iProbe = probe==blockObj.Channels(iCh).probe;
   curCh = curCh + 1;
   % Do re-reference
   data = doCAR(blockObj.Channels(iCh),...
      refMean(iProbe,:));
   
   % Get filename
   pNum  = num2str(blockObj.Channels(iCh).probe);
   chNum = blockObj.Channels(iCh).chStr;
   fName = sprintf(strrep(blockObj.Paths.CAR.file,'\','/'), ...
      pNum, chNum);
   
   % Save CAR data
   blockObj.Channels(iCh).CAR = nigeLab.libs.DiskData(...
      'MatFile',fName,data,'access','w','overwrite',true);
   lockData(blockObj.Channels(iCh).CAR);
   blockObj.Channels(iCh).refMean = refMeanFile{iProbe};
   
   % Update user
   
   PCT = 30 + round(60 * curCh/nCh);
   blockObj.reportProgress(str,PCT,'toWindow'); 
   blockObj.reportProgress('Removing-CAR',PCT,'toEvent','Removing-CAR');
   blockObj.updateStatus('CAR',true,iCh);
end

if blockObj.OnRemote
   str = 'Saving-Block';
   blockObj.reportProgress(str,95,'toWindow',str);
else
   blockObj.save;
   linkStr = blockObj.getLink('CAR');
   str = sprintf('<strong>Re-referencing</strong> complete: %s\n',linkStr);
   blockObj.reportProgress(str,100,'toWindow','Done');
   blockObj.reportProgress('Done',100,'toEvent');
end

flag = true;

   function data = doCAR(channelData,reference)
      data = channelData.Filt(:);
      data = data - reference;
   end

end

