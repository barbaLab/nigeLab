function varargout = initZerosArray(varargin)
%% INITZEROSARRAY   [var1,var2,...] = utils.initZerosArray(dim1,dim2,...);
%
%  [var1,...,varK] = utils.initZerosArray(dim1,...,dimN);
%  [var1,...,varK] = utils.initZerosArray(typename,dim1,...,dimN);
%     --> e.g. [var1,var2] = utils.initZerosArray('uint8',5,10,3);
%
%  For each requested output argument, request an array of zeros of
%  dimensions dim1 x dim2 x ... x dim[nargin]

%%
if ischar(varargin{1})
   typename = varargin{1};
   varargin(1) = [];
else
   typename = 'double'; % Default is 'double'
end

%%
if numel(varargin) > 0
   dims = cell2mat(varargin);
else
   dims = 1;
end

varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = zeros(dims,typename);
end


end