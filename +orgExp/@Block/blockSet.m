function flag = blockSet(blockObj,prop,value)
%% BLOCKSET  Set a specific BLOCK property
%
%  flag = BLOCKSET(tankObj,prop);
%
%  NOTE: Motivation is that this function may be useful later if adding
%        Listeners and Notifications to the class.
%
%  --------
%   INPUTS
%  --------
%   blockObj   :     Previously constructed BLOCK object.
%
%    prop      :     String, or cell array of strings. Specifies the
%                    property to set. If that property does not exist or
%                    cannot be set, returns false. If specified as a cell
%                    array, returns an output array of the same
%                    dimensions.
%
%   value      :     New value for property specified by prop. If prop is
%                    specified as a cell array, then value must be
%                    specified as a cell array of the same dimensions.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Boolean true, if the property is successfully set. If
%                    the property does not exist or cannot be set, flag is
%                    false. If inputs are cell arrays, then flag is
%                    returned as a boolean array of the same dimensions.
%
% By: Max Murphy  v1.0  06/14/2018  Original version (R2017b)

%% PARSE INPUT
if iscell(prop) % If cell, use recursion
   
   if any(size(prop) - size(value)) % Must be same dimensions
      error('Size mismatch: prop ([%d %d]) and value ([%d %d]).', ...
         size(prop,1),size(prop,2),size(value,1),size(value,2));
   end
      
   flag = false(size(prop));
   for ii = 1:numel(prop)
      flag(ii) = blockSet(blockObj,prop{ii},value{ii});
   end
   return;
end

%% CHECK PROPERTY AND IF IT EXISTS, ASSIGN AND RETURN CORRESPONDING BOOLEAN
 P = properties(blockObj);
 p = P(ismember(upper(P), upper( deblank( prop))) );
if isempty(p)
   flag = false;
else
   blockObj.(prop) = value;
   flag = true;
end

end