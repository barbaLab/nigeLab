function UpdateID(obj,name,type,value)
%% UPDATEID Update the file or folder identifier for block
%
%  obj.UPDATEID(name,type,value)
%
%  --------
%   INPUTS
%  --------
%    name   :  String corresponding to one of the structure data
%              types (example: 'Raw' or 'Filt' etc.)
%
%    type   :  'File' or 'Folder'.
%
%    value  :  String corresponding to updated ID value.
%
%  NOTE: Inputs can be strings, or cell arrays of strings
%  corresponding to multiple simultaneous updates. If cell arrays
%  are specified, element i of each array correspond to one
%  another; therefore, each cell array must be the same length.
%
% By: Max Murphy  v1.0  08/25/2017  Original version (R2017a)

%% PARSE INPUT
if (~ischar(name) || ~ischar(type) || ~ischar(value))
   % Look for cell inputs:
   if (~iscell(name) && ~iscell(type) && ~iscell(value))
      error('Inputs must be strings or cell array of strings of equal length.');
   elseif (~iscell(name) && ~iscell(type))
      % Only one field changed, but with multiple options:
      name = lower(name);
      name(1) = upper(name(1));
      if strcmp(name,'Delimiter')
         error('ID.Delimiter cannot take multiple values.');
      end
      type = lower(type);
      type(1) = upper(type(1));
      if ~ismember(type,{'File'; 'Folder'})
         error('Type is %s, but must be ''File'' or ''Folder''',type);
      end
      
      str = strjoin(value,' + ');
      fprintf(1,'ID.%s.%s updated to %s\n',name,type,str);
      obj.ID.(name).(type) = cell(numel(value),1);
      for ii = 1:numel(value)
         obj.ID.(name).(type){ii} = value{ii};
      end
      
      obj.UpdateContents(name);
      return;
      
   else
      for iN = 1:numel(name)
         name{iN} = lower(name{iN});
         name{iN}(1) = upper(name{iN}(1));
         type{iN} = lower(type{iN});
         type{iN}(1) = upper(type{iN}(1));
      end
   end
else
   name = lower(name);
   name(1) = upper(name(1));
   if strcmp(name,'Delimiter')
      % Special case: update delimiter
      obj.ID.Delimiter = value;
      fprintf(1,'ID.Delimiter updated to %s\n',value);
      % Must update all fields since all are affected.
      for iL = 1:numel(obj.Fields)
         obj.UpdateContents(obj.Fields{iL});
      end
      fprintf(1,'Fields changed to reflect updated delimiter.\n');
      return;
   end
   type = lower(type);
   type(1) = upper(type(1));
   if ~ismember(type,{'File'; 'Folder'})
      error('Type is %s, but must be ''File'' or ''Folder''',type);
   end
end

%% UPDATE PROPERTY
if ~iscell(name)
   obj.ID.(name).(type) = value;
   fprintf(1,'ID.%s.%s updated to %s\n',name,type,value);
   obj.(name).dir = dir(fullfile(obj.DIR,...
      [obj.Name obj.ID.Delimiter obj.ID.(name).Folder], ...
      ['*' obj.ID.(name).File '*.mat']));
   
   obj.(name).ch = [];
   for ii = 1:numel(obj.(name).dir)
      temp = strsplit(obj.(name).dir(ii).name,obj.ID.Delimiter);
      ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
      obj.(name).ch = [obj.(name).ch; ...
         str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
   end
else
   % If multiple, update all first:
   for iN = 1:numel(name)
      obj.ID.(name{iN}).(type{iN}) = value{iN};
      fprintf(1,'ID.%s.%s updated to %s\n',name{iN},type{iN},value{iN});
   end
   
   % Then update lists
   for iN = 1:numel(name)
      obj.UpdateContents(name{iN});
   end
end

end