function blockObj = loadRemote(targetBlockFile)
%LOADREMOTE  Static method to load Block on remote worker
%
%  targetFile = '//unc/target/name_Block.mat';
%  blockObj = nigeLab.Block.loadRemote(targetFile);
%
%  See Also:
%  NIGELAB.LIBS.DASHBOARD/QOPERATIONS

%% Check that target file exists and load it if it does.
if exist(targetBlockFile,'file')==0
   error(['nigeLab:' mfilename ':FileNotFound'],...
      'Coult not find file (%s) from worker (at %s)\n',...
      targetBlockFile,pwd);
end
in = load(targetBlockFile,'blockObj');

%% Check that object exists in the file.
if ~isfield(in,'blockObj')
   error(['nigeLab:' mfilename ':ObjectNotFound'],...
      'Coult not load variable ''blockObj'' from file (%s)\n',...
      targetBlockFile);
end
blockObj = in.blockObj;

%% Check that object can be correctly loaded as a nigeLab.Block object.
if ~isa(blockObj,'nigeLab.Block')
   error(['nigeLab:' mfilename ':NigeLabNotFound'],...
      'Could not properly load nigeLab.Block class object from %s\n',...
      pwd);
end
end