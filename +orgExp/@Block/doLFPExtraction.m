function doLFPExtraction(blockObj)
%% DOLFPEXTRACTION   Decimates files to retrieve LFPs.
% Sampling frequency chosen for the downsampled files is 1000Hz
% Band of interest in LFPs is up to 250Hz.


%% INITIALIZE PARAMETERS

pars = orgExp.defaults.LFP;

DownSampleFreq =   pars.DownSampleFreq;
DecimateCascadeM = pars.DecimateCascadeM;
DecimateCascadeN = pars.DecimateCascadeN;

blockObj.LFP_pars = pars;

%% DECIMATE DATA AND SAVE IT
for ii=1:blockObj.numChannels
   lfp=double(blockObj.Channels(ii).rawData);
   for jj=1:numel(DecimateCascadeM)
      lfp=decimate(lfp,DecimateCascadeM(jj),DecimateCascadeN(jj));
   end
   pNum  = num2str(blockObj.Channels(ii).port_number);
   chNum = blockObj.Channels(ii).custom_channel_name(regexp(blockObj.Channels(ii).custom_channel_name, '\d'));
   fName = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pNum, chNum);
   save(fullfile(fName),'lfp','-v7.3');
   blockObj.Channels(ii).LFP=orgExp.libs.DiskData(matfile(fullfile(fName)));
end
blockObj.Downsampled_rate=DownSampleFreq;
blockObj.updateStatus('LFP',true);
blockObj.save;
end

