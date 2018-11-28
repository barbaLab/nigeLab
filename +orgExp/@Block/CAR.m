function CAR(blockObj)
probes=unique([blockObj.Channels.port_number]);
num_amplifier_channels=length(blockObj.Channels(1).Filt);
probe_ref=zeros(numel(probes),num_amplifier_channels);

STIM_SUPPRESS = false;
STIM_P_CH = [nan, nan];
STIM_BLANK = [1 3];
FILE_TYPE = blockObj.File_extension;

if STIM_SUPPRESS
   if isnan(STIM_P_CH(1)) %#ok<UNRCH>
      error('STIM Probe Number not specified (''STIM_P_CH(1)'')');
   elseif isnan(STIM_P_CH(2))
      error('STIM Channel Number not specified (''STIM_P_CH(2)'')');
   end
end

if (~isnan(STIM_P_CH(1)) && ~isnan(STIM_P_CH(2)))
   STIM_SUPPRESS = true;
end

fprintf(1,'Applying CAR rereferncing... %.3d%%',0);
for iCh = 1:length(blockObj.Channels)
    if ~STIM_SUPPRESS
        % Filter and and save amplifier_data by probe/channel
        iPb = blockObj.Channels(iCh).port_number;
        nChanPb = sum(iPb == [blockObj.Channels.port_number]);
        data = blockObj.Channels(iCh).Filt(:);
        probe_ref(iPb,:)=probe_ref(iPb,:)+data./nChanPb;
    end
    fraction_done = 100 * (iCh / blockObj.numChannels);
    if ~floor(mod(fraction_done,5)) % only increment counter by 5%
        fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
    end
end
clear('data');
fprintf(1,'\b\b\b\bDone.\n');


% Save amplifier_data CAR by probe/channel
fprintf(1,'Saving data... %.3d%%',0);
if ~STIM_SUPPRESS
    car_infoname = fullfile(blockObj.paths.CARW,[blockObj.Name '_CAR_Ref.mat']);
    save(fullfile(car_infoname),'probe_ref','-v7.3');
    for iCh = 1:length(blockObj.Channels)
        pnum  = num2str(blockObj.Channels(iCh).port_number);
        chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
        data = blockObj.Channels(iCh).Filt(:);
        data = data - probe_ref(blockObj.Channels(iCh).port_number,:); % rereferencing        
        fname = sprintf(strrep(blockObj.paths.CARW_N,'\','/'), pnum, chnum);     % save CAR data
        blockObj.Channels(iCh).CAR = orgExp.libs.DiskData(blockObj.SaveFormat,fname,data);
        fraction_done = 100 * (iCh / blockObj.numChannels);
    if ~floor(mod(fraction_done,5)) % only increment counter by 5%
        fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
    end
    end
    clear('data')
end
fprintf(1,'\b\b\b\bDone.\n');
blockObj.updateStatus('CAR',true);
end

