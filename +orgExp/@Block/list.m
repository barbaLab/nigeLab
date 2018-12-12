function L = list(blockObj)
%% LIST  Give list of current files associated with field.
%
%  flag = blockObj.LIST;
%  flag = blockObj.LIST(name);
%
%  Note: If called without an input argument, returns names of all
%  associated files for all fields.
%
%  --------
%   INPUTS
%  --------
%    name   :  Name of a particular field you want to return a
%              list of files for.
%
%  --------
%   OUTPUT
%  --------
%    flag   :  Returns true if no input argument is specified, if ANY file
%              is associated with the BLOCK. Otherwise returns false. If
%              name is specified, returns false if no files are associated
%              with the BLOCK.
%
% By: Max Murphy  v1.0  06/13/2018 Original Version (R2017a)
%                 v1.1  06/14/2018 Added flag output
Format = '';
str='';
if ~strcmp(blockObj.Meta.RecDate,'YYMMDD')
    Format = [Format 'yyMMdd'];
    str = [str blockObj.Meta.RecDate];
end
if ~strcmp(blockObj.Meta.RecTime,'hhmmss')
    Format = [Format 'HHmmss' ];
    str = [str blockObj.Meta.RecTime];
end
DateTime=datetime(str,'InputFormat',Format);
infoFields={'Animal_ID'
            'Rec_ID'
            };
                
info.Recording_date=DateTime;
info.LengthInMinutes=minutes(seconds((blockObj.Samples./blockObj.SampleRate)));
for jj=1:numel(infoFields)
info.(infoFields{jj})={blockObj.Meta.(infoFields{jj})};
end

infoFields={'RecType'
            'NumChannels'
            };
for jj=1:numel(infoFields)
   info.(infoFields{jj})={blockObj.(infoFields{jj})};
end

info.RecType={sprintf('%s (%s)',info.RecType{:},blockObj.FileExt)};
St = blockObj.getStatus;
info.Status = sprintf([repmat('%s,',1,numel(St)) '\b'],St{:});


L_=struct2table(info,'AsArray',true);
for ii=1:length(L_.Properties.VariableNames)
    switch L_.Properties.VariableNames{ii}
        case 'Corresponding_animal'
            L_.Properties.VariableNames{ii}='Animal';
        case 'RecType'
            L_.Properties.VariableNames{ii}='RecordingType';
        case 'numChannels'
            L_.Properties.VariableNames{ii}='NumberOfChannels';
    end
end
if nargout==0
    disp(L_);
else
    L=L_;
end
end