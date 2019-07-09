function varargout = blockGet(blockObj,prop)
%% BLOCKGET  Get a specific BLOCK property
%
%  out = BLOCKGET(blockObj,prop);
%
%  NOTE: Motivation is that this function may be useful later if adding
%        Listeners and Notifications to the class.
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     Previously constructed BLOCK object.
%
%    prop      :     String, or cell array of strings. Specifies the
%                    property to return. If that property does not exist or
%                    has not been set, returns NaN. If specified as a cell
%                    array, returns an output cell array of the same
%                    dimensions.
%
%                    If not specified, BLOCKGET returns all properties of
%                    BLOCK.
%
%  --------
%   OUTPUT
%  --------
%    out       :     Value held by property specified in prop. If prop
%                    argument is a cell array, then out is a cell array of
%                    the same dimensions.
%
% By: Max Murphy  v1.0  06/14/2018  Original version (R2017b)

P = properties(blockObj);

if nargin<2
    prop=P;
end
Prop = P(ismember(upper(P), upper( deblank( prop))) );
if ~isempty(Prop)
    for ii= 1:numel(Prop)
        varargout{ii} = blockObj.(Prop{ii});
    end
else
   warning('Property %s not found.',prop);
   varargout=cell;
end

end