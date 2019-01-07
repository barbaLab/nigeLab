function ts = getSpikeTimes(blockObj,ch,class)
%% GETSPIKETIMES  Retrieve list of spike times (seconds)
%
%  ts = GETSPIKETIMES(blockObj,ch);
%  ts = GETSPIKETIMES(blockObj,ch,class);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
%
%    ch        :     Channel index for retrieving spikes.
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%
%   class      :     (Optional) Specify the class of spikes to retrieve,
%                       based on sorting or clustering. If not specified,
%                       gets all spikes on channel. Otherwise, it will
%                       check to make sure that there are actually classes
%                       associated with the spike and issue a warning if
%                       that part hasn't been done yet.
%                       -> Can be given as a vector.
%                       -> Non-negative integer.
%
%  --------
%   OUTPUT
%  --------
%     ts       :     Vector of spike times (sec)
%                    -> If ch is a vector, returns a cell array of
%                       corresponding spike sample times.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2
   ch = 1:blockObj.NumChannels;
end

if nargin < 3
   class = nan;
end

%% GET SPIKE PEAK SAMPLES AND CONVERT TO TIMES
idx = getSpikeTrain(blockObj,ch,class);

if numel(ch) > 1
   ts = cell(size(idx));
   for ii = 1:numel(ch)
      ts{ii} = idx{ii} ./ blockObj.SampleRate;
   end 
else
   ts = idx ./ blockObj.SampleRate;
end


end