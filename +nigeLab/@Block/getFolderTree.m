function paths = getFolderTree(blockObj,paths)
%% GETFOLDERTREE  Returns paths struct that parses folder names
%
%  paths = GETFOLDERTREE(blockObj);
%  paths = GETFOLDERTREE(blockObj,paths);
%  paths = GETFOLDERTREE(blockObj,paths,useRemote);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object
%
%    paths        :     (optional) struct similar to output from this
%                          function. This should be passed if paths has
%                          already been extracted, to preserve paths that
%                          are not extrapolated directly from
%                          GETFOLDERTREE.
%
%   useRemote     :     (optional) flag to use remote universal naming
%                          convention (UNC) folder at the beginning of
%                          SaveLoc. This is needed if the UseRemote flag is
%                          set to true in nigeLab.defaults.Queue, so that
%                          the remote workers can see the file paths. Files
%                          MUST be put in a location where the UNC allows
%                          both the local machine and the remote workers to
%                          see them. 
%
%                          Later versions will change the way jobs are
%                          handled so that there is an option to attach
%                          files and send them to remote workers, without
%                          needing to worry about the remote workers
%                          directly being able to access the files in their
%                          native location.
%
% By: Federico Barban, Max Murphy, Stefano Buccelli  v0 (2019)

%%
if nargin < 2
   paths = struct(); 
end

blockObj.updateParams('Block');
F = fieldnames(blockObj.PathExpr);
del = blockObj.Delimiter;

for iF = 1:numel(F) % For each field, update field type
   p = blockObj.PathExpr.(F{iF});
   
   if contains(p.Folder,'%s') % Parse for spikes stuff
      p.Folder = sprintf(strrep(p.Folder,'\','/'),...
         blockObj.Pars.SD.ID.(F{iF}));
   end
   
   % Set folder name for this particular Field
   paths.(F{iF}).dir = nigeLab.utils.getUNCPath(paths.SaveLoc.dir,...
      [p.Folder]);
   
   % Parse for both old and new versions of file naming convention
   paths.(F{iF}).file = nigeLab.utils.getUNCPath(...
      paths.(F{iF}).dir,[p.File]);
   paths.(F{iF}).f_expr = p.File;
   paths.(F{iF}).old = getOldFiles(p,paths.(F{iF}),'dir');
   paths.(F{iF}).info = nigeLab.utils.getUNCPath(...
      paths.(F{iF}).dir,[p.Info]);
   
end
end

  function old = getOldFiles(p,fieldPath,type)
      %% GETOLDFILES  Get struct with file info for possible old files
      old = struct;
      for iO = 1:numel(p.OldFile)
         f = strsplit(p.OldFile{iO},'.');
         f = deblank(strrep(f{1},'*',''));
         if isempty(f)
            continue;
         end
         O = dir(fullfile(fieldPath.(type),p.OldFile{iO}));
         if isempty(O)
            old.(f) = O;
         else
            if O(1).isdir
               old.(f) = dir(fullfile(O(1).folder,O(1).name,...
                  p.OldFile{iO}));
            else
               old.(f) = O;
            end
         end
      end
   end
