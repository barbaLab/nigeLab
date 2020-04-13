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
%  2020-01-29: Add ability for pct to be char, where 'clc' value causes the
%              printed line that was detected to be erased.

if nargin < 4
   notification_mode = 'toWindow';
end
pars = blockObj.Pars.Notifications; 
clc_single_line = false;
if nargin < 3
   pct = 0;
elseif ischar(pct)
   switch lower(pct)
      case {'clear','clc','erase'}
         clc_single_line = true;
         pct = 0;
      case {'done','done.','complete','complete.'}
         pct = 100;
      case {'init','init.','start','start.'}
         pct = 0;
   end
end
pct = round(pct);

if ~clc_single_line
   switch lower(notification_mode)
      case {'towindow','cmd','commandwindow','window'}
         % Continue
      case {'toevent','event','evt','notify'}
         % Only do the event notification in Serial mode
         if ~nigeLab.utils.checkForWorker(blockObj)
            status = str_expr;
            evtData = nigeLab.evt.progressChanged(status,pct);
            notify(blockObj,'ProgressChanged',evtData);
         end
         str = [];
         return;
      otherwise
         % Behave as if 'toWindow'
   end
end

if ~nigeLab.utils.checkForWorker(blockObj) % serial execution on localhost
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
      % Searches only the last number of characters in the command window
      % equal to the length of the "temporary" string + 1
      try % In case (for example on the remote) the path to java is messed up
         lastDisplText = nigeLab.utils.getLastDispText(numel(tmpstr)+1);
      catch
         return;
      end
      
      lastDisplText = regexprep(lastDisplText,'>> ','');
      strtIndx = regexp(lastDisplText,cstr); % Get index of constant part
      
      % Now we are sure we have the previously-displayed text that
      % corresponds to what we wish to update:
      if isempty(strtIndx) % If it is empty, then skip
         stringMatch = [];
      else % Otherwise, find index to "variable" part (if not clearing)
         lastDisplText = lastDisplText(strtIndx(end):end);
         nextDisplText = regexprep(str,'\d*%',sprintf('%.3d%%%%\n',pct));
         nextDisplText = regexprep(nextDisplText,'\\','\\\\');
         stringMatch = regexp(lastDisplText,regexprep(str_expr,'<.*?>',''),'ONCE');
      end
      if ~isempty(stringMatch) 
         try
%             tmpstr = regexprep(lastDisplText,'<.*?>','');
            tmpstr = regexprep(sprintf(nextDisplText),'<.*?>','');
            fprintf(1,repmat('\b',1,length(tmpstr))); % Erase previous 
            if clc_single_line
               return;
            else
               fprintf(1,nextDisplText);
            end
         catch
            fprintf(1,'\n');
            fprintf(1,pars.NotifyString.String,metas{:},...% constant part of the message
               str_expr,floor(pct));
         end
      else
         fprintf(1,pars.NotifyString.String,metas{:},...% constant part of the message
            str_expr,floor(pct));  % variable part of the message
         fprintf(1,'\n');
      end
   end
   
else % Local or Remote parallel worker environment
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

   if (nargout == 1) || clc_single_line
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
