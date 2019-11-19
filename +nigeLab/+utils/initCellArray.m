function varargout = initCellArray(varargin)
%% INITCELLARRAY    [var1,var2,...] = utils.initCellArray(dim1,dim2,...);
%
%  For each requested output argument, request an empty cell array of
%  dimensions dim1 x dim2 x ... x dim[nargin]

%%
if nargin > 0
   dims = cell2mat(varargin);
else
   dims = 1;
end
varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = cell(dims);
end


end