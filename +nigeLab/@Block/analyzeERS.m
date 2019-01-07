function  [tf_map,times_in_ms]=analyzeERS(blockObj,options)

%% performs the event relater power spectrum analysis on the data provided 
% blockObj contains the recording and the metadata
% options is a structure where some parameters are specified such as the
% filtering options
% window depth for the spectrogram
% window step for the spectrogram
% frequency resolution we want to investigate the data
% The event structure has information about the events. It is a structure
% array where each element has the fields:
% time
% label
%
% different events type are defined by different labes

hp = 1;
lp = 300;
% Fs = blockObj.Downsampling_rate;
large_window = 2/3; % window length in sec
step_window  = 0.03; % step length in sec, smaller will make calculation take longer time
frequencies  = hp:lp; % in Hz, resolution 1 Hz

% window2 = hann( round(Fs*large_window) ); % in points/samples
window2 = round(Fs*large_window); % in points/samples
overlap = round( Fs*(large_window-step_window)); % in points/samples (integer)


for i=1:blockObj.numChannels
    fprintf(1,'channel %d of %d\n', i,blockObj.numChannels);
    
    
    [~, F, T, P] = spectrogram(blockObj.Channels(i).filtData(:), window2, overlap, frequencies, Fs);
    P = medfilt2(P,[5 5]);  % smooth the spectrogram
    
    
    % get map of each type of triggers
    for iter_conditions = 1:conditions_num
        %prepare parameters
        pretrig=options.pretrig*blockObj.Sample_rate;
        posttrig=options.posttrig*blockObj.Sample_rate;
        baseline=options.baseline*blockObj.Sample_rate;
     
        event_time = cat(1, events.time);
        
        %delete those cannot be used
        event_time(event_time+1.1*pretrig/Fs<1)=[];  %delete first several events that do not have enough time for pretrig
        event_time(event_time+1.1*posttrig/Fs>size(blockObj.Channels(i).filtData(:),2))=[]; %delete last several events that do not have enough time for posttrig
        
        nf=size(P,1);  %frequency channel number
        Nsamples=posttrig-pretrig+1; % time in sample points
        
        ntrig=length(event_time); %number of triggers
        
        epoched_data=zeros(ntrig,nf,Nsamples);
        event_sample=event_time*Fs;
        for ii=1:ntrig
            interval=[event_sample+pretrig:event_sample+posttrig];
            base_interval=event_sample+baseline(1):baseline(2)+event_sample;
            if interval(1)>=1 && interval(end)<=length(time_axis)
                epoched_baselines(ii,:)=mean(P(:,base_interval),2);
                epoched_base_vars(ii,:)=var(P(:,base_interval),2);
                epoched_data(ii,:,:)=(P(:,interval)-epoched_baselines(ii,:))./...
                epoched_base_vars(ii,:)*ones(1,Nsamples);         
            end
        end
        
 
        
        tf_map=100*squeeze(mean(epoched_data,1)); % definition of ERS/ERD, refer to https://doi.org/10.1016/S1388-2457(99)00141-8
        
        times_in_ms=1000/Fs*[pretrig:posttrig]; %time_in_ms = 1000ms*[Ts*sample_point], Ts = 1/Fs
        
        
        
        %save result to structure
        ers_erd_sensor(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
        ers_erd_sensor(iter_conditions).time_axis = times;
        ers_erd_sensor(iter_conditions).frequency_axis = frequencies;
        ers_erd_sensor(iter_conditions).tf_map(i,:,:) = tf_map;
        ers_erd_sensor(iter_conditions).label{i} = source.label{i};
    end
    
end

n_range=3;


end