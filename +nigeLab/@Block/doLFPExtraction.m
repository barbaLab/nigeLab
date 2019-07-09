function flag = doLFPExtraction(blockObj)
%% DOLFPEXTRACTION   Decimates files to retrieve LFPs.
%
% Sampling frequency chosen for the downsampled files is 1000Hz
% Band of interest in LFPs is up to 250Hz.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)


%% INITIALIZE PARAMETERS
flag = false;
if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

if ~blockObj.updateParams('LFP')
   warning('Something went wrong setting the LFP parameters.');
   return;
end

DecimateCascadeM = blockObj.LFPPars.DecimateCascadeM;
DecimateCascadeN = blockObj.LFPPars.DecimateCascadeN;
DecimationFactor =   blockObj.LFPPars.DecimationFactor;
blockObj.LFPPars.DownSampledRate = blockObj.SampleRate / DecimationFactor;

%% DECIMATE DATA AND SAVE IT
fprintf(1,'Decimating raw data... %.3d%%\n',0);
ProgressPath = fullfile(nigeLab.defaults.Tempdir,['doLFPExtraction',blockObj.Name]);
fid = fopen(ProgressPath,'wb');
fwrite(fid,numel(blockObj.Mask),'int32');
fclose(fid);
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
   blockObj.Channels(iCh).LFP=nigeLab.libs.DiskData(fType,...
      fName,data,'access','w');
   blockObj.Channels(iCh).LFP = lockData(blockObj.Channels(iCh).LFP);
   
   pct = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
   fid = fopen(fullfile(ProgressPath),'ab');
   fwrite(fid,1,'uint8');
   fclose(fid);
end
blockObj.updateStatus('LFP',true);
blockObj.save;
flag = true;
end

function fName = parseFileName(blockObj,channel)
%% PARSEFILENAME  Get file name from a given channel
pNum  = num2str(blockObj.Channels(channel).port_number);
chNum = blockObj.Channels(channel).chStr;
fName = sprintf(strrep(blockObj.Paths.LFP.file,'\','/'), pNum, chNum);
end



