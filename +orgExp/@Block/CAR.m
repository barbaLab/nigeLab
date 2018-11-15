function CAR(blockObj)
probes=unique([blockObj.Channels.port_number]);
num_amplifier_channels=length(blockObj.Channels(1).Filtered);
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

fprintf(['Applying CAR rereferncing...' newline]);
for iCh = 1:length(blockObj.Channels)
    if ~STIM_SUPPRESS
        % Filter and and save amplifier_data by probe/channel
        pnum  = num2str(blockObj.Channels(iCh).port_number);
        chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
        iPb = blockObj.Channels(iCh).port_number;
        nChanPb = sum(iPb == [blockObj.Channels.port_number]);
        fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);
        load(fname,'data');
        probe_ref(iPb,:)=probe_ref(iPb,:)+data./nChanPb;
        %             data = single(filtfilt(b,a,double(data)));
    end
    clear('data')
end

% Save amplifier_data CAR by probe/channel
if ~STIM_SUPPRESS
    car_infoname = fullfile(blockObj.paths.CARW,[blockObj.Name '_CAR_Ref.mat']);
    save(fullfile(car_infoname),'probe_ref','-v7.3');
    for iCh = 1:length(blockObj.Channels)
        pnum  = num2str(blockObj.Channels(iCh).port_number);
        chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
        fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);       % loads filtered data
        load(fname,'data');
        
        data = data - probe_ref(blockObj.Channels(iCh).port_number,:); % rereferencing
        
        fname = sprintf(strrep(blockObj.paths.CARW_N,'\','/'), pnum, chnum);     % save CAR data
        save(fullfile(fname),'data','-v7.3');
    end
    clear('data')
end
fprintf(1,'Done.\n');
blockObj.updateStatus('CAR',true);
end

