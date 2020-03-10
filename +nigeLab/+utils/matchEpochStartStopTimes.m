function varargout = matchEpochStartStopTimes(ts_on,ts_off)
%MATCHEPOCHSTARTSTOPTIMES  Match epoch start and stop time vectors
%
%  T = nigeLab.utils.matchEpochStartStopTimes(ts_on,ts_off);
%  [ts_on_matched,ts_off_matched] = matchEpochStartStopTimes(ts_on,ts_off);
%
%  All values may be given in vectors of times (seconds) OR sample indices
%  (integer values), but ts_on and ts_off should either BOTH be times or
%  BOTH be index vectors.
%
%  -- Inputs --
%  ts_on  : Vector of timestamps of "epoch" or "trial" start (onset) times
%  ts_off : Vector of timestamps of "epoch" or "trial" stop (offset) times
%
%  -- Output --
%  -> (1 output requested)
%  --> T  : 2 x nEpoch or nTrial matrix of "start" and "stop" values
%
%  -> (2 outputs requested)
%  --> ts_on_matched  : Same as ts_on, but matched to ts_off
%  --> ts_off_matched : Same as ts_off, but matched to ts_on
%
%  Note: if there is a discrepancy between number of elements in ts_on and
%        ts_off, then `ts_on` is used to determine the total number of
%        "trials" or "epochs" from the output.

nargo = min(max(nargout,1),2);
varargout = cell(1,nargo);
if nargo > 1
   [varargout{:}] = matchVectorsOut(ts_on,ts_off);
else
   varargout{1} = matchMatrixOut(ts_on,ts_off);
end

% Helper functions
   function T = matchMatrixOut(ts_on,ts_off)
      %MATCHMATRIXOUT  Function handle if 1 or less outputs requested
      %
      %  T = matchMatrixOut(ts_on,ts_off);
      
      [tStart,tStop] = fixInputVectorSizes(ts_on,ts_off);
      tStart = reshape(tStart,1,numel(tStart));
      tStop = reshape(tStop,1,numel(tStop));
      T = [tStart; tStop];
   end

   function [ts_on_matched,ts_off_matched] = matchVectorsOut(ts_on,ts_off)
      %MATCHVECTORSOUT  Function handle if 2 outputs requested
      %
      %  [ts_on_matched,ts_off_matched] = matchVectorsOut(ts_on,ts_off);
      
      [ts_on_matched,ts_off_matched] = fixInputVectorSizes(ts_on,ts_off);
      
   end

   function [tStart,tStop] = fixInputVectorSizes(ts_on,ts_off)
      %FIXINPUTVECTORSIZES  Return ts_on and ts_off of matched size
      %
      %  [tStart,tStop] = fixInputVectorSizes(ts_on,ts_off);
      
      M = numel(ts_off);
      N = numel(ts_on);
      delta = N - M;
      switch delta
         case 0
            tStart = ts_on;
            tStop = ts_off;
            return;
         case 1
            tStart = ts_on;
            tStop = fixSingleClippedEpoch(ts_off,sign(delta));
            
         otherwise
            [~,tmpIdx] = unique(ts_on);
            vec = setdiff(1:numel(ts_on),reshape(tmpIdx,1,numel(tmpIdx)));
            ts_on(vec) = nan;
            ts_off = unique(ts_off);
            [tStart,tStop] = fixAllEpochTimes(ts_on,ts_off,N);
      end
   end

   function [tStart,tStop] = fixAllEpochTimes(ts_on,ts_off,N)
      %FIXALLEPOCHTIMES  Fix "all" epoch values by matching "starts" only
      %
      %  [tStart,tStop] = fixAllEpochTimes(ts_on,ts_off);
      %  --> For N elements of `ts_on`, returns N-element vectors `tStart`
      %      and closest matched (or `NaN` if no suitable value is found,
      %      for example if no value of `ts_off` is greater than the
      %      matched element of `ts_on`) value of "stop" times or indices
      %      as `tStop`
      %  
      %  [ts_on,ts_off] = fixAllEpochTimes(ts_on,ts_off,N);
      %  --> By default, `N` is the number of elements of `ts_on`, but it
      %      can be set manually as well to return a fixed-size vector of
      %      epoch start and epoch stop times.
      
      % If `N` not specified, get it from number of "starts"
      if nargin < 3
         N = numel(ts_on);
      end
      % Since `N` could be different from # elements in `ts_on`
      k = min(numel(ts_on),N); 
      
      % Return outputs in same "size" as inputs
      firstDim = size(ts_on,1);
      if firstDim > 1
         tStart = nan(N,1);
         tStop = nan(N,1);
      else
         tStart = nan(1,N);
         tStop = nan(1,N);
      end
      
      % Make assignment since these are not changed regardless:
      tStart(1:k) = ts_on;
      
      % Iterate on number of elements of `ts_on` (if N > numel(ts_on), then
      % the last [N - numel(ts_on)] rows are just `NaN`
      for i = 1:k
         tmp = ts_off(ts_off >= tStart(i));
         if ~isempty(tmp)
            [~,idx] = min(tmp - tStart(i));
            tStop(i) = tmp(idx);
         end
         % Otherwise, tStop(i) is already `NaN` so no assignment needed
         
      end
   end

   function ts_off = fixSingleClippedEpoch(ts_off,mode)
      %FIXSINGLECLIPPEDEPOCH  Fix "clipped" epoch (add or remove 1 "stop")
      %
      %  ts_off = fixSingleClippedEpoch(ts_off,mode);
      %
      %  mode : If -1, removes the first `ts_off` "stop" element
      %         If  1, adds `inf` value to end of `ts_off`
      
      if mode > 0
         ts_off(end+1) = inf;
      else
         ts_off(1) = [];
      end
   end
end