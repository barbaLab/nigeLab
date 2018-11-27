function pars = Init_Filt(varargin)
%% PARSE VARARGIN
if numel(varargin)==1
    varargin = varargin{1};
    if numel(varargin) ==1
        varargin = varargin{1};
    end
end

for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% defaults

% Filter command
FSTOP1 = 250;        % First Stopband Frequency
FPASS1 = 300;        % First Passband Frequency
FPASS2 = 3000;       % Second Passband Frequency
FSTOP2 = 3050;       % Second Stopband Frequency
ASTOP1 = 70;         % First Stopband Attenuation (dB)
APASS  = 0.001;      % Passband Ripple (dB)
ASTOP2 = 70;         % Second Stopband Attenuation (dB)
METHOD = 'ellip';    % filter type

STIM_SUPPRESS = false;
STIM_BLANK = [1 3];


%% INITIALIZE PARAMETERS STRUCTURE OUTPUT
pars=struct;
pars.FSTOP1 =FSTOP1;

pars.FSTOP1 = FSTOP1;      
pars.FPASS1 = FPASS1;      
pars.FPASS2 = FPASS2;    
pars.FSTOP2 = FSTOP2;      
pars.ASTOP1 = ASTOP1;         
pars.APASS  = APASS;      
pars.ASTOP2 = ASTOP2; 
pars.METHOD = METHOD;

pars.STIM_SUPPRESS = STIM_SUPPRESS;
pars.STIM_BLANK = STIM_BLANK;

end