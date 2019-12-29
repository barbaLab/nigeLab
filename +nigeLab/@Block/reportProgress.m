function str = reportProgress(blockObj, str_expr, pct,notification_mode,tag_str) 
% REPORTPROGRESS  Utility function to report progress on block operations.
%
%  str = blockObj.reportProgress(string,pct);
%
%  inputs:
%  blockObj  --  nigeLab.Block object
%
%  str_expr  --  <a> tag to define hyperlinks </a>
%                <strong> to define bold </strong>
%
%  pct  --  Current percentage to update as associated with the string.
%           --> If not provided, defaults to 0 (assume that this is the
%               first declaration of the string (outside the loop for
%               example).
%
%  mode  --  Default: 'toWindow' (print to window)
%            Can set as 'toEvent' (notifies with event instead)
%
%  tag_str  --  "Fixed" string without html formatting (optional; for JOB)
%
%  Description:
%       It uses the notification string specified in defaults.Notification,
%       where you can specify what metadata it should be printed on screen
%       along with the *string* input and the percentage.
%
%  2019-12-11: Added copy to nigeLab.utils to start replacing block method
%              version with calls to the utility function. Note that THIS
%              version (the block method) will trigger the block
%              'ProgressUpdated' event.

if nargin < 4
   notification_mode = 'toWindow';
end

if nargin < 3
   pct = 0;
end

pars = blockObj.Pars.Notifications;
pct = round(pct);

switch lower(notification_mode)
   case {'towindow','cmd','commandwindow','window'}
      % Continue
   case {'toevent','event','evt','notify'}
      % Only do the event notification in Serial mode
      if ~nigeLab.utils.checkForWorker(blockObj)
         status = str_expr;
         evtData = nigeLab.evt.progressChangedEventData(status,pct);
         notify(blockObj,'ProgressChanged',evtData);
         
      end
      str = [];
      return;
   otherwise
      % Behave as if 'toWindow'
end

if ~nigeLab.utils.checkForWorker(blockObj) % serial execution on localhost
   %% Serial execution on localhost
   metas = cell(1, numel(pars.NotifyString.Vars));
   for ii=1:numel(pars.NotifyString.Vars)
      metas{ii} = blockObj.Meta.(pars.NotifyString.Vars{ii});
   end
   str = sprintf(pars.NotifyString.String,metas{:},...         % constant part of the message
      str_expr,floor(pct));                                     % variable part of the message
   if nargout == 1
      return;
   end
   
   % only increment counter by a certain amount defined in defaults.
   if ~floor(mod(pct,pars.MinIncrement))
      % This is only entered if % is an even multiple of pars.MinIncrement   
      cstr = strrep(sprintf(pars.ConstantString.String,metas{:}),'.','\.');
      tmpstr = regexprep(str,'<.*?>','');
      lastDisplText = nigeLab.utils.getLastDispText(numel(tmpstr)+1);
      
      lastDisplText = regexprep(lastDisplText,'>> ','');
      strtIndx = regexp(lastDisplText,cstr); % Get index of constant part
      
      % Now we are sure we have the previously-displayed text that
      % corresponds to what we wish to update:
      if isempty(strtIndx)
         stringMatch = [];
      else
         lastDisplText = lastDisplText(strtIndx(end):end);
         nextDisplText = regexprep(str,'\d*%',sprintf('%.3d%%%%\n',pct));
         nextDisplText = regexprep(nextDisplText,'\\','\\\\');
         stringMatch = regexp(lastDisplText,regexprep(str_expr,'<.*?>',''),'ONCE');
      end
      if ~isempty(stringMatch)
         try
            tmpstr = regexprep(sprintf(nextDisplText),'<.*?>','');
            fprintf(1,[repmat('\b',1,length(tmpstr)) nextDisplText]);
         catch
            fprintf(1,'\n');
            fprintf(1,pars.NotifyString.String,metas{:},...             % constant part of the message
               str_expr,floor(pct));
         end
      else
         fprintf(1,pars.NotifyString.String,metas{:},...             % constant part of the message
            str_expr,floor(pct));                                     % variable part of the message
         fprintf(1,'\n');
      end
   end
   
else % we are in worker environment
   %% Local or Remote parallel worker environment
   if nargin < 5
      tag_str = regexprep(sprintf(str_expr),'<.*?>','');
   end
   metas = cell(1, numel(pars.TagString.Vars));
   for ii=1:numel(pars.TagString.Vars)
      metas{ii} = blockObj.Meta.(pars.TagString.Vars{ii});
   end
   % Here, pars.TagString.String (nigeLab.defaults.Notifications) will
   % always have form ['%s.%s %s' pars.TagDelim '%.3d%%']. The delimited
   % portion is periodically checked by the TimerFcn running in the
   % remoteMonitor of nigeLab.libs.DashBoard, which then updates the bar
   % increment accordingly.
   str = sprintf(pars.TagString.String,metas{:},tag_str,pct);

   if nargout == 1
      return;
   end
   % getCurrentJob can be slow, so this just checks if property for job
   % already exists and takes that property value as the job if it is valid
   if ~isempty(blockObj.CurrentJob)
      if isvalid(blockObj.CurrentJob)
         job = blockObj.CurrentJob;
      else
         pause(15); % Make sure enough time to "catch" current job
         job = getCurrentJob;
         blockObj.CurrentJob = job;
      end
   else
      pause(15);
      job = getCurrentJob;
      blockObj.CurrentJob = job;
   end
   set(job,'Tag',str); 
end

end
