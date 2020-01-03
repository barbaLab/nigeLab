function TempDir = Tempdir()
%TEMPDIR  Just makes sure that `temp` exists so that files that go there
%           don't cause problems when it is a new repository.

TempDir = nigeLab.utils.getUNCPath(...
   fullfile(fileparts(fileparts(mfilename('fullpath'))),...
   'temp'));
if ~exist(TempDir,'dir')
   mkdir(TempDir); 
end
end