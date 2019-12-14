function varargout = initNaNArray(varargin)
%% INITNANARRAY    [var1,var2,...] = utils.initNaNArray(dim1,dim2,...);
%
%  For each requested output argument, request a NaN array of
%  dimensions dim1 x dim2 x ... x dim[nargin]

%%
dims = cell2mat(varargin);
varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = nan(dims);
end


end