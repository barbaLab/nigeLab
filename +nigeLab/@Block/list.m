function L = list(blockObj)
%% LIST  Give list of current files associated with field.
%
%  L = blockObj.LIST;
%
%  --------
%   INPUTS
%  --------
%  blockObj :     nigeLab.Block class object.
%
%  --------
%   OUTPUT
%  --------
%     L     :     Table with information about blockObj.
%
% By: Max Murphy  v1.0  06/13/2018 Original Version (R2017a)
%                 v1.1  06/14/2018 Added flag output
%                 v1.2  ?? ?? ???? Assume modified by FB ? 

%% PARSE DATE AND TIME INFO
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
                
info.Recording_date=DateTime;
info.LengthInMinutes=minutes(seconds((blockObj.Samples./blockObj.SampleRate)));

%% PARSE ANIMAL AND RECORDING ID
infoFields={'AnimalID'
            'RecID'
            };
for jj=1:numel(infoFields)
   info.(infoFields{jj})={blockObj.Meta.(infoFields{jj})};
end

%% PARSE RECORDING TYPE AND TOTAL NUMBER OF CHANNELS
infoFields={'RecType'
            'NumChannels'
            };
for jj=1:numel(infoFields)
   info.(infoFields{jj})={blockObj.(infoFields{jj})};
end

% Update RecType (for example, for Intan .rhd or .rhs; TDT will not have a
% file extension though.
info.RecType={sprintf('%s (%s)',info.RecType{:},blockObj.FileExt)};

%% PARSE CURRENT STATUS OF PROCESSING
St = blockObj.getStatus;
info.Status = sprintf([repmat('%s,',1,numel(St)) '\b'],St{:});


%% CONVERT STRUCT INTO TABLE FORMAT SO IT CAN BE PRINTED TO COMMAND WINDOW
L_=struct2table(info,'AsArray',true);
for ii=1:length(L_.Properties.VariableNames)
    switch L_.Properties.VariableNames{ii}
        case 'Corresponding_animal' % Deprecated I think ? -MM
            L_.Properties.VariableNames{ii}='Animal';
        case 'RecType'
            L_.Properties.VariableNames{ii}='RecordingType';
        case 'numChannels' % Deprecated as well? -MM
            L_.Properties.VariableNames{ii}='NumberOfChannels';
    end
end

%% IF OUTPUT ARGUMENT IS REQUESTED, DO NOT DISPLAY IT
if nargout==0
    disp(L_);
else
    L=L_;
end

end