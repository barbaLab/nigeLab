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


DateTime=datetime([blockObj.Recording_date blockObj.Recording_time],'InputFormat','yyMMddHHmmss');
infoFields={'RecType'
            'Corresponding_animal'
            'Recording_ID'
            'numChannels'
            };
                
info.Recording_date=DateTime;
info.Recording_length=minutes(seconds(size(blockObj.Channels(1).rawData,2)./blockObj.Sample_rate));
for jj=1:numel(infoFields)
info.(infoFields{jj})={blockObj.(infoFields{jj})};
end
info.RecType={sprintf('%s (%s)',info.RecType{:},blockObj.File_extension)};


L_=struct2table(info);
for ii=1:length(L_.Properties.VariableNames)
    switch L_.Properties.VariableNames{ii}
        case 'Recording_length'
            L_.Properties.VariableNames{ii}='LengthInMinutes';
        case 'Corresponding_animal'
            L_.Properties.VariableNames{ii}='Animals';
        case 'Recording_ID'
            L_.Properties.VariableNames{ii}='ID';
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

%% RETURN LIST OF VALUES
% if nargin == 2
%    if isempty(blockObj.(name).dir)
%       fprintf(1,'\nNo %s files found for %s.\n',name,blockObj.Name);
%       flag = false;
%    else
%       fprintf(1,'\nCurrent %s files stored in %s:\n->\t%s\n\n',...
%          name, blockObj.Name, ...
%          strjoin({blockObj.(name).dir.name},'\n->\t'));
%       flag = true;
%    end
% else
%    flag = false;
%    for iL = 1:numel(blockObj.Fields)
%       name = blockObj.Fields{iL};
%       if isempty(blockObj.(name).dir)
%          fprintf(1,'\nNo %s files found for %s.\n',name,blockObj.Name);
%       else
%          fprintf(1,'\nCurrent %s files stored in %s:\n->\t%s\n\n',...
%             name, blockObj.Name, ...
%             strjoin({blockObj.(name).dir.name},'\n->\t'));
%          flag = true;
%       end
%    end
% end
end