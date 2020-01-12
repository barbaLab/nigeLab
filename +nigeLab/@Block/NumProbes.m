function N = NumProbes(blockObj)
%NUMPROBES  Number of unique probes (electrode arrays) in recording
%
%  N = blockObj.NumProbes;
%
%  N = NumProbes(blockObjArray); Returns [1 x nBlock] array

nB = numel(blockObj);
if nB > 1
   N = zeros(1,nB);
   for i = 1:nB
      N(i) = blockObj(i).NumProbes;
   end
   return;
end

switch blockObj.RecType
   case {'Intan','TDT','nigelBlock'}
      C = blockObj.ChannelID;
      N = numel(unique(C(:,1)));
   case 'Matfile'
      N = blockObj.MatFileWorkflow.Pars.NumProbes;
   otherwise
      error(['nigeLab:' mfilename ':UnsupportedRecType'],...
         '''%s'' is not a supported RecType.',blockObj.RecType);
      
end