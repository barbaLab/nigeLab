function thresh = PreciseTimingThreshold(data,pars)
%% PRECISETIMINGTHRESHOLD Automatically determine threshold for spike detection. For OFFLINE use.
%   
%   thresh = PRECISETIMINGTHRESHOLD(data,pars)
%   
%   --------
%    INPUTS
%   --------
%     data      :       Single-channel data that has already had hard
%                       artifact rejection performed.
%
%     pars      :       Parameters, passed on from SPIKEDETECTIONARRAY.
%
%   --------
%    OUTPUT
%   --------
%    thresh     :       Threshold value to look for potential spikes.
%
% See also: SPIKEDETECTIONARRAY
%
% Max Murphy        v1.3    02/03/2017  Per Kelly's algorithm, I've updated 
%                                       the windowed threshold detection
%                                       method to be similar to the
%                                       paper of Quiroga et al (2004) in
%                                       how it adaptively gets the
%                                       median rectified threshold.
%                   v1.2    01/29/2016  Cleaned up code and documentation.
%                                       Changed input to just take pars, so
%                                       that nWin and winDur can be coded
%                                       in at higher functions.
% Alberto Averna    v1.1    11/02/2016  Switched to using median, rather
%                                       than minimum value.
% Kelly RM          v1.0    11/04/2015  Original version

%% REMOVE ANY DC-OFFSET INTRODUCED BY HARD REJECTION
    data_temp=data(data~=0);
    data_Mc=data-mean(data_temp);
    data_Mc(data==0)=0;
    
    clear data_temp data

%% CHECK WINDOW LENGTH
nSamples = numel(data_Mc);
winDur_samples = floor(pars.WINDUR.*pars.FS);
if nSamples < (pars.NWIN + winDur_samples)
    thresh = [];
    return
end

%% GET START AND END INDICES FOR EACH WINDOW
startSample = 1:(round(nSamples/pars.NWIN)):nSamples;
endSample = startSample+winDur_samples-1;

if isempty(endSample)
    thresh = [];
    return
end

%% FIND AVERAGE POWER WITHIN EACH WINDOW
thThis = ones(1,pars.NWIN) * pars.INIT_THRESH;
for iW = 1:pars.NWIN
% Here we exclude windows containing 0'S due to artifact rejection
% Since not all artifact may have been removed
% These artifacts would increase threshold greatly
    
    endSample(iW)   =   min(endSample(iW),nSamples)     ;
    curr_W          =   data_Mc(startSample(iW):endSample(iW)) ;

    if any(curr_W   ==  0) % Ignore windows with artifact
         continue;
    end
     
%     thThis(iW) = std(curr_W); 
    thThis(iW) = median(abs(curr_W))/0.6475; % From Quiroga et al (2004)

end

%% FIND MEDIAN WINDOW POWER AND SCALE FOR USE AS THRESHOLD

if exist('thThis','var')==0
    thThis = pars.INIT_THRESH;
end

thMedian=median(thThis); % Use median to exclude outlier windows
thresh = thMedian.*pars.MULTCOEFF;

end
