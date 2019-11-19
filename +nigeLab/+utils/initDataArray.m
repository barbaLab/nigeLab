function varargout = initDataArray(x,varargin)
%% INITDATAARRAY   [var1,var2,...] = utils.initDataArray(dim1,dim2,...);
%
%  [var1,...,varK] = utils.initDataArray(x);
%     --> e.g. [var1,var2] = utils.initDataArray(1:10); % Both are 1:10
%  [var1,...,varK] = utils.initDataArray(x,dim1,...,dimN);
%     --> e.g. [var1,var2] = utils.initDataArray(1:10,2,3); 
%        --> var1 and var2 would both be repmat(1:10,2,3)
%
%  For each requested output argument, request a copy of the data array x,
%  and potentially replicate it along dimensions as:
%     --> repmat(x,[dim1,dim2,...,dimN]);

%%
if numel(varargin) > 0
   dims = cell2mat(varargin);
else
   dims = 1;
end

%%
varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = repmat(x,dims);
end

end