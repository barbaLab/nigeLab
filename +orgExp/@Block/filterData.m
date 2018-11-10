function filterData(blockObj)

% Filter command
STATE_FILTER = true; % Flag to emulate hardware high-pass filter (if true)
FSTOP1 = 250;        % First Stopband Frequency
FPASS1 = 300;        % First Passband Frequency
FPASS2 = 3000;       % Second Passband Frequency
FSTOP2 = 3050;       % Second Stopband Frequency
ASTOP1 = 70;         % First Stopband Attenuation (dB)
APASS  = 0.001;      % Passband Ripple (dB)
ASTOP2 = 70;         % Second Stopband Attenuation (dB)
MATCH  = 'both';     % Band to match exactly

SAVELOC = blockObj.SaveLoc;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Filtering
%% This section provides both a band pass filtering and the CAR
        
        % Determine CAR ref for each probe
%         hold_filt = zeros(size(amplifier_data));
%         probe_ref=zeros(numel(probes),num_amplifier_samples);
        
        % Get filter specs
        %         WP = [300 3000]/(0.5*blockObj.Sample_rate);
        filtspecs = struct( ...
            'FS', blockObj.Sample_rate, ...
            'FSTOP1', FSTOP1, ...
            'FPASS1', FPASS1, ...
            'FPASS2', FPASS2, ...
            'FSTOP2', FSTOP2, ...
            'ASTOP1', ASTOP1, ...
            'APASS', APASS, ...
            'ASTOP2', ASTOP2, ...
            'MATCH', MATCH);
        
        %         filtspecs = struct( ...
        %         'ORD', ORD, ...
        %         'RP', RP, ...
        %         'RS', RS, ...
        %         'WP', WP);
        
        %         [b,a] = ellip(ORD,RP,RS,WP);

        
        %% DESIGN FILTER
% Construct an FDESIGN object and call its ELLIP method.
% h  = fdesign.bandpass(FSTOP1, FPASS1, FPASS2, FSTOP2, ASTOP1, APASS, ...
%                       ASTOP2, blockObj.Sample_rate);
% Hd = design(h, 'ellip', 'MatchExactly', MATCH);

bp_Filt = designfilt('bandpassiir', 'StopbandFrequency1', FSTOP1, ...
                                   'PassbandFrequency1', FPASS1, ...
                                   'PassbandFrequency2', FPASS2, ...
                                   'StopbandFrequency2', FSTOP2, ...
                                   'StopbandAttenuation1', ASTOP1, ...
                                   'PassbandRipple', APASS, ...
                                   'StopbandAttenuation2', ASTOP2, ...
                                   'SampleRate', blockObj.Sample_rate, ...
                                   'DesignMethod', 'ellip');
          
        if ~STIM_SUPPRESS
            filt_infoname = fullfile(blockObj.paths.FW,[blockObj.Name '_Filtspecs.mat']);
            save(fullfile(filt_infoname),'filtspecs','-v7.3');
        end
        % Save amplifier_data by probe/channel
        fprintf(1,'Applying bandpass filtering...\n');
        fprintf(1,'%.3d%%',0)
        for iCh = 1:blockObj.numChannels          
            if ~STIM_SUPPRESS
                % Filter and and save amplifier_data by probe/channel
                pnum  = num2str(blockObj.Channels(iCh).port_number);
                chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
                data = single(filtfilt(bp_Filt,double(blockObj.Channels(iCh).rawData(:,:))));
                iPb = blockObj.Channels(iCh).port_number;
                nChanPb = sum(iPb == [blockObj.Channels.port_number]);
                %             data = single(filtfilt(b,a,double(data)));
                fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);
                save(fullfile(fname),'data','-v7.3');
                blockObj.Channels(iCh).Filtered = orgExp.libs.DiskData(matfile(fname));
            end
            clear data
            fraction_done = 100 * (iCh / blockObj.numChannels);
            if ~floor(mod(fraction_done,5)) % only increment counter by 5%
                fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
            end
        end
blockObj.updateStatus('filt',true);
blockObj.save;
end


% if STIM_SUPPRESS
%     reFilter_Stims(STIM_P_CH,(1),STIM_P_CH(2),...
%         'DIR',strrep(blockObj.paths.A,UNC_PATH,filesep),...
%         'USE_CLUSTER',true,...
%         'STIM_BLANK',STIM_BLANK);
% end


