function N = NumChannels(blockObj)
%NUMCHANNELS  Number of elements in .Channels array (# recording channels)
%
%  N = blockObj.NumChannels;
%
%  N = NumChannels(blockObjArray); Returns [1 x nBlock] array

nB = numel(blockObj);
if nB > 1
   N = zeros(1,nB);
   for i = 1:nB
      N(i) = blockObj(i).NumChannels;
   end
   return;
end
N = numel(blockObj.Channels);
end