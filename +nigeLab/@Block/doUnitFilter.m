function flag = doUnitFilter(blockObj)
%% DOUNITFILTER   Filter raw data using spike bandpass filter
%
%  blockObj = nigeLab.Block;
%  doUnitFilter(blockObj);
%
%  Note: added varargin so you can pass <'NAME', value> input argument
%        pairs to specify adhoc filter parameters if desired, rather than
%        modifying the defaults.Filt source code.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% GET DEFAULT PARAMETERS
flag = false;
if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

if ~blockObj.updateParams('Filt')
   warning('Could not update filter parameters.');
   return;
else
   pars = blockObj.FiltPars;
end

fType = blockObj.FileType{strcmpi(blockObj.Fields,'Filt')};

%% DESIGN FILTER
bp_Filt = designfilt('bandpassiir', 'StopbandFrequency1', pars.FSTOP1, ...
   'PassbandFrequency1', pars.FPASS1, ...
   'PassbandFrequency2', pars.FPASS2, ...
   'StopbandFrequency2', pars.FSTOP2, ...
   'StopbandAttenuation1', pars.ASTOP1, ...
   'PassbandRipple', pars.APASS, ...
   'StopbandAttenuation2', pars.ASTOP2, ...
   'SampleRate', blockObj.SampleRate, ...
   'DesignMethod', pars.METHOD);

%% DO FILTERING AND SAVE
fprintf(1,'\nApplying bandpass filtering... ');
fprintf(1,'%.3d%%',0)
updateFlag = false(1,blockObj.NumChannels);
for iCh = blockObj.Mask
   if ~pars.STIM_SUPPRESS
      % Filter and and save amplifier_data by probe/channel
      pNum  = num2str(blockObj.Channels(iCh).port_number);
      chNum = blockObj.Channels(iCh).custom_channel_name(...
         regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
      data = single(filtfilt(bp_Filt,blockObj.Channels(iCh).Raw.double));
      
      fName = sprintf(strrep(blockObj.Paths.Filt.file,'\','/'), ...
         pNum, chNum);
      blockObj.Channels(iCh).Filt = nigeLab.libs.DiskData(...
         fType,fName,data,'access','w');
      blockObj.Channels(iCh).Filt = lockData(blockObj.Channels(iCh).Filt);
   else
      warning('STIM SUPPRESSION method not yet available.');
      return;
   end
   
   updateFlag(iCh) = true;
   pct = 100 * (iCh / blockObj.NumChannels);
   if ~floor(mod(pct,5)) % only increment counter by 5%
      fprintf(1,'\b\b\b\b%.3d%%',floor(pct))
   end
end
fprintf(1,'\b\b\b\bDone.\n');
blockObj.updateStatus('Filt',updateFlag);
flag = true;
blockObj.save;
end

