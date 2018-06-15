function blockList = list(tankObj)
%% LIST  List BLOCK objects in parent TANK
%
%  blockList = LIST(tankObj);
%
%  --------
%   INPUTS
%  --------
%   tankObj    :     TANK Class object.
%
%  --------
%   OUTPUT
%  --------
%  blockList   :     List of BLOCK Class objects in this tank.
%                    Returns an empty array if no BLOCKS are in TANK.
%
% By: Max Murphy  v1.0  06/14/2018  Original version (R2017b)

%%
if isempty(tankObj.Block)
   blockList = [];   
else
   blockList = cell(size(tankObj.Block));
   
   fprintf(1,'Blocks in %s:\n',tankObj.Name);
   fprintf(1,'---------------------------------\n\n');
   for ii = 1:numel(tankObj.Block)
      fprintf(1,'->\t%s\n',tankObj.Block(ii).Name);
      blockList{ii} = tankObj.Block(ii).Name;
   end
   
end


end