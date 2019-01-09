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
%                       depends on if sorting has been done. 
%                       Otherwise it gets all spikes. 
%                       If class is specified, it will check to make sure 
%                       that there are actually classes associated with the
%                       spike and issue a warning if that part hasn't been 
%                       done yet.
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

%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
if (numel(ch)>1)
   ts = cell(size(ch));
   for ii = 1:numel(ch)
      ts{ii} = getSpikeTimes(blockObj,ch(ii),class); 
   end   
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if numel(blockObj) > 1
   ts = [];
   for ii = 1:numel(blockObj)
      ts = [ts; getSpikeTimes(blockObj(ii),ch,class)]; %#ok<AGROW>
   end 
   return;
end

%% GET SPIKE PEAK SAMPLES AND CONVERT TO TIMES
idx = getSpikeTrain(blockObj,ch,class);
ts = idx ./ blockObj.SampleRate;



end