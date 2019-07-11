function notifyUser(blockObj,myJob,op,stage,curIdx,totIdx)
%% NOTIFYUSER  Update user of job processing status
%
%  blockObj = nigeLab.Block();
%  myJob = getCurrentJob;
%  for curIdx = 1:totIdx
%     % Loop that updates a data field of Block (op) for some
%     % processing stage (e.g. 'info')
%     blockObj.NOTIFYUSER(myJob,op,stage,curIdx,totIdx);
%  end
%
%  % Note: if myJob is a parallel.job.CJSCommunicatingJob, then stage can
%           be specified as [] as it is unused.
%
% By: Max Murphy  v1.1  2019-07-11     Moved to own file/class method.

%%
% Compute overall completion percentage
if nargin < 6
   pctComplete = 0;
else
   pctComplete = floor(100 * (curIdx / totIdx));
end

pars = nigeLab.defaults.Notifications();

% If parallel job, update the job status tag so you can track progress
% using the Parallel Job Monitor
% if isa(myJob,'parallel.job.CJSCommunicatingJob')
if ~isempty(myJob)
   n = min(numel(blockObj.Name),pars.NMaxNameChars);
   name = blockObj.Name(1:n);
   strrep(name,'_','-');
   myJob = getCurrentJob; % I know this seems redundant, but I forgot: you can't pass job objects as function arguments. Because that makes sense. -MM
   set(myJob,'Tag',sprintf(pars.TagString,op,name,pars.TagDelim,pctComplete));
   
else % Otherwise, print to Command Window
   if pctComplete==0
      fprintf(1, pars.NotifyString,...
         op,stage,pctComplete);
   else
      fprintf(1,'\b\b\b\b\b%.3d%%\n',pctComplete);
   end
end
end