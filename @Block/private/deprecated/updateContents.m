function updateContents(blockObj,fieldname)
%% UPDATECONTENTS    Update files for particular field
%
%  blockObj.UPDATECONTENTS;
%  blockObj.UPDATECONTENTS(fieldname);
%
%  ex:
%  blockObj.updateContents('Raw');
%
%  --------
%   INPUTS
%  --------
%  fieldname   :  (String) name of field to re-check for new
%                 files.
%
% By: Max Murphy  v1.1  08/27/2017  (R2017a)
%                 v1.2  06/13/2018  (R2017b) Added more input parsing.

%% PARSE INPUT
if exist('fieldname','var')
   fieldmatch = false(size(blockObj.Fields));
   for ii = 1:numel(blockObj.Fields)
      fieldmatch(ii) = strcmpi(fieldname,blockObj.Fields{ii});
   end

   if sum(fieldmatch) > 1
      error(['Redundant field names.\n' ...
         'Check Block_Defaults.mat or %s CPL_BLOCK object.\n'],...
         blockObj.Name);
   elseif sum(fieldmatch) < 1
      error('No matching field in %s. Check CPL_BLOCK object.\n', ...
         blockObj.Name);
   else
      fieldname = blockObj.Fields{fieldmatch};
   end
else
   for ii = 1:numel(blockObj.Fields)
      blockObj.UpdateContents(blockObj.Fields{ii});
   end
   return;
end

%% UPDATE FILES DEPENDING ON CELL OR STRING CASES
% Lots of logical combinations for handling cell/non-cell inputs
if (~iscell(blockObj.ID.(fieldname).Folder) && ...
      ~iscell(blockObj.ID.(fieldname).File))
   blockObj.(fieldname).dir = [];
   blockObj.(fieldname).dir = [blockObj.(fieldname).dir; ...
      dir(fullfile(blockObj.DIR, ...
      [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder],...
      ['*' blockObj.ID.(fieldname).File '*.mat']))];
   
   blockObj.(fieldname).ch = [];
   for ii = 1:numel(blockObj.(fieldname).dir)
      temp = strsplit(blockObj.(fieldname).dir(ii).name,blockObj.ID.Delimiter);
      ch_ind = find(ismember(temp,blockObj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         blockObj.(fieldname).ch = [blockObj.(fieldname).ch; nan];
         continue;
      end
      blockObj.(fieldname).ch = [blockObj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:blockObj.CH_FIELDWIDTH))];
   end
   if isempty(blockObj.(fieldname).dir)
      dname = fullfile(blockObj.DIR,...
         [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder]);
      if blockObj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               blockObj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               blockObj.Name,fieldname);
         end
      end
   else
      if blockObj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',blockObj.Name,fieldname,...
            strjoin({blockObj.(fieldname).dir.name},'\n->\t'));
      end
   end
elseif (iscell(blockObj.ID.(fieldname).Folder) && ...
      ~iscell(blockObj.ID.(fieldname).File))
   blockObj.(fieldname).dir = [];
   for ii = 1:numel(blockObj.ID.(fieldname).Folder)
      blockObj.(fieldname).dir = [blockObj.(fieldname).dir; ...
         dir(fullfile(blockObj.DIR, ...
         [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder{ii}],...
         ['*' blockObj.ID.(fieldname).File '*.mat']))];
   end
   
   blockObj.(fieldname).ch = [];
   for ii = 1:numel(blockObj.(fieldname).dir)
      temp = strsplit(blockObj.(fieldname).dir(ii).name,blockObj.ID.Delimiter);
      ch_ind = find(ismember(temp,blockObj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         blockObj.(fieldname).ch = [blockObj.(fieldname).ch; nan];
         continue;
      end
      blockObj.(fieldname).ch = [blockObj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:blockObj.CH_FIELDWIDTH))];
   end
   if isempty(blockObj.(fieldname).dir)
      dname = fullfile(blockObj.DIR,...
         [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder{ii}]);
      if blockObj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               blockObj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               blockObj.Name,fieldname);
         end
      end
   else
      if blockObj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',blockObj.Name,fieldname,...
            strjoin({blockObj.(fieldname).dir.name},'\n->\t'));
      end
   end
elseif (iscell(blockObj.ID.(fieldname).File) && ...
      ~iscell(blockObj.ID.(fieldname).Folder))
   blockObj.(fieldname).dir = [];
   for ii = 1:numel(blockObj.ID.(fieldname).File)
      blockObj.(fieldname).dir = [blockObj.(fieldname).dir; ...
         dir(fullfile(blockObj.DIR, ...
         [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder],...
         ['*' blockObj.ID.(fieldname).File{ii} '*.mat']))];
   end
   
   blockObj.(fieldname).ch = [];
   for ii = 1:numel(blockObj.(fieldname).dir)
      temp = strsplit(blockObj.(fieldname).dir(ii).name,blockObj.ID.Delimiter);
      ch_ind = find(ismember(temp,blockObj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         blockObj.(fieldname).ch = [blockObj.(fieldname).ch; nan];
         continue;
      end
      blockObj.(fieldname).ch = [blockObj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:blockObj.CH_FIELDWIDTH))];
   end
   if isempty(blockObj.(fieldname).dir)
      dname = fullfile(blockObj.DIR,...
         [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder]);
      if blockObj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               blockObj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               blockObj.Name,fieldname);
         end
      end
   else
      if blockObj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',blockObj.Name,fieldname,...
            strjoin({blockObj.(fieldname).dir.name},'\n->\t'));
      end
   end
elseif (iscell(blockObj.ID.(fieldname).File) && ...
      iscell(blockObj.ID.(fieldname).Folder))
   blockObj.(fieldname).dir = [];
   for ii = 1:numel(blockObj.ID.(fieldname).File)
      for kk = 1:numel(blockObj.ID.(fieldname).Folder)
         blockObj.(fieldname).dir = [blockObj.(fieldname).dir; ...
            dir(fullfile(blockObj.DIR, ...
            [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder{kk}],...
            ['*' blockObj.ID.(fieldname).File{ii} '*.mat']))];
      end
   end
   
   blockObj.(fieldname).ch = [];
   for ii = 1:numel(blockObj.(fieldname).dir)
      temp = strsplit(blockObj.(fieldname).dir(ii).name,blockObj.ID.Delimiter);
      ch_ind = find(ismember(temp,blockObj.CH_ID),1,'last')+1;
      if isempty(ch_ind)
         blockObj.(fieldname).ch = [blockObj.(fieldname).ch; nan];
         continue;
      end
      blockObj.(fieldname).ch = [blockObj.(fieldname).ch; ...
         str2double(temp{ch_ind}(1:blockObj.CH_FIELDWIDTH))];
   end
   if isempty(blockObj.(fieldname).dir)
      dname = fullfile(blockObj.DIR,...
         [blockObj.Name blockObj.ID.Delimiter blockObj.ID.(fieldname).Folder{kk}]);
      if blockObj.VERBOSE
         if exist(dname,'dir')==0
            fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
               blockObj.Name,fieldname,dname);
         else
            fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
               blockObj.Name,fieldname);
         end
      end
   else
      if blockObj.VERBOSE
         fprintf(1,'\nFound %s -- %s:\n->\t%s\n',blockObj.Name,fieldname,...
            strjoin({blockObj.(fieldname).dir.name},'\n->\t'));
      end
   end
end
if isempty(blockObj.(fieldname).dir)
   blockObj.Status(fieldmatch) = false;
else
   blockObj.Status(fieldmatch) = true;
end
end