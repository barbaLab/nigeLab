function out = tankGet(tankObj,prop)
%% TANKGET  Get a specific TANK property
%
%  out = TANKGET(tankObj,prop);
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
%                    property to return. If that property does not exist or
%                    has not been set, returns NaN. If specified as a cell
%                    array, returns an output cell array of the same
%                    dimensions.
%
%                    If not specified, TANKGET returns all properties of
%                    TANK.
%
%  --------
%   OUTPUT
%  --------
%    out       :     Value held by property specified in prop. If prop
%                    argument is a cell array, then out is a cell array of
%                    the same dimensions.
%
% By: Max Murphy  v1.0  06/14/2018  Original version (R2017b)

%% PARSE INPUT

out = tankObj.(prop);

end