function TempDir = Tempdir()
TempDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'temp');
if ~exist(TempDir,'dir')
   mkdir(Tempdir); 
end
end