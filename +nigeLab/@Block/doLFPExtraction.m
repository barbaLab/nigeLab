function flag = doLFPExtraction(blockObj)
%% DOLFPEXTRACTION   Decimates files to retrieve LFPs.
%
% Sampling frequency chosen for the downsampled files is 1000Hz
% Band of interest in LFPs is up to 250Hz.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)


%% INITIALIZE PARAMETERS
flag = false;
blockObj.checkActionIsValid();
nigeLab.utils.checkForWorker('config');

if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end



if ~blockObj.updateParams('LFP')
   warning('Something went wrong setting the LFP parameters.');
   return;
%    error('Something went wrong setting the LFP parameters.');
end

DecimateCascadeM = blockObj.Pars.LFP.DecimateCascadeM;
DecimateCascadeN = blockObj.Pars.LFP.DecimateCascadeN;
DecimationFactor =   blockObj.Pars.LFP.DecimationFactor;
blockObj.Pars.LFP.DownSampledRate = blockObj.SampleRate / DecimationFactor;

%% DECIMATE DATA AND SAVE IT
str = nigeLab.utils.getNigeLink('nigeLab.Block','doLFPExtraction',...
      'Decimating');
str = sprintf('%s raw data',str);

for iCh=blockObj.Mask
   % Get the values from Raw DiskData, and decimate:
   data=double(blockObj.Channels(iCh).Raw(:));
   for jj=1:numel(DecimateCascadeM)
      data=decimate(data,DecimateCascadeM(jj),DecimateCascadeN(jj));
   end
   
   % Get the file name:
   fName = parseFileName(blockObj,iCh);
   
   % Assign to diskData and protect it:
   fType = blockObj.FileType{strcmpi(blockObj.Fields,'LFP')};
   blockObj.Channels(iCh).LFP = nigeLab.libs.DiskData(fType,...
      fName,data,'access','w');
   blockObj.Channels(iCh).LFP = lockData(blockObj.Channels(iCh).LFP);

   pct = round(iCh/numel(blockObj.Mask) * 100);
   blockObj.reportProgress(str,pct,'toWindow');
   blockObj.reportProgress('Decimating.',pct,'toEvent');
   blockObj.updateStatus('LFP',iCh,true);
end
blockObj.save;
flag = true;
end

function fName = parseFileName(blockObj,channel)
%% PARSEFILENAME  Get file name from a given channel
pNum  = num2str(blockObj.Channels(channel).port_number);
chNum = blockObj.Channels(channel).chStr;
fName = sprintf(strrep(blockObj.Paths.LFP.file,'\','/'), pNum, chNum);
end



