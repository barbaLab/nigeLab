function obj = subsasgn(obj,S,data)
% SUBSASGN    Overloaded function for DiskData array assignment
%
%  obj = subsasgn(obj,S,data);
%
%  obj : nigeLab.libs.DiskData object to add data to using subscripted
%        assignment
%
%  S : struct returned from `substruct` that gives indexing
%  --> Array containing pairs of .type and .subs fields
%     --> .type : can be '()' or '.' or '{}' etc
%     --> .subs : the numeric or char subscript indexing values of DiskData
%
%  b : Data to assign to the DiskData obj.diskfile_ based on the
%        subscripted indices. 
%
%  This should effectively work as a `save` method for DiskData class

if strcmp(S(1).type,'.') % Check for '.'-indexed property assignment
   mc = ?nigeLab.libs.DiskData;
   diskProps = {mc.PropertyList.Name};
%    includedPropNames = setdiff(diskProps,...
%       {'type','value','tag','ts','snippet','data'});
   includedPropNames = setdiff(diskProps,{'snippet','data'});
   if any(strcmp(includedPropNames,S(1).subs))
      obj = builtin('subsasgn',obj,S,data(:));
      return;
   end
end

% Do validation that the DiskData object can be assigned to
if strcmp(obj.type_,'MatFile') && (length(obj)==0) %#ok<ISMT>
   nigeLab.libs.DiskData.throwImproperAssignmentError('empty');
   return;
elseif builtin('isempty',obj)
   nigeLab.libs.DiskData.throwImproperAssignmentError('empty');
   return;
elseif ~isvalid(obj)
   nigeLab.libs.DiskData.throwImproperAssignmentError('invalid');
   return;
end

% Check that obj.diskfile_ is writable
if ~obj.writable_
   nigeLab.libs.DiskData.throwImproperAssignmentError('standard');
else
   obj.unlockData(); % Make sure that it is writable otherwise
end

% Behavior depends on if it is 'Event' (matrix file) vs 'MatFile' or
% 'Hybrid' (vector files)
switch obj.type_
   case 'Event'
      subsasgn_MatrixData(obj,S,data);
   otherwise
      subsasgn_VectorData(obj,S,data);
end
end
