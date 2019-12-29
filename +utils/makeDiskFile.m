function diskFile = makeDiskFile(diskPars)
%% MAKEDISKFILE   Short-hand function to create file on disk
%
%  diskFile = nigeLab.utils.MAKEDISKFILE(diskPars);
%
%  diskPars: Struct with following fields
%     --> 'name' (full filename of data file to be created or overwritten)
%     --> 'format' ('Hybrid', 'Matfile', 'Event', or 'Other')
%     --> 'class' (class of output 'data' variable)
%     --> 'size'  (size of the output 'data' variable)
%     --> 'access' ('r' for 'read only' or 'w' for 'write')
%
%  diskFile: Output, which is a nigeLab.libs.DiskData object that points to
%              where the data is on the disk.

%% CHECK INPUT
REQUIRED_FIELDS = {'name','format','class','size','access'};
if nargin < 1
   error('diskPars (struct) is a required input argument.');
end

if ~isstruct(diskPars)
   error('diskPars must be a struct');
end

iField = find(~ismember(REQUIRED_FIELDS,fieldnames(diskPars)));
if ~isempty(iField)
   for i = 1:numel(iField)
      nigeLab.utils.cprintf('Unterminated Strings',...
         'Missing field: %s\n',REQUIRED_FIELDS{iField(i)});
   end
   error('Missing fields of diskPars');
end

%%
% Check if file exists; if it does, remove it
if exist(diskPars.name,'file')
   delete(diskPars.name)
end
% Then create new pre-allocated diskFile
diskFile = nigeLab.libs.DiskData(...
   diskPars.format,...
   diskPars.name,...
   'class',diskPars.class,...
   'size',diskPars.size,...
   'access',diskPars.access);
end