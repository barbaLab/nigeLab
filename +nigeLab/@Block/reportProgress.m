function str = reportProgress(blockObj, string, pct ) %#ok<INUSL>
%%

pars = nigeLab.defaults.Notifications;

if ~nigeLab.utils.checkForWorker % serial execution on localhost
    metas = cell(1, numel(pars.NotifyString.Vars));
    for ii=1:numel(pars.NotifyString.Vars),metas{ii} = eval(pars.NotifyString.Vars{ii});end
        str = sprintf(pars.NotifyString.String,metas{:},...         % constant part of the message
            string,floor(pct));                                     % variable part of the message
        if nargout == 1,return;end
        
        if ~floor(mod(pct,pars.MinIncrement)) % only increment counter by a certain amount defined in defaults.
           
            lastDisplText = getLastDispText(numel(str)+3);
            
            lastDisplText = regexprep(lastDisplText,'>> ','');
            strtIndx = regexp(lastDisplText,[eval(pars.NotifyString.Vars{1})]);
            lastDisplText = lastDisplText(strtIndx:end);
            nextDisplText = regexprep(lastDisplText,'\d*%',sprintf('%.3d%%%%\n',pct));
            nextDisplText = regexprep(nextDisplText,'\n*','\\n');
            nextDisplText = regexprep(nextDisplText,'\r','\\r');
            nextDisplText = regexprep(nextDisplText,'\t','\\t');
            nextDisplText = regexprep(nextDisplText,'\v','\\v');

            stringMatch = regexp(lastDisplText,string,'ONCE');
            if ~isempty(stringMatch)
                try
                fprintf(1,[repmat('\b',1,length(lastDisplText)) nextDisplText]);
                catch
                    fprintf(1,'\n');
                    fprintf(1,pars.NotifyString.String,metas{:},...             % constant part of the message
                        string,floor(pct));
                end
            else     
                
                fprintf(1,pars.NotifyString.String,metas{:},...             % constant part of the message
                    string,floor(pct));                                     % variable part of the message
            end
            
        end
    
else % we are in worker environment
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
txt = output_string(end-nChars:end);
end
