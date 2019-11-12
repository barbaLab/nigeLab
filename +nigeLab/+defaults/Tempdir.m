function TempDir = Tempdir()
TempDir = nigeLab.utils.getUNCPath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'temp'));
if ~exist(TempDir,'dir')
   mkdir(TempDir); 
end
end