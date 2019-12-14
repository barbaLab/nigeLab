function varargout = initFalseArray(varargin)
%% INITFALSEARRAY   [var1,var2,...] = utils.initFalseArray(dim1,dim2,...); 
%     Initialize logical false array.
%
%  For each requested output argument, request a logical false array of
%  dimensions dim1 x dim2 x ... x dim[nargin]

%%
if nargin > 0
   dims = cell2mat(varargin);
else
   dims = 1;
end

varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = false(dims);
end

end