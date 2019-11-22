function varargout = initTrueArray(varargin)
%% INITTRUEARRAY  [var1,var2,...] = utils.initTrueArray(dim1,dim2,...); 
%     Initialize logical true array.
%
%  For each requested output argument, request a logical true array of
%  dimensions dim1 x dim2 x ... x dim[nargin]

%%
if nargin > 0
   dims = cell2mat(varargin);
else
   dims = 1;
end
varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = true(dims);
end

end