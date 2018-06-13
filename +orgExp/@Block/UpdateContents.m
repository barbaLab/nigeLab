function UpdateContents(obj,fieldname)
%% UPDATECONTENTS    Update files for particular field
%
%  obj.UPDATECONTENTS(fieldname)
%
%  ex:
%  obj.UpdateContents('Raw');
%
%  --------
%   INPUTS
%  --------
%  fieldname   :  (String) name of field to re-check for new
%                 files.
%
% By: Max Murphy  v1.1  08/27/2017  (R2017a)

%% GET CORRECT SYNTAX
fieldmatch = false(size(obj.Fields));
for ii = 1:numel(obj.Fields)
   fieldmatch(ii) = strcmpi(fieldname,obj.Fields{ii});
end

if sum(fieldmatch) > 1
   error(['Redundant field names.\n' ...
      'Check Block_Defaults.mat or %s CPL_BLOCK object.\n'],...
      obj.Name);
elseif sum(fieldmatch) < 1
   error('No matching field in %s. Check CPL_BLOCK object.\n', ...
      obj.Name);
else
   fieldname = obj.Fields{fieldmatch};
end

%% UPDATE FILES DEPENDING ON CELL OR STRING CASES
% Lots of logical combinations for handling cell/non-cell inputs
if (~iscell(obj.ID.(fieldname).Folder) && ...
      ~iscell(obj.ID.(fieldname).File))
   obj.(fieldname).dir = [];
   obj.(fieldname).dir = [obj.(fieldname).dir; ...
      dir(fullfile(obj.DIR, ...
      [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder],...
      ['*' obj.ID.(fieldname).File '*.mat']))];
   
   obj.(fieldname).ch = [];
   for ii = 1:numel(obj.(fieldname).dir)
      temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
      ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         obj.(fieldname).ch = [obj.(fieldname).ch; nan];
         continue;
      end
      obj.(fieldname).ch = [obj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
   end
   if isempty(obj.(fieldname).dir)
      dname = fullfile(obj.DIR,...
         [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder]);
      if obj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               obj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               obj.Name,fieldname);
         end
      end
   else
      if obj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
            strjoin({obj.(fieldname).dir.name},'\n->\t'));
      end
   end
elseif (iscell(obj.ID.(fieldname).Folder) && ...
      ~iscell(obj.ID.(fieldname).File))
   obj.(fieldname).dir = [];
   for ii = 1:numel(obj.ID.(fieldname).Folder)
      obj.(fieldname).dir = [obj.(fieldname).dir; ...
         dir(fullfile(obj.DIR, ...
         [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{ii}],...
         ['*' obj.ID.(fieldname).File '*.mat']))];
   end
   
   obj.(fieldname).ch = [];
   for ii = 1:numel(obj.(fieldname).dir)
      temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
      ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         obj.(fieldname).ch = [obj.(fieldname).ch; nan];
         continue;
      end
      obj.(fieldname).ch = [obj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
   end
   if isempty(obj.(fieldname).dir)
      dname = fullfile(obj.DIR,...
         [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{ii}]);
      if obj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               obj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               obj.Name,fieldname);
         end
      end
   else
      if obj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
            strjoin({obj.(fieldname).dir.name},'\n->\t'));
      end
   end
elseif (iscell(obj.ID.(fieldname).File) && ...
      ~iscell(obj.ID.(fieldname).Folder))
   obj.(fieldname).dir = [];
   for ii = 1:numel(obj.ID.(fieldname).File)
      obj.(fieldname).dir = [obj.(fieldname).dir; ...
         dir(fullfile(obj.DIR, ...
         [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder],...
         ['*' obj.ID.(fieldname).File{ii} '*.mat']))];
   end
   
   obj.(fieldname).ch = [];
   for ii = 1:numel(obj.(fieldname).dir)
      temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
      ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         obj.(fieldname).ch = [obj.(fieldname).ch; nan];
         continue;
      end
      obj.(fieldname).ch = [obj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
   end
   if isempty(obj.(fieldname).dir)
      dname = fullfile(obj.DIR,...
         [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder]);
      if obj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               obj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               obj.Name,fieldname);
         end
      end
   else
      if obj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
            strjoin({obj.(fieldname).dir.name},'\n->\t'));
      end
   end
elseif (iscell(obj.ID.(fieldname).File) && ...
      iscell(obj.ID.(fieldname).Folder))
   obj.(fieldname).dir = [];
   for ii = 1:numel(obj.ID.(fieldname).File)
      for kk = 1:numel(obj.ID.(fieldname).Folder)
         obj.(fieldname).dir = [obj.(fieldname).dir; ...
            dir(fullfile(obj.DIR, ...
            [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{kk}],...
            ['*' obj.ID.(fieldname).File{ii} '*.mat']))];
      end
   end
   
   obj.(fieldname).ch = [];
   for ii = 1:numel(obj.(fieldname).dir)
      temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
      ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         obj.(fieldname).ch = [obj.(fieldname).ch; nan];
         continue;
      end
      obj.(fieldname).ch = [obj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
   end
   if isempty(obj.(fieldname).dir)
      dname = fullfile(obj.DIR,...
         [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{kk}]);
      if obj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               obj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               obj.Name,fieldname);
         end
      end
   else
      if obj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
            strjoin({obj.(fieldname).dir.name},'\n->\t'));
      end
   end
end
if isempty(obj.(fieldname).dir)
   obj.Status(fieldmatch) = false;
else
   obj.Status(fieldmatch) = true;
end
end