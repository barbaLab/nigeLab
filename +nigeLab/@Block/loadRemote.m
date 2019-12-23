function blockObj = loadRemote(targetBlockFile)
%LOADREMOTE  Static method to load Block on remote worker
%
%  targetFile = '//unc/target/name_Block.mat';
%  blockObj = nigeLab.Block.loadRemote(targetFile);
%
%  See Also:
%  NIGELAB.LIBS.DASHBOARD/QOPERATIONS

in = load(targetBlockFile,'blockObj');
if ~isfield(in,'blockObj')
   error(['nigeLab:' mfilename ':blockObjNotFound'],...
      'Coult not load variable ''blockObj'' from file (%s)\n',...
      targetBlockFile);
end
blockObj = in.blockObj;
end