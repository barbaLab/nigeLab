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

%% INITIALIZE PARAMETERS
flag = false;
blockObj.checkActionIsValid(); % Now contains `checkForWorker`

if ~genPaths(blockObj)
   warning('Something went wrong with extraction');
   return;
end

[~,pars] = blockObj.updateParams('LFP');

DecimateCascadeM = pars.LFP.DecimateCascadeM;
DecimateCascadeN = pars.LFP.DecimateCascadeN;
DecimationFactor =  pars.LFP.DecimationFactor;
blockObj.Pars.LFP.DownSampledRate = blockObj.SampleRate / DecimationFactor;

%% DECIMATE DATA AND SAVE IT
if ~blockObj.OnRemote
   str = nigeLab.utils.getNigeLink('nigeLab.Block','doLFPExtraction',...
         'Decimating');
   str = sprintf('%s raw data',str);
else
   str = 'Decimating';
end
fType = blockObj.FileType{strcmpi(blockObj.Fields,'LFP')};
for iCh=blockObj.Mask
   % Get the values from Raw DiskData, and decimate:
   data=double(blockObj.Channels(iCh).Raw(:));
   for jj=1:numel(DecimateCascadeM)
      data=decimate(data,DecimateCascadeM(jj),DecimateCascadeN(jj));
   end
   
   % Get the file name:
   fName = parseFileName(blockObj,iCh);
   
   % Assign to diskData and protect it:
   blockObj.Channels(iCh).LFP = nigeLab.libs.DiskData(fType,...
      fName,data,'access','w');
   blockObj.Channels(iCh).LFP = lockData(blockObj.Channels(iCh).LFP);

   pct = round(iCh/numel(blockObj.Mask) * 100);
   blockObj.reportProgress(str,pct,'toWindow');
   blockObj.reportProgress('Decimating.',pct,'toEvent');
   blockObj.updateStatus('LFP',true,iCh);
end
blockObj.linkToData('LFP');
blockObj.save;

if blockObj.OnRemote
   str = 'Complete';
else
   linkStr = blockObj.getLink('LFP');
   str = sprintf('<strong>LFP</strong> extraction complete: %s\n',linkStr);
end
blockObj.reportProgress(str,100,'toWindow','Done');
blockObj.reportProgress('Done',100,'toEvent');

flag = true;

   function fName = parseFileName(blockObj,channel)
      %PARSEFILENAME  Get file name from a given channel
      pNum  = num2str(blockObj.Channels(channel).probe);
      chNum = blockObj.Channels(channel).chStr;
      fName = sprintf(strrep(blockObj.Paths.LFP.file,'\','/'), pNum,chNum);
   end

end

