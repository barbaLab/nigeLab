function pars = Filt(varargin)
%FILT  Initialize filter parameters for bandpass filter
%
%  pars = defaults.Filt('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%                    -> 'FPASS1' [def: 300 Hz] // 1st passband frequency
%
%                    -> 'FPASS2' [def: 3000 Hz] // 2nd passband frequency
%
%                    -> 'ASTOP1' [def: 70 dB] // 1st stopband attenuation
%
%                    -> 'APASS' [def: 0.001 dB] // passband ripple
%
%                    -> 'ASTOP2' [def: 70 dB] // 2nd stopband attenuation
%
%                    -> 'METHOD' [def: 'ellip'] // IIR filter design method
%
%                    -> 'STIM_SUPPRESS' [def: false] // do stim suppression
%
%                    -> 'STIM_BLANK' [def: [1,3] ms] // prior and post stim
%                                                        blanking period
%
%  --------
%   OUTPUT
%  --------
%    pars      :     Parameters struct with filter parameters.

%% DEFAULTS
% The filtering routine can be specified here.
% A zero phase filtering will be implemented to preprocess the signal prior
% to spike detection. The filtering routine is optimized and compiled for
% performance. The function used is FilterX by Jan available on mathworks 
% file exchange.

%% Different filters are here proposed for usage.
% the filtering routing accepts the A,B filter coefficients in input.

FPASS1 = 300;        % First Passband Frequency
FPASS2 = 3000;       % Second Passband Frequency
ASTOP = 70;          % First Stopband Attenuation (dB)
APASS  = 0.1;        % Passband Ripple (dB)
METHOD = 'ellip';    % filter type
ORDER = 4;

STIM_SUPPRESS = true;  % set true to do stimulus artifact suppression
STIM_BLANK = [1 3];     % milliseconds prior and after to blank on stims
STIM_P_CH = [nan, nan]; % [probe #, channel #] for channel delivering stims

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


%% INITIALIZE PARAMETERS STRUCTURE OUTPUT
pars=struct;
pars.FPASS1 = FPASS1;      
pars.FPASS2 = FPASS2;    
pars.ASTOP  = ASTOP;         
pars.APASS  = APASS;   
pars.ORDER  = ORDER;

pars.METHOD = METHOD;

pars.STIM_SUPPRESS = STIM_SUPPRESS;
pars.STIM_BLANK = STIM_BLANK;
pars.STIM_P_CH = STIM_P_CH;

pars.getFilterCoeff = @(f) getFilterCoeff(pars,f);
end

function [b,a,zi,nfact,L] = getFilterCoeff(pars,fs)
%% Filter parameters definition
% Define here the filter parameters. Some suggested filters are already
% implemented.
% Some other values are extracted here that will be usefull later. 
switch pars.METHOD
   case 'ellip'
      [b,a]=ellip(pars.ORDER./2,pars.APASS,pars.ASTOP,[pars.FPASS1 pars.FPASS2]./fs);
      
   case 'filtdesellip'
      bp_Filt = designfilt('bandpassiir', ...
         'PassbandFrequency1', pars.FPASS1, ...
         'PassbandFrequency2', pars.FPASS2, ...
         'StopbandFrequency2', pars.FPASS2 + 50, ...
         'StopbandFrequency1', pars.FPASS1 - 50, ...
         'StopbandAttenuation1', pars.ASTOP, ...
         'PassbandRipple', pars.APASS, ...
         'StopbandAttenuation2', pars.ASTOP, ...
         'SampleRate', fs, ...
         'DesignMethod', 'ellip');
      a = bp_Filt.Coefficients;
      b = 1;
      
   case 'butter'
      [b,a]=butter(pars.ORDER,[pars.FPASS1 pars.FPASS2]./fs);
      
   case 'intanHPF'
      a = exp(-(2*pi*pars.FPASS1)/fs);
      b = 1 - a;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Don't modify this part (unless you know what you're doing) %%%%%
%% Taken from filtfilt function. Creates b and a in case of SOS filters.
% Also outputs other usefull parameters like: 
% nfact                        the lenght of the edge effect,
% zi                           the initial conditions 
% L                            the length of the filter bank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[L, ncols] = size(b);
na = numel(a);

% Rules for the first two inputs to represent an SOS filter:
% b is an Lx6 matrix with L>1 or,
% b is a 1x6 vector, its 4th element is equal to 1 and a has less than 2
% elements. 
if ncols==6 && L==1 && na<=2
    if b(4)==1
        warning(message('signal:filtfilt:ParseSOS', 'SOS', 'G'));
    else
        warning(message('signal:filtfilt:ParseB', 'a01', 'SOS'));
    end
end
issos = ncols==6 && (L>1 || (b(4)==1 && na<=2));
if issos
    %----------------------------------------------------------------------
    % b is an SOS matrix, a is a vector of scale values
    %----------------------------------------------------------------------
    g = a(:);
    ng = na;
    if ng>L+1
        error(message('signal:filtfilt:InvalidDimensionsScaleValues', L + 1));
    elseif ng==L+1
        % Include last scale value in the numerator part of the SOS Matrix
        b(L,1:3) = g(L+1)*b(L,1:3);
        ng = ng-1;
    end
    for ii=1:ng
        % Include scale values in the numerator part of the SOS Matrix
        b(ii,1:3) = g(ii)*b(ii,1:3);
    end
    
    ord = filtord(b);
    
    a = b(:,4:6).';
    b = b(:,1:3).';
         
    nfact = max(1,3*ord); % length of edge transients    
    if Npts <= nfact % input data too short
        error(message('signal:filtfilt:InvalidDimensionsDataShortForFiltOrder',num2str(nfact)))
    end
    
    % Compute initial conditions to remove DC offset at beginning and end of
    % filtered sequence.  Use sparse matrix to solve linear system for initial
    % conditions zi, which is the vector of states for the filter b(z)/a(z) in
    % the state-space formulation of the filter.
    zi = zeros(2,L);
    for ii=1:L
        rhs  = (b(2:3,ii) - b(1,ii)*a(2:3,ii));
        zi(:,ii) = ( eye(2) - [-a(2:3,ii),[1;0]] ) \ rhs;
    end
    
else
    %----------------------------------------------------------------------
    % b and a are vectors that define the transfer function of the filter
    %----------------------------------------------------------------------
    L = 1;
    % Check coefficients
    b = b(:);
    a = a(:);
    nb = numel(b);
    nfilt = max(nb,na);   
    nfact = max(1,3*(nfilt-1));  % length of edge transients

    % Zero pad shorter coefficient vector as needed
    if nb < nfilt
        b(nfilt,1)=0;
    elseif na < nfilt
        a(nfilt,1)=0;
    end
    
    % Compute initial conditions to remove DC offset at beginning and end of
    % filtered sequence.  Use sparse matrix to solve linear system for initial
    % conditions zi, which is the vector of states for the filter b(z)/a(z) in
    % the state-space formulation of the filter.
    if nfilt>1
        rows = [1:nfilt-1, 2:nfilt-1, 1:nfilt-2];
        cols = [ones(1,nfilt-1), 2:nfilt-1, 2:nfilt-1];
        vals = [1+a(2), a(3:nfilt).', ones(1,nfilt-2), -ones(1,nfilt-2)];
        rhs  = b(2:nfilt) - b(1)*a(2:nfilt);
        zi   = sparse(rows,cols,vals) \ rhs;
        % The non-sparse solution to zi may be computed using:
        %      zi = ( eye(nfilt-1) - [-a(2:nfilt), [eye(nfilt-2); ...
        %                                           zeros(1,nfilt-2)]] ) \ ...
        %          ( b(2:nfilt) - b(1)*a(2:nfilt) );
    else
        zi = zeros(0,1);
    end

end
end