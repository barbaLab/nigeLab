function spikes = getSpikes(blockObj,ch,class,type)
%% GETSPIKES  Retrieve list of spike peak sample indices
%
%  spikes = GETSPIKES(blockObj,ch);
%  spikes = GETSPIKES(blockObj,ch,class);
%  features = GETSPIKES(blockObj,ch,class,'feat');
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
%
%    ch        :     Channel index for retrieving spikes. Must be given as
%                       a SCALAR positive integer.
%
%   class      :     (Optional) Specify the class of spikes to retrieve,
%                       based on sorting or clustering. If not specified,
%                       gets all spikes on channel. Otherwise, it will
%                       check to make sure that there are actually classes
%                       associated with the spike and issue a warning if
%                       that part hasn't been done yet.
%                       -> Can be given as a vector.
%                       -> Non-negative integer.
%                       -> Default is NaN
%
%   type       :     (Optional) Specify the type of snippets to retrieve. 
%                       -> 'feat' : Retrieves the features extracted during
%                                   spike detection (currently defaulted to
%                                   Wavelet coefficients).
%
%  --------
%   OUTPUT
%  --------
%   spikes     :     Spike waveform snippets from the FILT or CARFILT data,
%                       corresponding to each identified spike wave peak
%                       (or subset that matches class vector elements). 
%
%  features    :     Feature coefficients used for semi-automated
%                       clustering and sorting. Only returned if 'feat' is
%                       specified for type variable.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUTS
if nargin < 4
   type = 'spikes';
end

if nargin < 3
   class = nan;
end

if nargin < 3
   class = nan;
elseif ~ismember('Sorted',blockObj.Fields(blockObj.Status))
   class = nan;
end

if nargin < 2
   error('Must specify channel input arg.');
end

if ~ParseSingleChannelInput(blockObj,ch)
   error('Check ''ch'' input argument.');
end
   
%% RETRIEVE SPIKES OR FEATURES
switch type % Could add expansion for things like 'pw' and 'pp' etc.
   case 'feat'
      % Variable is still called "spikes"
      spikes = blockObj.Channels(ch).Spikes.features;
      if ~isnan(class(1))
         idx = ismember(blockObj.Channels(ch).Sorted.class,class);
         spikes = spikes(idx,:);
      end
   otherwise % Default is 'spikes'
      spikes = blockObj.Channels(ch).Spikes.spikes;
      if ~isnan(class(1))
         idx = ismember(blockObj.Channels(ch).Sorted.class,class);
         spikes = spikes(idx,:);
      end
end
end