function flag = doLFPExtraction(blockObj)
%DOLFPEXTRACTION   Decimates files to retrieve LFPs.
%
%  b = nigeLab.Block();
%  flag = b.doLFPExtraction();
%
% Sampling frequency chosen for the downsampled files is 1000Hz
% Band of interest in LFPs is up to 250Hz.
%
%  See Also:
%  NIGELAB.DEFAULTS.LFP

% INITIALIZE PARAMETERS
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if ~isempty(blockObj(i))
         if isvalid(blockObj(i))
            flag = flag && doLFPExtraction(blockObj(i));
         end
      end
   end
   return;
else
   flag = false;
end
blockObj.checkActionIsValid(); % Now contains `checkForWorker`

if ~genPaths(blockObj)
   warning(['nigeLab:' mfilename ':DOLFPEXTRACTION'],...
      'Something went wrong with generating output file save paths.');
   return;
end

[~,pars] = blockObj.updateParams('LFP');

DecimateCascadeM = pars.DecimateCascadeM;
DecimateCascadeN = pars.DecimateCascadeN;
DecimationFactor =  pars.DecimationFactor;
blockObj.Pars.LFP.DownSampledRate = blockObj.SampleRate / DecimationFactor;

% DECIMATE DATA AND SAVE IT
if ~blockObj.OnRemote
   str = nigeLab.utils.getNigeLink('nigeLab.Block','doLFPExtraction',...
         'Decimating');
   str = sprintf('%s raw data',str);
else
   str = 'Decimating';
end
fType = blockObj.FileType{strcmpi(blockObj.Fields,'LFP')};
curCh = 0;
nCh = numel(blockObj.Mask);

probes = unique([blockObj.Channels.probe]);
nChanProbe = sum([blockObj.Channels(blockObj.Mask).probe]' == probes);
rereference = [];
for iCh=blockObj.Mask
   curCh = curCh + 1;
   if ~pars.STIM_SUPPRESS
       % Get the values from Raw DiskData, and decimate:
       data=double(blockObj.Channels(iCh).Raw(:));
   else
       data=double(blockObj.execStimSuppression(iCh));
   end
   
   for jj=1:numel(DecimateCascadeM)
      data=decimate(data,DecimateCascadeM(jj),DecimateCascadeN(jj));
   end
      
   if isfield(pars,'NotchF') &&~isempty(pars.NotchF)
       data = notchMainPower(data,blockObj.Pars.LFP.DownSampledRate,pars.NotchF,3);
   end
   % Get the file name:
   fName = parseFileName(blockObj,iCh);
   
   if size(rereference,2)==0
       rereference = zeros(numel(probes),numel(data));
   end
   data = data(:)';
   thisProbe = find(probes == blockObj.Channels(iCh).probe);
   rereference(thisProbe,:) = rereference(thisProbe,:) + ...
                                data./nChanProbe(thisProbe);
   
   % Assign to diskData and protect it:
   blockObj.Channels(iCh).LFP = nigeLab.libs.DiskData(fType,...
      fName,data,'access','w','overwrite',true);
   pct = round(curCh/nCh*50);
   blockObj.reportProgress(str,pct,'toWindow');
   blockObj.reportProgress('Decimating.',pct,'toEvent');
     if ~pars.ReReference
       lockData(blockObj.Channels(iCh).LFP);
       blockObj.updateStatus('LFP',true,iCh);
   end
end


% Rereferncing step
curCh = 0;
if pars.ReReference
    for iCh=blockObj.Mask
        curCh = curCh + 1;
        data = blockObj.Channels(iCh).LFP(:);
        thisProbe = probes == blockObj.Channels(iCh).probe;
        blockObj.Channels(iCh).LFP(:) = data - rereference(thisProbe,:);
        lockData(blockObj.Channels(iCh).LFP);
        
        pct = round(curCh/nCh*50);
        blockObj.reportProgress(str,pct,'toWindow');
        blockObj.reportProgress('Rereferencing.',pct,'toEvent');
        blockObj.updateStatus('LFP',true,iCh);
        
    end
   
    
end

% Saving  

if blockObj.OnRemote
   str = 'Saving-Block';
   blockObj.reportProgress(str,95,'toWindow',str);
else
   linkStr = blockObj.getLink('LFP');
   str = sprintf('<strong>LFP extraction</strong> complete: %s\n',linkStr);
   blockObj.reportProgress(str,100,'toWindow','Done');
   blockObj.reportProgress('Done',100,'toEvent');
end
blockObj.save;

for iProbe = 1:size(rereference,1)
    refName = fullfile(sprintf(...
        strrep(blockObj.Paths.LFP.file,'\','/'),...
        num2str(iProbe),'REF'));
    refMeanFile{iProbe} = nigeLab.libs.DiskData(...
        'MatFile',refName,rereference(iProbe,:),'access','w','overwrite',true);
    
end

for iCh = blockObj.Mask
    thisProbe = probes == blockObj.Channels(iCh).probe;
   blockObj.Channels(iCh).refMeanLFP = refMeanFile{thisProbe};
end

flag = true;
   function fName = parseFileName(blockObj,channel)
      %PARSEFILENAME  Get file name from a given channel
      pNum  = num2str(blockObj.Channels(channel).probe);
      chNum = blockObj.Channels(channel).chStr;
      fName = sprintf(strrep(blockObj.Paths.LFP.file,'\','/'), pNum,chNum);
   end

end

