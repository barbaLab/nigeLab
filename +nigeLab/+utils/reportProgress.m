function str = reportProgress(string, pct ) 
% REPORTPROGRESS  Utility function to report progress on block operations. 
%
%  str = nigeLab.utils.reportProgress(string,pct);
%
%  inputs:
%  string  --  <a> tag to define hyperlinks </a>
%              <strong> to define bold </strong>
%  pct  --  Current percentage to update as associated with the string.
%           --> If not provided, defaults to 0 (assume that this is the
%               first declaration of the string (outside the loop for
%               example).
%
%  Description:
%       It uses the notification string specified in defaults.Notification, 
%       where you can specify what metadata it should be printed on screen 
%       along with the *string* input and the percentage.
%
%  2019-12-11: Added copy to nigeLab.utils to start replacing block method
%              version with calls to the utility function.

if nargin < 2
   pct = 0; 
end

pars = nigeLab.defaults.Notifications;
pct = round(pct);
if ~nigeLab.utils.checkForWorker % serial execution on localhost
    metas = cell(1, numel(pars.NotifyString.Vars));
    for ii=1:numel(pars.NotifyString.Vars),metas{ii} = eval(pars.NotifyString.Vars{ii});end
        str = sprintf(pars.NotifyString.String,metas{:},...         % constant part of the message
            string,floor(pct));                                     % variable part of the message
        if nargout == 1
           return;
        end
        
        if ~floor(mod(pct,pars.MinIncrement)) % only increment counter by a certain amount defined in defaults.
           tmpstr = regexprep(str,'<.*?>','');
            lastDisplText = getLastDispText(numel(tmpstr));
            
            lastDisplText = regexprep(lastDisplText,'>> ','');
            strtIndx = regexp(lastDisplText,[eval(pars.NotifyString.Vars{1})]);
            lastDisplText = lastDisplText(strtIndx:end);
            nextDisplText = regexprep(str,'\d*%',sprintf('%.3d%%%%\n',pct));
            nextDisplText = regexprep(nextDisplText,'\\','\\\\');

            stringMatch = regexp(lastDisplText,regexprep(string,'<.*?>',''),'ONCE');
            if ~isempty(stringMatch)
                try
                    tmpstr = regexprep(sprintf(nextDisplText),'<.*?>','');
                    fprintf(1,[repmat('\b',1,length(tmpstr)) nextDisplText]);
                catch
                    fprintf(1,'\n');
                    fprintf(1,pars.NotifyString.String,metas{:},...             % constant part of the message
                        string,floor(pct));
                end
            else     
                
                fprintf(1,pars.NotifyString.String,metas{:},...             % constant part of the message
                    string,floor(pct));                                     % variable part of the message
            fprintf(1,'\n');
            end
            
        end
    
else % we are in worker environment
    string = regexprep(sprintf(string),'<.*?>','');
    job = getCurrentJob;
    metas = cell(1, numel(pars.TagString.Vars));
    for ii=1:numel(pars.TagString.Vars),metas{ii} = eval(pars.TagString.Vars{ii});end
    str = sprintf(pars.TagString.String,metas{:},...                     % variable part of the message
        string,floor(pct));
    if nargout == 1,return;end
    set(job,'Tag',...
        str);                                             % constant part of the message);
end

end

function txt = getLastDispText(nChars)
[cmdWin]=com.mathworks.mde.cmdwin.CmdWin.getInstance;
cmdWin_comps=get(cmdWin,'Components');
subcomps=get(cmdWin_comps(1),'Components');
text_container=get(subcomps(1),'Components');
output_string=get(text_container(1),'text');
txt = output_string(end-min(end-1,nChars):end);
end
