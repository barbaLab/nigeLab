function parsavedata(fname,varargin) 
%% PARSAVEDATA  Parses variables to be saved
%
%   parsavedata(fname,'VARNAME1',var1,'VARNAME2',var2,...)
%
%   --------
%    INPUTS
%   --------
%     fname     :       Full file name (with directory) of where to save
%                       the .mat file.
%
%   varargin    :       'VARNAME',var input argument pairs.
%
%       -> ex \\ parsavedata('C:\test.mat','data',data,'fs',fs);
%
% Updated by: Max Murphy    v2.0    08/04/2017 - Made it more flexible so
%                                                it can take whatever
%                                                variables.

%% PARSE VARARGIN
vars = struct;
for ii = 1:2:length(varargin)
    vars.(varargin{ii}) = varargin{ii+1};
end

%% SAVE DATA
save(fname,'-STRUCT','vars','-v7.3');
    
end