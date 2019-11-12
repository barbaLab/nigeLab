function str = reportProgress(blockObj, string, pct ) %#ok<INUSL>
%%

job = getCurrentJob;
pars = nigeLab.defaults.Notifications;

if isempty(job) % serial execution on localhost
    if ~floor(mod(pct,pars.MinIncrement)) % only increment counter by a certain amount defined in defaults.
        metas = cell(1, numel(pars.NotifyString.Vars));
        for ii=1:numel(pars.NotifyString.Vars),metas{ii} = eval(pars.NotifyString.Vars{ii});end
        str = sprintf(pars.NotifyString.String,metas{:},...                     % variable part of the message 
            string,floor(pct));                                             % constant part of the message
        if nargout == 1,return;end
        fprintf(1,str);
    end
    
else % we are in worker environment
    metas = cell(1, numel(pars.TagString.Vars));
    for ii=1:numel(pars.TagString.Vars),metas{ii} = eval(pars.TagString.Vars{ii});end
    str = sprintf(pars.TagString.String,metas{:},...                     % variable part of the message 
         string,floor(pct));
    if nargout == 1,return;end
    set(job,'Tag',...
         str);                                             % constant part of the message);
end

end

