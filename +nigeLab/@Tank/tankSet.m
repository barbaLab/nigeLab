function flag = tankSet(tankObj,prop,value)
%% TANKSET  Get a specific TANK property
%
%  flag = TANKSET(tankObj,prop);
%
%  NOTE: Motivation is that this function may be useful later if adding
%        Listeners and Notifications to the class.
%
%  --------
%   INPUTS
%  --------
%   tankObj    :     Previously constructed TANK object.
%
%    prop      :     String, or cell array of strings. Specifies the
%                    property to set. If that property does not exist or
%                    has not been set, returns false. If specified as a cell
%                    array, returns an output cell array of the same
%                    dimensions.
%
%                    If not specified, TANKGET returns all properties of
%                    TANK.
%
%   value      :     New value for property specified by prop.
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
      flag(ii) = tankSet(tankObj,prop{ii},value{ii});
   end
   return;
end

%% CHECK PROPERTY AND IF IT EXISTS, ASSIGN AND RETURN CORRESPONDING BOOLEAN
p = findprop(tankObj,prop);
if isempty(p)
   flag = false;
else
   tankObj.(prop) = value;
   flag = true;
end

end